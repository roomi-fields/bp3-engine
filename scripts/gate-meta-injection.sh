#!/usr/bin/env bash
# PREUVE DE MORSURE du méta-garde anti-bypass, par injection.
#
# Un garde qu'on n'a jamais vu échouer sur un cas connu n'est pas une protection,
# c'est une hypothèse. bpscript a découvert que son méta-garde était vide par
# construction — il n'a été démasqué qu'en lui injectant un faux fichier.
#
# Ce script dépose un test bidon HORS du portillon, vérifie que le garde devient
# ROUGE et NOMME le fichier, puis le retire et vérifie le retour au VERT.
# Il dépose volontairement le leurre dans un dossier INATTENDU (pas scripts/),
# parce que c'est précisément le cas qu'un garde naïf laisse passer.
set -u
cd "$(dirname "$0")/.."
LEURRE="docs/test-leurre-anti-bypass.js"
echec=0

nettoie() { rm -f "$LEURRE"; rmdir docs 2>/dev/null || true; }
trap nettoie EXIT

echo "1. état de départ — le garde doit être VERT"
if python3 scripts/gate-meta.py >/dev/null 2>&1; then
  echo "   vert ✔"
else
  echo "   ÉCHEC : le garde est déjà rouge avant l'injection, la preuve est sans valeur"; exit 1
fi

echo "2. injection d'un test bidon hors du portillon : $LEURRE"
mkdir -p docs && printf '// leurre de test du meta-garde\nprocess.exit(0);\n' > "$LEURRE"

echo "3. le garde doit devenir ROUGE et NOMMER le fichier"
sortie=$(python3 scripts/gate-meta.py 2>&1); code=$?
if [ $code -eq 0 ]; then
  echo "   ÉCHEC : le garde reste vert malgré l'orphelin — c'est un figurant"; echec=1
elif ! printf '%s' "$sortie" | grep -q "test-leurre-anti-bypass"; then
  echo "   ÉCHEC : le garde est rouge mais ne nomme pas le fichier fautif"; echec=1
else
  echo "   rouge, et il nomme le fichier ✔"
fi

echo "4. retrait du leurre — le garde doit redevenir VERT"
nettoie
if python3 scripts/gate-meta.py >/dev/null 2>&1; then
  echo "   vert ✔"
else
  echo "   ÉCHEC : le garde reste rouge après retrait"; echec=1
fi

echo "─────────────────────────────────────────────"
[ $echec -eq 0 ] && echo "MORSURE PROUVÉE : le méta-garde détecte un test déposé hors du portillon." \
                || echo "MORSURE NON PROUVÉE — le méta-garde ne protège rien."
exit $echec
