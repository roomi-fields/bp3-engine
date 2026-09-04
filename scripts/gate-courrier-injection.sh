#!/usr/bin/env bash
# PREUVE DE BRANCHEMENT du garde du courrier non lu.
#
# ⛔ POURQUOI CE MAILLON EXISTE, ET IL A ÉTÉ MESURÉ AVANT D'ÊTRE ÉCRIT. Ce refus vivait dans
# `garde-fenetre.sh`, qui en portait DEUX — les fenêtres de gel ET le courrier non lu. Retirer le
# mécanisme de gel a emporté le second avec lui, chez tous ceux qui l'ont fait. Mesuré ici le
# 2026-09-05 : crochet complet, DEUX lettres non lues en boîte, 21 verts et CODE 0.
# ⇒ *Deux refus dans un même fichier sont DEUX gardes, et ils se retirent séparément.*
#
# ⛔ ET SA LIGNE PEUT SE RETIRER DU CROCHET SANS QUE RIEN NE ROUGISSE — c'est le défaut exact qui a
# valu son existence au maillon du retard. Un garde qui peut se sauter doit ÉCHOUER, jamais se taire.
#
# ⛔ LA PREUVE NE PORTE PAS SUR LA GRAPHIE : un banc qui appelle ma propre porte prouve la PORTE,
# jamais le BRANCHEMENT. Elle se prend sur le crochet que GIT EXÉCUTE, lu par `core.hooksPath`, en
# substituant HOME pour que le chemin du hub tombe sur un leurre — et c'est le CODE DE SORTIE du
# crochet qui tranche, pas son texte.
set -u
cd "$(dirname "$0")/.."

echec=0
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT INT TERM

CROCHET="$(git rev-parse --show-toplevel)/$(git config core.hooksPath)/pre-push"

mkdir -p "$T/leurre/dev/bp/hub/tools"
COURRIER="$T/leurre/dev/bp/hub/tools/garde-courrier-non-lu.sh"
# Les gardes qui SUIVENT dans le crochet laissent passer : sans eux, un crochet mené jusqu'au bout
# rendrait son verdict sur une cause qui n'est pas le sujet de cette épreuve.
printf '#!/usr/bin/env bash\nexit 0\n' \
  > "$T/leurre/dev/bp/hub/tools/gardes-du-portillon.sh"
chmod +x "$T/leurre/dev/bp/hub/tools/gardes-du-portillon.sh"

poser_courrier() { # poser_courrier <code de sortie>
  rm -f "$T/marqueur"
  printf '#!/usr/bin/env bash\ntouch "%s"\necho "leurre : courrier simule" >&2\nexit %s\n' \
    "$T/marqueur" "$1" > "$COURRIER"
  chmod +x "$COURRIER"
}

echo "1. le crochet lu par core.hooksPath existe et s'exécute"
if [ ! -x "$CROCHET" ]; then
  echo "   ÉCHEC : crochet absent ou non exécutable — $CROCHET"; echec=1
else
  echo "   $CROCHET ✔"
fi

echo "2. le CROCHET QUE GIT EXÉCUTE atteint le garde du courrier"
# ⚠️ `timeout` est ici pour que l'ÉCHEC SE NOMME : si la ligne du garde manque, le crochet poursuit
# jusqu'au portillon — donc jusqu'à ce maillon-ci — et sans borne il rendrait « dépassement » au
# lieu de dire ce qu'il a trouvé. Un garde nomme sa cause.
poser_courrier 7
sortie=$(HOME="$T/leurre" BP3_COPIE_RACINE="$T/copie" timeout 20 bash "$CROCHET" 2>&1); code=$?
if [ ! -f "$T/marqueur" ]; then
  echo "   ÉCHEC : le garde n'a pas été exécuté par le crochet — abonné, pas branché"; echec=1
else
  echo "   exécuté ✔"
fi

