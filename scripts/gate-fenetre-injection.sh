#!/usr/bin/env bash
# PREUVE DE MORSURE du garde de fenêtre, et PREUVE QU'IL EST BRANCHÉ AUX DEUX SITES.
#
# Le garde vient du hub (`hub/tools/garde-fenetre.sh`) : il refuse un geste quand un voisin
# tient une fenêtre de mesure ouverte sur ce dépôt. Il est appelé, jamais recopié — donc lu
# dans l'arbre de travail du hub, et sa mention de régime remonte au portillon.
#
# ⛔ DEUX QUESTIONS DISTINCTES, ET UN GARDE ABONNÉ NE PROUVE PAS UN GARDE BRANCHÉ :
#   A. le garde mord-il quand la fenêtre me nomme ? — éprouvé par sa couture `--depuis-entree`
#   B. les deux sites l'appellent-ils VRAIMENT ? — éprouvé par un leurre à la place du hub, qui
#      dépose un marqueur : le marqueur prouve que la ligne s'exécute, pas qu'elle est écrite.
#
# Les deux sites sont le crochet de poussée ET `build.sh`, qui réécrit `bp3` sans qu'aucun git
# n'intervienne alors que les voisins consomment ce dépôt par lien symbolique.
set -u
cd "$(dirname "$0")/.."
GARDE="$HOME/dev/bp/hub/tools/garde-fenetre.sh"
echec=0

# ── régime : le garde est du code voisin lu vivant, on dit sous quel état il a été éprouvé ──
HUB="$HOME/dev/bp/hub"
if [ ! -f "$GARDE" ]; then
  echo "ÉCHEC : le garde de fenêtre est introuvable — le portillon appelle un fichier absent"
  exit 1
fi
publie=$(git -C "$HUB" rev-parse --short '@{u}' 2>/dev/null) || publie=""
if [ -z "$publie" ]; then
  echo "ÉCHEC : impossible de lire le commit publié du hub — la mention de régime se tairait"
  exit 1
fi
sale=""
[ -n "$(git -C "$HUB" status --porcelain 2>/dev/null)" ] && sale="~sale"
echo "[regime] SOURCE VIVE : hub @ ${publie}${sale} — garde-fenetre.sh lu dans son arbre de travail"

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

# ═══ A. LA MORSURE, par la couture qui change la SOURCE de la liste, jamais la décision ═══

MOI="▸ kairos — jusqu'à 23:59 · bpx, bp3-engine, kronos · lit le COMMIT PUBLIÉ · TOUT l'arbre · mesure"
AUTRES="▸ kairos — jusqu'à 23:59 · bpx, kronos · lit le COMMIT PUBLIÉ · TOUT l'arbre · mesure"
MIENNE="▸ bp3-engine — jusqu'à 23:59 · bp3-engine · lit le COMMIT PUBLIÉ · TOUT l'arbre · mesure"

echo "1. une fenêtre de voisin qui NOMME ce dépôt — le garde doit refuser"
sortie=$(printf '%s\n' "$MOI" | BP_AGENT=bp3-engine bash "$GARDE" --depuis-entree 2>&1); code=$?
if [ $code -eq 0 ]; then
  echo "   ÉCHEC : laisse passer alors que la fenêtre le nomme — figurant"; echec=1
elif ! printf '%s' "$sortie" | grep -q "kairos"; then
  echo "   ÉCHEC : refuse sans nommer le voisin qui mesure"; echec=1
else
  echo "   refuse (sortie $code) et nomme kairos ✔"
fi

echo "2. ⛔ TÉMOIN NON NUL — la MÊME fenêtre sans ce dépôt doit laisser passer"
if printf '%s\n' "$AUTRES" | BP_AGENT=bp3-engine bash "$GARDE" --depuis-entree >/dev/null 2>&1; then
  echo "   laisse passer ✔ — le refus du volet 1 vient bien du champ des dépôts"
else
  echo "   ÉCHEC : refuse une fenêtre qui ne le concerne pas — il bloquerait sur tout"; echec=1
fi

echo "3. ma propre fenêtre ne me bloque pas moi-même"
if printf '%s\n' "$MIENNE" | BP_AGENT=bp3-engine bash "$GARDE" --depuis-entree >/dev/null 2>&1; then
  echo "   laisse passer ✔"
else
  echo "   ÉCHEC : je me gèlerais moi-même en ouvrant une fenêtre sur mon dépôt"; echec=1
fi

