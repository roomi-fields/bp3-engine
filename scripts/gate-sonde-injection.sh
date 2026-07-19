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
nettoie() { cp "$SAUVE" "$BIN"; chmod +x "$BIN"; rm -f "$SAUVE"; }
trap nettoie EXIT

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

echo "4. la baseline publiée doit être INTACTE"
if python3 scripts/gate-baseline.py >/dev/null 2>&1; then echo "   intacte ✔"
else echo "   ÉCHEC : la baseline a été touchée malgré l'abandon"; echec=1; fi

nettoie
echo "─────────────────────────────────────────────"
[ $echec -eq 0 ] && echo "MORSURE PROUVÉE : chaîne muette détectée en quelques secondes, rien mesuré, rien publié." \
                || echo "MORSURE NON PROUVÉE."
exit $echec
