#!/usr/bin/env bash
# PREUVE DE MORSURE du garde anti-rétrocompatibilité, par injection.
# Un garde qu'on n'a jamais vu échouer est une hypothèse, pas une protection.
# On injecte les DEUX fautes qu'il doit attraper, séparément.
set -u
cd "$(dirname "$0")/.."
LEG="csrc/wasm/bp3_leurre_legacy.c"
CANON="csrc/bp3/Misc.c"
echec=0
nettoie() { rm -f "$LEG"; git checkout -- "$CANON" 2>/dev/null || true; }
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

echo "3. injection B — les deux arbres de sources du moteur divergent"
printf '\n/* divergence injectee */\n' >> "$CANON"
sortie=$(python3 scripts/gate-legacy.py 2>&1); code=$?
if [ $code -eq 0 ]; then
  echo "   ÉCHEC : le garde ne voit pas la divergence des deux arbres"; echec=1
elif ! printf '%s' "$sortie" | grep -q "Misc.c"; then
  echo "   ÉCHEC : rouge mais sans nommer le fichier divergent"; echec=1
else
  echo "   rouge, et il nomme le fichier ✔"
fi
git checkout -- "$CANON"

echo "4. retrait des deux leurres — le garde doit redevenir VERT"
vert && echo "   vert ✔" || { echo "   ÉCHEC : reste rouge après retrait"; echec=1; }

echo "─────────────────────────────────────────────"
[ $echec -eq 0 ] && echo "MORSURE PROUVÉE sur les DEUX volets : appelant vivant, et divergence des arbres." \
                || echo "MORSURE NON PROUVÉE — le garde ne protège pas ce qu'il annonce."
exit $echec
