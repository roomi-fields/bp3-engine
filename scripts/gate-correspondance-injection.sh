#!/usr/bin/env bash
# PREUVE DE MORSURE du garde de correspondance.
#
# Un garde qu on n a jamais vu echouer est une hypothese, pas une protection. Celui-ci a
# trois volets ; on injecte les trois defauts, un par un, et on exige un ROUGE a chaque fois.
# Tout est restaure a la fin, y compris en cas d interruption.
set -u
cd "$(dirname "$0")/.."

K=/home/romi/dev/bp/kanopi/packages/library
TABLE=$K/test-assets/bp3/correspondance.json
SCENES=$K/scenes/BP3-tests
GARDE=scripts/gate-correspondance.py
TMP=$(mktemp -d)
ECHECS=0

restaurer() {
    [ -f "$TMP/correspondance.json" ] && cp "$TMP/correspondance.json" "$TABLE"
    rm -f "$SCENES/__injection__.gr"
    rm -rf "$TMP"
}
trap restaurer EXIT INT TERM

[ -f "$TABLE" ] || { echo "table absente, rien a prouver"; exit 1; }
cp "$TABLE" "$TMP/correspondance.json"

# --- ligne de base : le garde doit etre VERT avant toute injection -------------------
if ! python3 "$GARDE" >/dev/null; then
    echo "ECHEC : le garde est deja rouge AVANT injection — la preuve ne vaut rien."
    exit 1
fi
echo "ligne de base : vert"

attendre_rouge() {  # $1 = libelle
    if python3 "$GARDE" >/dev/null 2>&1; then
        echo "  FIGURANT : $1 — le garde est reste VERT"
        ECHECS=$((ECHECS + 1))
    else
        echo "  mord : $1"
    fi
    cp "$TMP/correspondance.json" "$TABLE"
}

# --- volet 1 : chemin mort ------------------------------------------------------------
python3 - "$TABLE" <<'PY'
import json, sys
p = sys.argv[1]; t = json.load(open(p, encoding="utf-8"))
for e in t["grammaires"]:
    if e["auxiliaires"]:
        k = next(iter(e["auxiliaires"]))
        e["auxiliaires"][k]["chemin"] = "test-assets/bp3/commun/-se.CE-FICHIER-N-EXISTE-PAS"
        break
json.dump(t, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
PY
attendre_rouge "chemin auxiliaire mort"

# --- volet 2 : grammaire orpheline ----------------------------------------------------
echo "// injection" > "$SCENES/__injection__.gr"
attendre_rouge "grammaire presente sans entree dans la table"
rm -f "$SCENES/__injection__.gr"

# --- volet 4 : la table disparait alors que la bibliotheque est la ---------------------
mv "$TABLE" "$TMP/deplacee.json"
if python3 "$GARDE" >/dev/null 2>&1; then
    echo "  FIGURANT : table supprimee — le garde est reste VERT"
    ECHECS=$((ECHECS + 1))
else
    echo "  mord : table supprimee alors que la bibliotheque est presente"
fi
mv "$TMP/deplacee.json" "$TABLE"

# --- volet 3 : entree fantome ---------------------------------------------------------
python3 - "$TABLE" <<'PY'
import json, sys
p = sys.argv[1]; t = json.load(open(p, encoding="utf-8"))
t["grammaires"][0]["grammaire"] = "scenes/BP3-tests/__fantome__.gr"
json.dump(t, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
PY
attendre_rouge "entree decrivant une grammaire absente"

# --- retour a la ligne de base --------------------------------------------------------
if ! python3 "$GARDE" >/dev/null; then
    echo "ECHEC : le garde reste rouge APRES restauration — l injection n a pas ete defaite."
    exit 1
fi

if [ "$ECHECS" -gt 0 ]; then
    echo "PREUVE INVALIDE : $ECHECS volet(s) n ont pas mordu."
    exit 1
fi
echo "les quatre volets mordent, ligne de base restauree"