echo "4. liste vide — rien n'est gelé, rien n'est refusé"
if printf '' | BP_AGENT=bp3-engine bash "$GARDE" --depuis-entree >/dev/null 2>&1; then
  echo "   laisse passer ✔"
else
  echo "   ÉCHEC : refuse sans aucune fenêtre ouverte"; echec=1
fi

# ═══ B. LE BRANCHEMENT, par un leurre à la place du hub ═══
# Les deux sites appellent le garde par "$HOME/dev/bp/hub/tools/garde-fenetre.sh". On déplace
# HOME : le leurre dépose un marqueur puis refuse. Marqueur présent = la ligne S'EXÉCUTE.

mkdir -p "$T/leurre/dev/bp/hub/tools"
LEURRE="$T/leurre/dev/bp/hub/tools/garde-fenetre.sh"
poser_leurre() { # poser_leurre <code de sortie>
  rm -f "$T/marqueur"
  printf '#!/usr/bin/env bash\ntouch "%s"\necho "leurre : refus simule" >&2\nexit %s\n' \
    "$T/marqueur" "$1" > "$LEURRE"
  chmod +x "$LEURRE"
}

echo "5. le CROCHET QUE GIT EXÉCUTE l'appelle, et s'arrête avant le portillon"
CROCHET="$(git rev-parse --show-toplevel)/$(git config core.hooksPath)/pre-push"
if [ ! -x "$CROCHET" ]; then
  echo "   ÉCHEC : le crochet lu par core.hooksPath est absent ou non exécutable — $CROCHET"; echec=1
else
  poser_leurre 1
  sortie=$(HOME="$T/leurre" bash "$CROCHET" 2>&1); code=$?
  if [ ! -f "$T/marqueur" ]; then
    echo "   ÉCHEC : le garde n'a pas été exécuté par le crochet — abonné, pas branché"; echec=1
  elif [ $code -eq 0 ]; then
    echo "   ÉCHEC : le crochet rend 0 malgré le refus du garde"; echec=1
  elif printf '%s' "$sortie" | grep -q "portillon bp3-engine"; then
    echo "   ÉCHEC : le crochet a poursuivi jusqu'au portillon — le garde n'est pas en tête"; echec=1
  else
    echo "   exécuté, et le crochet s'arrête (sortie $code) avant le portillon ✔"
  fi
fi

echo "6. la CONSTRUCTION l'appelle aussi — elle réécrit bp3 sans qu'aucun git n'intervienne"
poser_leurre 1
sortie=$(HOME="$T/leurre" ./build.sh --clean 2>&1); code=$?
if [ ! -f "$T/marqueur" ]; then
  echo "   ÉCHEC : build.sh n'exécute pas le garde — le second site est une hypothèse"; echec=1
elif [ $code -eq 0 ]; then
  echo "   ÉCHEC : build.sh rend 0 malgré le refus"; echec=1
elif printf '%s' "$sortie" | grep -q "Cleaning"; then
  echo "   ÉCHEC : build.sh a écrit malgré le refus"; echec=1
else
  echo "   exécuté, et build.sh s'arrête (sortie $code) sans rien écrire ✔"
fi

echo "7. ⛔ TÉMOIN NON NUL du volet 6 — leurre qui laisse passer, la construction doit poursuivre"
poser_leurre 0
sortie=$(HOME="$T/leurre" ./build.sh --clean 2>&1); code=$?
if [ ! -f "$T/marqueur" ]; then
  echo "   ÉCHEC : le garde n'a pas été exécuté"; echec=1
elif ! printf '%s' "$sortie" | grep -q "Cleaning"; then
  echo "   ÉCHEC : build.sh s'arrête même quand le garde passe — le volet 6 ne prouvait rien"; echec=1
else
  echo "   poursuit ✔ — l'arrêt du volet 6 vient bien du garde"
fi

echo "8. la lecture seule n'est pas gelée — --status passe malgré un garde qui refuse"
poser_leurre 1
if HOME="$T/leurre" ./build.sh --status >/dev/null 2>&1 && [ ! -f "$T/marqueur" ]; then
  echo "   passe sans appeler le garde ✔ — lire n'est pas basculer"
else
  echo "   ÉCHEC : --status appelle le garde ou échoue — il ne bascule rien"; echec=1
fi

echo "─────────────────────────────────────────────"
[ $echec -eq 0 ] && echo "MORSURE PROUVÉE : le garde refuse quand la fenêtre nomme ce dépôt, et les deux sites l'exécutent." \
                 || echo "MORSURE NON PROUVÉE — le garde de fenêtre ne protège pas ce qu'il annonce."
exit $echec
