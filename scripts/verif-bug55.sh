#!/usr/bin/env bash
# VÉRIFICATION DU BUG MOTEUR #55 — section de tables Csound non fermée.
#
# Le moteur boucle indéfiniment si un fichier `-cs` valide en tout point omet sa ligne
# de fermeture `_end tables`. Mesuré sur v3.4.4 : aucun retour après 45 s.
#
# Bernard Bel annonce ce bug CORRIGÉ en v3.4.7. La comparaison des sources ne le confirme
# PAS : `csrc/bp3/SaveLoads1.c` et la version amont v3.4.7 sont identiques dans toute la
# boucle de lecture des tables (lignes 437-439). Ce script est donc le seul juge : après
# le passage en v3.4.7, il dit sur pièces si le comportement a changé.
#
# Il vit dans la voie « rouge » du portillon : c'est un défaut moteur connu, non corrigé
# chez nous. On ne le maquille pas, on le mesure.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
DELAI=45

# un fichier -cs authentique, privé de sa SEULE ligne de fermeture
grep -v "^_end tables" -- test-data/-cs.tryCsound > "$T/-cs.sansfin"
printf '// Bol Processor BP3\nRND\nGRAM#1[1] S --> C4 D4\n' > "$T/-gr.essai"

echo "bug #55 — fichier -cs sans « _end tables », moteur $(./bp3 --short-version)"
debut=$(date +%s)
timeout $DELAI ./bp3 produce -e -gr "$T/-gr.essai" -cs "$T/-cs.sansfin" \
    --english --seed 1 -o "$T/out" >"$T/log" 2>&1
code=$?
duree=$(( $(date +%s) - debut ))

if [ $code -eq 124 ]; then
  echo "  ROUGE — le moteur BOUCLE : aucun retour après ${duree} s. Bug #55 toujours présent."
  exit 1
fi
echo "  VERT — le moteur rend la main en ${duree} s (sortie $code) :"
grep -iE "error|=>" "$T/log" | tail -2 | sed 's/^/      /'
echo "  => #55 est corrigé sur cette version. Mettre à jour hub/constats/bugs-moteur-bp3.md."
