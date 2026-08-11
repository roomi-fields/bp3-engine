#!/usr/bin/env bash
# Preuve de morsure du garde de gel.
#
# Un garde qu on n a jamais vu echouer n est pas un garde : c est une intention. On lui
# presente trois violations reelles, chacune restauree juste apres, et on exige qu il
# rougisse sur les trois.
#
#   A  un champ modifie dans baseline.json  — la retouche discrete
#   B  une capture modifiee                 — le contenu qui derive
#   C  une capture retiree                  — ce qu une empreinte par fichier raterait
set -u
cd "$(dirname "$0")/.." || exit 2
G=scripts/gel-baseline.py
BJ=baseline-native/baseline.json
UNE=$(ls baseline-native/captures | head -1)
CAP="baseline-native/captures/$UNE"
rc=0

if ! python3 "$G" >/dev/null 2>&1; then
  echo "PREALABLE ROUGE : le gel est deja rompu avant toute injection."
  python3 "$G"
  exit 1
fi

essai() {  # $1 = etiquette
  if python3 "$G" >/dev/null 2>&1; then
    echo "  $1 : LE GARDE N A PAS MORDU"
    rc=1
  else
    echo "  $1 : mord"
  fi
}

cp "$BJ" /tmp/gel-bj.$$ && cp "$CAP" /tmp/gel-cap.$$

python3 - "$BJ" <<'EOF'
import json, sys
p = sys.argv[1]
d = json.load(open(p, encoding="utf-8"))
d["grammaires"][0]["mots_texte"] = (d["grammaires"][0].get("mots_texte") or 0) + 1
json.dump(d, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
EOF
essai "A champ modifie dans baseline.json"
cp /tmp/gel-bj.$$ "$BJ"

printf 'derive\n' >> "$CAP"
essai "B capture modifiee ($UNE)"
cp /tmp/gel-cap.$$ "$CAP"

rm -f "$CAP"
essai "C capture retiree ($UNE)"
cp /tmp/gel-cap.$$ "$CAP"

rm -f /tmp/gel-bj.$$ /tmp/gel-cap.$$

if ! python3 "$G" >/dev/null 2>&1; then
  echo "RESTAURATION INCOMPLETE : le gel reste rompu apres les injections."
  python3 "$G"
  exit 2
fi
[ $rc -eq 0 ] && echo "les trois injections mordent, l etat est restaure."
exit $rc
