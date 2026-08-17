#!/usr/bin/env bash
# PREUVE DE MORSURE du garde anti-rétrocompatibilité, par injection.
# Un garde qu'on n'a jamais vu échouer est une hypothèse, pas une protection.
# On injecte les DEUX fautes qu'il doit attraper, séparément.
set -u
cd "$(dirname "$0")/.."
LEG="scripts/bp3_leurre_legacy.c"
SRC="source/BP3/Misc.c"
echec=0
# On memorise la date de la source AVANT de la toucher, et on la restaure apres : le
# controle de fraicheur des artefacts (volet 2 du garde) verrait sinon une source plus
# recente que le binaire, et resterait rouge apres la preuve.
# Une preuve d injection ne doit rien laisser derriere elle, pas meme une date.
DATE_SRC=$(stat -c %y "$SRC")
nettoie() {
  rm -f "$LEG"
  touch -d "$DATE_SRC" "$SRC" 2>/dev/null || true
}
trap nettoie EXIT

vert() { python3 scripts/gate-legacy.py >/dev/null 2>&1; }

echo "1. état de départ — le garde doit être VERT"
vert && echo "   vert ✔" || { echo "   ÉCHEC : déjà rouge, la preuve serait sans valeur"; exit 1; }

echo "2. injection A — un symbole marqué au retrait, AVEC un appelant vivant"
cat > "$LEG" <<'C'
/* deprecated: voué au retrait, gardé le temps de migrer */
int bp3_vieille_voie(int x) { return x; }
int bp3_nouvelle_voie(int x) { return bp3_vieille_voie(x); }  /* appelant vivant */
C
sortie=$(python3 scripts/gate-legacy.py 2>&1); code=$?
if [ $code -eq 0 ]; then
  echo "   ÉCHEC : le garde reste vert malgré un appelant vivant — figurant"; echec=1
elif ! printf '%s' "$sortie" | grep -q "bp3_vieille_voie"; then
  echo "   ÉCHEC : rouge mais sans nommer le symbole fautif"; echec=1
else
  echo "   rouge, et il nomme le symbole ✔"
fi
rm -f "$LEG"

echo "3. injection B — une source du moteur devient plus récente que le binaire"
touch "$SRC"
sortie=$(python3 scripts/gate-legacy.py 2>&1); code=$?
if [ $code -eq 0 ]; then
  echo "   ÉCHEC : le garde ne voit pas que l'oracle est périmé"; echec=1
elif ! printf '%s' "$sortie" | grep -q "bp3"; then
  echo "   ÉCHEC : rouge mais sans nommer l'artefact périmé"; echec=1
else
  echo "   rouge, et il nomme l'artefact ✔"
fi
touch -d "$DATE_SRC" "$SRC"

echo "4. retrait des deux leurres — le garde doit redevenir VERT"
vert && echo "   vert ✔" || { echo "   ÉCHEC : reste rouge après retrait"; echec=1; }

echo "─────────────────────────────────────────────"
[ $echec -eq 0 ] && echo "MORSURE PROUVÉE sur les DEUX volets : appelant vivant, et oracle périmé." \
                || echo "MORSURE NON PROUVÉE — le garde ne protège pas ce qu'il annonce."
exit $echec
