#!/usr/bin/env bash
# PREUVE DE MORSURE du garde des empreintes annoncées.
#
# ⛔ Un garde qu'on n'a pas vu mordre par injection est une hypothèse. On lui présente quatre
# déclarations fausses, chacune restaurée juste après, et on exige qu'il rougisse sur les quatre.
#
#   A  une empreinte faussée D'UN SEUL CARACTÈRE dans GEL.json — la dérive minimale
#   B  une empreinte faussée d'un caractère dans le tableau d'ORACLE-BINAIRE.md
#   C  un chemin annoncé qui n'existe pas — la description qui pointe vers rien
#   D  le tableau renommé : ZÉRO couple confronté, et un vert sur zéro ne prouve rien
set -u
cd "$(dirname "$0")/.." || exit 2
G=scripts/gate-empreinte-oracle.py
GEL=baseline-native/GEL.json
DOC=ORACLE-BINAIRE.md
rc=0

if ! python3 "$G" >/dev/null 2>&1; then
  echo "PRÉALABLE ROUGE : une empreinte annoncée est déjà fausse avant toute injection."
  python3 "$G"
  exit 1
fi

essai() { # essai <étiquette>
  if python3 "$G" >/dev/null 2>&1; then
    echo "  $1 : LE GARDE N'A PAS MORDU"; rc=1
  else
    echo "  $1 : mord"
  fi
}

cp "$GEL" "/tmp/emp-gel.$$" && cp "$DOC" "/tmp/emp-doc.$$"

# A — un caractère de l'empreinte, et rien d'autre.
python3 - "$GEL" <<'EOF'
import json, sys
p = sys.argv[1]
d = json.load(open(p, encoding="utf-8"))
m = d["binaire"]["md5"]
d["binaire"]["md5"] = ("b" if m[0] == "a" else "a") + m[1:]
json.dump(d, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
EOF
essai "A un caractère faussé dans GEL.json"
cp "/tmp/emp-gel.$$" "$GEL"

# B — le même geste dans le tableau du document.
python3 - "$DOC" <<'EOF'
import re, sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
m = re.search(r"\| ([0-9a-f]{32}) \|", t)
a = m.group(1)
t = t.replace(a, ("b" if a[0] == "a" else "a") + a[1:], 1)
open(p, "w", encoding="utf-8").write(t)
EOF
essai "B un caractère faussé dans le tableau d'ORACLE-BINAIRE.md"
cp "/tmp/emp-doc.$$" "$DOC"

# C — le chemin annoncé ne désigne plus rien.
python3 - "$DOC" <<'EOF'
import sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
t = t.replace("`builds/v3.5.1-iso.2`", "`builds/campagne-qui-n-existe-pas`", 1)
open(p, "w", encoding="utf-8").write(t)
EOF
essai "C un chemin annoncé absent du disque"
cp "/tmp/emp-doc.$$" "$DOC"

# D — ⛔ LE VOLET QUI COMPTE LE PLUS : le motif cesse d'apparier, zéro couple, et le garde
#     doit REFUSER plutôt que rendre un vert sur un ensemble vide.
python3 - "$DOC" "$GEL" <<'EOF'
import json, re, sys
d, g = sys.argv[1], sys.argv[2]
t = open(d, encoding="utf-8").read()
open(d, "w", encoding="utf-8").write(re.sub(r"^\| ", "  ", t, flags=re.M))
j = json.load(open(g, encoding="utf-8"))
j["binaire"].pop("md5", None); j["binaire"].pop("archive", None)
json.dump(j, open(g, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
EOF
essai "D zéro couple confronté — le garde refuse d'avoir examiné zéro"
cp "/tmp/emp-doc.$$" "$DOC"; cp "/tmp/emp-gel.$$" "$GEL"

rm -f "/tmp/emp-gel.$$" "/tmp/emp-doc.$$"

if ! python3 "$G" >/dev/null 2>&1; then
  echo "RESTAURATION INCOMPLÈTE : une empreinte reste fausse après les injections."
  python3 "$G"
  exit 2
fi
[ $rc -eq 0 ] && echo "les quatre injections mordent, l'état est restauré."
exit $rc
