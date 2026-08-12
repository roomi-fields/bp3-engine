#!/usr/bin/env bash
# Preuve de morsure du garde d'autonomie.
#
# On reintroduit la dependance exacte qui a cassé six grammaires le 2026-08-12 : une
# lecture du registre de BPscript depuis capture.py. Le garde doit rougir, et l'etat
# doit etre restaure ensuite.
set -u
cd "$(dirname "$0")/.." || exit 2
G=scripts/gate-autonomie.py
CIBLE=baseline-native/capture.py
rc=0

if ! python3 "$G" >/dev/null 2>&1; then
  echo "PREALABLE ROUGE : une dependance hors depot existe deja."
  python3 "$G"
  exit 1
fi

cp "$CIBLE" /tmp/autonomie.$$
printf '\nGRJ = "/home/romi/dev/bp/BPscript/test/grammars/grammars.json"\n' >> "$CIBLE"
if python3 "$G" >/dev/null 2>&1; then
  echo "  A dependance au registre voisin : LE GARDE N A PAS MORDU"
  rc=1
else
  echo "  A dependance au registre voisin : mord"
fi
cp /tmp/autonomie.$$ "$CIBLE"

# Un commentaire n'est pas une dependance : le garde ne doit pas mordre dessus, sinon
# il devient impossible d'EXPLIQUER la panne dans le fichier qui l'a subie.
printf '\n# ancien: GRJ = "/home/romi/dev/bp/BPscript/test/grammars/grammars.json"\n' >> "$CIBLE"
if python3 "$G" >/dev/null 2>&1; then
  echo "  B mention en commentaire : ignoree, comme il faut"
else
  echo "  B mention en commentaire : LE GARDE MORD A TORT"
  rc=1
fi
cp /tmp/autonomie.$$ "$CIBLE"
rm -f /tmp/autonomie.$$

if ! python3 "$G" >/dev/null 2>&1; then
  echo "RESTAURATION INCOMPLETE."
  exit 2
fi
[ $rc -eq 0 ] && echo "le garde mord sur la dependance et ignore le commentaire."
exit $rc
