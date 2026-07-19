#!/usr/bin/env bash
# PREUVE DE MORSURE de la sonde d'entrée de la capture, par injection.
# On rejoue le défaut du 2026-07-19 : le sérialiseur ne reçoit plus le nom de fichier,
# donc il n'émet rien. La capture doit ABANDONNER en quelques secondes, sans rien mesurer
# ni rien publier — au lieu de tourner trente minutes pour rendre du vide.
set -u
cd "$(dirname "$0")/.."
echec=0
BIN="bp3"; SAUVE=$(mktemp)
cp "$BIN" "$SAUVE"
nettoie() { [ -f "$SAUVE" ] && { cp "$SAUVE" "$BIN"; chmod +x "$BIN"; rm -f "$SAUVE"; }; }
trap nettoie EXIT

EMPREINTE_JSON=$(sha256sum baseline-native/baseline.json)
NB_CAPTURES=$(ls baseline-native/captures | wc -l)

echo "1. état de départ — la sonde doit PASSER (le moteur émet)"
sortie=$(timeout 300 python3 baseline-native/capture.py vina 2>&1)
if printf '%s' "$sortie" | grep -q "jetons="; then echo "   la chaîne émet ✔"
else echo "   ÉCHEC : le moteur n'émet déjà rien, la preuve serait sans valeur"; exit 1; fi

echo "2. injection — on remplace le binaire par un leurre qui n'émet aucun jeton"
cat > "$BIN" <<'SH'
#!/usr/bin/env bash
# leurre : accepte tout, sort proprement, n'écrit aucun fichier de jetons
for a in "$@"; do case "$a" in --short-version) echo "3.4.7"; exit 0;; esac; done
echo "Errors: 0"
exit 0
SH
chmod +x "$BIN"

echo "3. la capture doit ABANDONNER, vite, sans rien publier"
avant=$(date +%s)
sortie=$(timeout 300 python3 baseline-native/capture.py 2>&1); code=$?
duree=$(( $(date +%s) - avant ))
if [ $code -ne 4 ]; then
  echo "   ÉCHEC : code $code au lieu de 4 — la sonde n'a pas arrêté la capture"; echec=1
elif ! printf '%s' "$sortie" | grep -q "CAPTURE ABANDONNEE"; then
  echo "   ÉCHEC : arrêt sans message explicite"; echec=1
else
  echo "   abandon en ${duree} s, code 4, message explicite ✔"
fi

# On vérifie que L'INJECTION n'a rien touché — par empreinte avant/après, PAS en lançant
# le garde d'intégrité : celui-ci est légitimement rouge quand une baseline vient d'être
# capturée et que ses en-têtes ne sont pas encore posés. Le garde répondrait à une autre
# question que celle qu'on pose ici, et sa réponse passerait pour un échec de l'injection.
echo "4. l'abandon ne doit avoir touché NI baseline.json NI les captures publiées"
if [ "$(sha256sum baseline-native/baseline.json)" = "$EMPREINTE_JSON" ] \
   && [ "$(ls baseline-native/captures | wc -l)" = "$NB_CAPTURES" ]; then
  echo "   rien touché ✔"
else
  echo "   ÉCHEC : l'abandon a modifié la baseline ou ses captures"; echec=1
fi

nettoie
echo "─────────────────────────────────────────────"
[ $echec -eq 0 ] && echo "MORSURE PROUVÉE : chaîne muette détectée en quelques secondes, rien mesuré, rien publié." \
                || echo "MORSURE NON PROUVÉE."
exit $echec
