#!/usr/bin/env bash
# PREUVE DE BRANCHEMENT du garde du retard de publication.
#
# ⛔ POURQUOI CE MAILLON EXISTE, ET IL A ÉTÉ MESURÉ AVANT D'ÊTRE ÉCRIT : la ligne
#   `bash "$HOME/dev/bp/hub/tools/garde-publie-a-jour.sh" || exit $?`
# se retirait du crochet SANS QUE RIEN NE ROUGISSE — le portillon rendait ses 21 verts
# sur un crochet amputé. Un garde qui peut se sauter doit ÉCHOUER, jamais se taire.
#
# ⛔ ET LA PREUVE NE PORTE PAS SUR LA GRAPHIE : un banc qui appelle ma propre porte
# prouve la PORTE, jamais le BRANCHEMENT. Elle se prend sur le crochet que GIT EXÉCUTE,
# lu par `core.hooksPath`, en substituant HOME pour que le chemin du hub tombe sur un
# leurre — et c'est le CODE DE SORTIE du crochet qui tranche, pas son texte.
#
# ⚠️ L'espace publié n'est JAMAIS écrit ici : le leurre remplace le garde, pas la donnée
# qu'il mesure. Une épreuve qui falsifie une EMPREINTE la donne à lire à un voisin.
set -u
cd "$(dirname "$0")/.."

echec=0
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT INT TERM

CROCHET="$(git rev-parse --show-toplevel)/$(git config core.hooksPath)/pre-push"

# ⛔ LE CROCHET LANCÉ ICI PEUT ATTEINDRE LE PORTILLON — c'est le sujet du volet 4, et c'est
# aussi ce qui arrive quand la ligne du garde manque. Ce portillon-là poserait sa copie
# d'injection à la racine COMMUNE, et se ferait tuer avant de la retirer : la course suivante
# trouverait un reste et refuserait pour une cause sans rapport. Mesuré ici même. Sa copie va
# donc dans le dossier jetable de cette épreuve.

# Le leurre du garde de FENÊTRE laisse passer : sans lui le crochet s'arrête avant
# d'atteindre le garde du retard, et l'épreuve ne toucherait jamais son sujet.
mkdir -p "$T/leurre/dev/bp/hub/tools"
FENETRE="$T/leurre/dev/bp/hub/tools/garde-fenetre.sh"
RETARD="$T/leurre/dev/bp/hub/tools/garde-publie-a-jour.sh"
printf '#!/usr/bin/env bash\nexit 0\n' > "$FENETRE"; chmod +x "$FENETRE"

poser_retard() { # poser_retard <code de sortie>
  rm -f "$T/marqueur"
  printf '#!/usr/bin/env bash\ntouch "%s"\necho "leurre : retard simule" >&2\nexit %s\n' \
    "$T/marqueur" "$1" > "$RETARD"
  chmod +x "$RETARD"
}

echo "1. le crochet lu par core.hooksPath existe et s'exécute"
if [ ! -x "$CROCHET" ]; then
  echo "   ÉCHEC : crochet absent ou non exécutable — $CROCHET"; echec=1
else
  echo "   $CROCHET ✔"
fi

echo "2. le CROCHET QUE GIT EXÉCUTE appelle le garde du retard"
# ⚠️ `timeout` est ici pour que l'ÉCHEC SE NOMME : si la ligne du garde manque, le crochet
# poursuit jusqu'au portillon — donc jusqu'à ce maillon-ci — et sans borne il rendrait
# « dépassement » au lieu de dire ce qu'il a trouvé. Un garde nomme sa cause.
poser_retard 5
sortie=$(HOME="$T/leurre" BP3_COPIE_RACINE="$T/copie" timeout 20 bash "$CROCHET" 2>&1); code=$?
if [ ! -f "$T/marqueur" ]; then
  echo "   ÉCHEC : le garde n'a pas été exécuté par le crochet — abonné, pas branché"; echec=1
else
  echo "   exécuté ✔"
fi

echo "3. son CODE DE SORTIE remonte, et le crochet s'arrête avant le portillon"
if printf '%s' "$sortie" | grep -q "portillon bp3-engine"; then
  echo "   ÉCHEC : le crochet a poursuivi jusqu'au portillon malgré le refus du garde —"
  echo "           la ligne du garde du retard ne s'exécute pas avant lui"; echec=1
elif [ $code -eq 0 ]; then
  echo "   ÉCHEC : le crochet rend 0 malgré le refus du garde"; echec=1
elif [ $code -eq 124 ]; then
  echo "   ÉCHEC : le crochet n'a pas rendu la main en 20 s — il ne s'est pas arrêté sur le refus"; echec=1
elif [ $code -ne 5 ]; then
  echo "   ÉCHEC : le crochet rend $code, le garde refusait en 5 — le code ne remonte pas"; echec=1
else
  echo "   sortie $code, portillon non atteint ✔"
fi

echo "4. ⛔ TÉMOIN NON NUL — un leurre qui LAISSE PASSER doit laisser le crochet poursuivre"
# ⛔ ON NE LAISSE PAS LE PORTILLON TOURNER ICI : ce maillon EST dans le portillon, et un
# crochet mené à son terme le relancerait sur lui-même. `grep -q -m1` rend la main dès la
# bannière, le crochet meurt de SIGPIPE à son écriture suivante, et `timeout` est la
# ceinture. Le sujet du volet est que la bannière SOIT ATTEINTE, jamais ce qui vient après.
poser_retard 0
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

if [ "$echec" -ne 0 ]; then
  echo "PREUVE INVALIDE : le garde du retard n'est pas branché au crochet."
  exit 1
fi
echo "les quatre volets tiennent : le garde du retard est appelé, et son code remonte"
