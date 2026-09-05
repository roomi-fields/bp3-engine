#!/usr/bin/env bash
# PREUVE DE MORSURE du garde de production.
#
# ⛔ Ce garde-ci est le seul dont la morsure ne peut PAS se prouver par un code de sortie : le
# moteur rend 0 quand il ne produit rien. Chaque volet vérifie donc que le garde REFUSE là où le
# binaire, lui, aurait rendu 0 sans un octet.
#
#   A  les chaînes de console retirées      — la moitié « répertoire courant »
#   B  les ressources Csound déplacées      — la moitié « ../ gravé en dur », que A ne touche pas
#   C  un auxiliaire du corpus retiré       — zéro production tentée, le garde refuse le vide
#   D  ⛔ TÉMOIN NON NUL — tout remis, le garde doit VERDIR
set -u
cd "$(dirname "$0")/.." || exit 2
G=scripts/gate-production.py
CS=capture-run/console_strings.json
RES=csound_resources
GRAM=test-data/-gr.tryKeyMap
rc=0

if ! python3 "$G" >/dev/null 2>&1; then
  echo "PRÉALABLE ROUGE : la porte ne produit pas avant toute injection."
  python3 "$G"
  exit 1
fi

essai() { # essai <étiquette> [motif attendu dans la sortie]
  local sortie; sortie=$(python3 "$G" 2>&1)
  if [ $? -eq 0 ]; then
    echo "  $1 : LE GARDE N'A PAS MORDU"; rc=1
  elif [ -n "${2:-}" ] && ! printf '%s' "$sortie" | grep -q "$2"; then
    echo "  $1 : mord, mais SANS NOMMER « $2 » — sa cause n'est pas la bonne"; rc=1
  else
    echo "  $1 : mord"
  fi
}

mv "$CS" "$CS.retire"
essai "A chaînes de console retirées" "0 OCTET PRODUIT"
mv "$CS.retire" "$CS"

mv "$RES" "$RES.deplace"
essai "B ressources Csound déplacées" "0 OCTET PRODUIT"
mv "$RES.deplace" "$RES"

mv "$GRAM" "$GRAM.retire"
essai "C auxiliaire du corpus retiré" "introuvable"
mv "$GRAM.retire" "$GRAM"

echo "D ⛔ TÉMOIN NON NUL — tout remis en place"
if python3 "$G" >/dev/null 2>&1; then
  echo "  verdit ✔ — les trois refus venaient bien des injections"
else
  echo "  ÉCHEC : reste rouge après restauration — les volets A à C ne prouvaient rien"
  python3 "$G"
  rc=2
fi
exit $rc