echo "3. le crochet REFUSE, et il s'arrête avant le portillon"
# ⚠️ CE VOLET N'EXIGE PAS QUE LE CODE DU GARDE REMONTE, et la borne est écrite plutôt que masquée :
# la forme prescrite par la tour est `|| exit 1`, qui refuse sans transmettre. Écrit d'abord en
# copiant le volet du garde du retard — dont la ligne est `|| exit $?` — il exigeait 7 et rougissait
# sur 1, en nommant « le code ne remonte pas » : vrai, et sans rapport avec le branchement mesuré.
# ⇒ *Une assertion reprise d'un autre garde décrit l'autre garde.*
if printf '%s' "$sortie" | grep -q "portillon bp3-engine"; then
  echo "   ÉCHEC : le crochet a poursuivi jusqu'au portillon malgré le refus du garde —"
  echo "           la ligne du garde du courrier ne s'exécute pas avant lui"; echec=1
elif [ $code -eq 0 ]; then
  echo "   ÉCHEC : le crochet rend 0 malgré le refus du garde"; echec=1
elif [ $code -eq 124 ]; then
  echo "   ÉCHEC : le crochet n'a pas rendu la main en 20 s — il ne s'est pas arrêté sur le refus"; echec=1
else
  echo "   sortie $code, portillon non atteint ✔"
fi

echo "4. ⛔ TÉMOIN NON NUL — un leurre qui LAISSE PASSER doit laisser le crochet poursuivre"
# ⛔ ON NE LAISSE PAS LE PORTILLON TOURNER ICI : ce maillon EST dans le portillon, et un crochet mené
# à son terme le relancerait sur lui-même. `grep -q -m1` rend la main dès la bannière, le crochet
# meurt de SIGPIPE à son écriture suivante, et `timeout` est la ceinture. Le sujet du volet est que
# la bannière SOIT ATTEINTE, jamais ce qui vient après.
poser_courrier 0
if HOME="$T/leurre" BP3_COPIE_RACINE="$T/copie" timeout 60 bash "$CROCHET" 2>&1 | grep -q -m1 "portillon bp3-engine"; then
  atteint=1
else
  atteint=0
fi
if [ ! -f "$T/marqueur" ]; then
  echo "   ÉCHEC : le garde n'a pas été exécuté — le volet 2 ne discriminait rien"; echec=1
elif [ "$atteint" -eq 0 ]; then
  echo "   ÉCHEC : le crochet s'arrête alors que le garde laissait passer — le volet 3"
  echo "           aurait rendu son verdict sur un arrêt d'une AUTRE cause"; echec=1
else
  echo "   le crochet atteint le portillon ✔"
fi

echo "5. ⛔ SA PLACE EST LA TÊTE — il refuse AVANT le point d'entrée des gardes partagés"
# Le leurre du point d'entrée dépose un marqueur à lui : s'il est posé alors que le garde du
# courrier refusait, c'est que l'ordre des deux lignes est inversé.
printf '#!/usr/bin/env bash\ntouch "%s"\nexit 0\n' "$T/marqueur-entree" \
  > "$T/leurre/dev/bp/hub/tools/gardes-du-portillon.sh"
chmod +x "$T/leurre/dev/bp/hub/tools/gardes-du-portillon.sh"
rm -f "$T/marqueur-entree"
poser_courrier 7
HOME="$T/leurre" BP3_COPIE_RACINE="$T/copie" timeout 20 bash "$CROCHET" >/dev/null 2>&1
if [ -f "$T/marqueur-entree" ]; then
  echo "   ÉCHEC : le point d'entrée a tourné malgré le refus du courrier — l'ordre est inversé"; echec=1
else
  echo "   le point d'entrée n'est pas atteint ✔"
fi

if [ "$echec" -ne 0 ]; then
  echo "PREUVE INVALIDE : le garde du courrier non lu n'est pas branché au crochet."
  exit 1
fi
echo "les cinq volets tiennent : le garde du courrier est appelé en tête, et son refus arrête le crochet"
