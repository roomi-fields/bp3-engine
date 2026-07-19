#!/usr/bin/env bash
# PREUVE DE MORSURE du garde d'ancrages locaux, par injection.
# On rejoue LE défaut réel du 2026-07-19 : reprendre PlayThings.c tel quel depuis l'amont,
# ce qui efface l'appel au sérialiseur. Le garde doit le voir AVANT la reconstruction.
set -u
cd "$(dirname "$0")/.."
CIBLE="source/BP3/PlayThings.c"
echec=0
DATE=$(stat -c %y "$CIBLE")
nettoie() { git checkout -- "$CIBLE" 2>/dev/null || true; touch -d "$DATE" "$CIBLE" 2>/dev/null || true; }
trap nettoie EXIT

echo "1. état de départ — le garde doit être VERT"
python3 scripts/gate-ancrages.py >/dev/null 2>&1 && echo "   vert ✔" \
  || { echo "   ÉCHEC : déjà rouge, la preuve serait sans valeur"; exit 1; }

echo "2. injection — on reprend PlayThings.c TEL QUEL depuis l'amont (le défaut réel)"
git show upstream/graphics-for-BP3:source/BP3/PlayThings.c > "$CIBLE" 2>/dev/null \
  || { echo "   (amont indisponible, on simule en retirant l'appel)"; \
       grep -v "EmitTimedTokensItem\|TokensOutFile" "$CIBLE" > "$CIBLE.tmp" && mv "$CIBLE.tmp" "$CIBLE"; }

sortie=$(python3 scripts/gate-ancrages.py 2>&1); code=$?
if [ $code -eq 0 ]; then
  echo "   ÉCHEC : le garde reste vert alors que l'appel a disparu — figurant"; echec=1
elif ! printf '%s' "$sortie" | grep -q "EmitTimedTokensItem"; then
  echo "   ÉCHEC : rouge mais sans nommer le marqueur perdu"; echec=1
elif ! printf '%s' "$sortie" | grep -q "PlayThings.c"; then
  echo "   ÉCHEC : rouge mais sans nommer le fichier"; echec=1
else
  echo "   rouge, et il nomme le fichier ET le marqueur perdu ✔"
fi

echo "3. restauration — le garde doit redevenir VERT"
nettoie
python3 scripts/gate-ancrages.py >/dev/null 2>&1 && echo "   vert ✔" \
  || { echo "   ÉCHEC : reste rouge après restauration"; echec=1; }

echo "─────────────────────────────────────────────"
[ $echec -eq 0 ] && echo "MORSURE PROUVÉE : le garde détecte la perte d'un ajout local par synchro amont." \
                || echo "MORSURE NON PROUVÉE."
exit $echec
