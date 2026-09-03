#!/usr/bin/env bash
# PREUVE DE MORSURE du garde de correspondance.
#
# Un garde qu on n a jamais vu echouer est une hypothese, pas une protection. Celui-ci a
# trois volets ; on injecte les trois defauts, un par un, et on exige un ROUGE a chaque fois.
#
# ⛔ L INJECTION NE TOUCHE PLUS L ARBRE D UN VOISIN. Le garde lit l espace publie de kanopi,
# qui est en lecture seule pour tout autre que son proprietaire. On en prend donc une COPIE
# et on injecte dedans, par la porte d epreuve du garde.
#
# ⛔ ET CETTE PORTE NE REND JAMAIS ZERO : un vert d epreuve sort en 3. Sans cela, il suffirait
# de fabriquer une racine saine pour mettre un portillon au vert — l epreuve certifierait a la
# place de la mesure.
set -u
cd "$(dirname "$0")/.."

PUBLIE=/home/romi/dev/bp/.publie/kanopi
GARDE=scripts/gate-correspondance.py
TMP=$(mktemp -d)
ECHECS=0
VERT_EPREUVE=3

restaurer() { rm -rf "$TMP"; }
trap restaurer EXIT INT TERM

[ -d "$PUBLIE/packages/library" ] || { echo "bibliotheque absente de l espace publie, rien a prouver"; exit 1; }

# La copie : la bibliotheque et l EMPREINTE, qui porte le regime.
mkdir -p "$TMP/racine/packages"
cp -a "$PUBLIE/packages/library" "$TMP/racine/packages/library"
cp -a "$PUBLIE/EMPREINTE" "$TMP/racine/EMPREINTE"

K=$TMP/racine/packages/library
TABLE=$K/test-assets/bp3/correspondance.json
SCENES=$K/scenes/BP3-tests
export BP3E_KANOPI_EPREUVE="$TMP/racine"

[ -f "$TABLE" ] || { echo "table absente de la copie, rien a prouver"; exit 1; }
cp "$TABLE" "$TMP/correspondance.json"

garde() { python3 "$GARDE" >/dev/null 2>&1; echo $?; }

# --- la porte d epreuve ne rend jamais zero -------------------------------------------
base=$(garde)
if [ "$base" = "0" ]; then
    echo "ECHEC : la porte d epreuve a rendu ZERO — elle pourrait certifier un portillon."
    exit 1
fi
if [ "$base" != "$VERT_EPREUVE" ]; then
    echo "ECHEC : le garde est deja rouge AVANT injection (code $base) — la preuve ne vaut rien."
    exit 1
fi
echo "ligne de base : vert d epreuve (code $base, jamais zero)"

attendre_rouge() {  # $1 = libelle
    c=$(garde)
    if [ "$c" = "$VERT_EPREUVE" ]; then
        echo "  FIGURANT : $1 — le garde est reste VERT"
        ECHECS=$((ECHECS + 1))
    else
        echo "  mord : $1 (code $c)"
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
c=$(garde)
if [ "$c" = "$VERT_EPREUVE" ]; then
    echo "  FIGURANT : table supprimee — le garde est reste VERT"
    ECHECS=$((ECHECS + 1))
else
    echo "  mord : table supprimee alors que la bibliotheque est presente (code $c)"
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

# --- volet 5 : l EMPREINTE disparait — un verdict sans regime ne sort pas --------------
mv "$TMP/racine/EMPREINTE" "$TMP/empreinte-deplacee"
c=$(garde)
if [ "$c" = "$VERT_EPREUVE" ]; then
    echo "  FIGURANT : EMPREINTE absente — le garde est reste VERT"
    ECHECS=$((ECHECS + 1))
else
    echo "  mord : EMPREINTE absente, le regime est indeterminable (code $c)"
fi
mv "$TMP/empreinte-deplacee" "$TMP/racine/EMPREINTE"

# --- retour a la ligne de base --------------------------------------------------------
c=$(garde)
if [ "$c" != "$VERT_EPREUVE" ]; then
    echo "ECHEC : le garde reste rouge APRES restauration (code $c) — l injection n a pas ete defaite."
    exit 1
fi

if [ "$ECHECS" -gt 0 ]; then
    echo "PREUVE INVALIDE : $ECHECS volet(s) n ont pas mordu."
    exit 1
fi
echo "les cinq volets mordent, ligne de base restauree"
