#!/usr/bin/env bash
# PREUVE DE MORSURE du maillon documentaire, et PREUVE QUE SA LISTE EST BIEN DÉRIVÉE.
#
# Le maillon lance les outils du hub que `hub/tools/PORTILLON.txt` nomme — la liste fait autorité
# chez l'architecte, et elle se dérive au lieu de se recopier ici. Mesuré le 2026-08-31 : la liste
# écrite en dur portait deux noms quand le hub en nommait trois, et le troisième n'était atteint ni
# par lancement ni par lecture.
#
# ⛔ UNE LISTE DÉRIVÉE PERD LE REFUS DE ZÉRO QUE LA LISTE EN DUR DONNAIT GRATUITEMENT : liste
# absente, ou ne nommant aucun outil, et la boucle tourne à vide puis sort au VERT en se déclarant
# complète. Les volets 2 et 3 éprouvent ces deux morts silencieuses.
#
# ⛔ ET ABONNÉ N'EST PAS BRANCHÉ : lire le fichier de liste ne prouve pas qu'on lance ce qu'il
# nomme. Le volet 5 pose un leurre à la place d'un outil du hub et regarde son marqueur.
#
# Le hub fabriqué vit dans un dossier jetable désigné par `BP3_HUB` — la surcharge existe pour
# éprouver ces branches SANS DÉPLACER le dépôt de l'architecte, que quinze agents consomment.
set -u
cd "$(dirname "$0")/.."
GARDE="./scripts/garde-documentaires.sh"
HUB="$HOME/dev/bp/hub"
echec=0

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
Z="$T/hub"

# Un hub jetable, avec un amont local : la mention de régime lit `@{u}` et ÉCHOUE sans lui, ce qui
# masquerait le comportement qu'on éprouve.
poser_hub() { # poser_hub <contenu de PORTILLON.txt, vide = fichier absent>
  rm -rf "$Z"; mkdir -p "$Z/tools"
  [ -n "$1" ] && printf '%s\n' "$1" >"$Z/tools/PORTILLON.txt"
  git -C "$Z" init -q
  git -C "$Z" add -A >/dev/null 2>&1
  git -C "$Z" -c user.email=x@x -c user.name=x commit -qm injection >/dev/null 2>&1
  # L'amont se pose par la configuration, jamais par `branch -u` : celui-ci exige un remote
  # déclaré et la branche par défaut varie d'une installation à l'autre. Sans amont, la mention
  # de régime refuse — et le refus qu'on éprouverait serait le sien, pas celui qu'on vise.
  local b
  b=$(git -C "$Z" symbolic-ref --short HEAD 2>/dev/null) || return 0
  git -C "$Z" update-ref "refs/remotes/origin/$b" HEAD 2>/dev/null || return 0
  # Une référence sous `refs/remotes/` ne suffit pas : sans refspec de rapatriement, git refuse
  # de la tenir pour une branche de suivi et `@{u}` échoue.
  git -C "$Z" config remote.origin.url "$Z"
  git -C "$Z" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  git -C "$Z" config "branch.$b.remote" origin
  git -C "$Z" config "branch.$b.merge" "refs/heads/$b"
  return 0
}

# ═══ 1. NOMINAL — sur le hub RÉEL, et le compte affirmé suit l'autorité ═══
# ⛔ Le nominal ne se prend PAS sur un hub fabriqué : celui-ci ne porte pas les tables que les
# outils du hub lisent, ils rougiraient sur mon décor. Et trois refus sans nominal vert ne
# prouveraient rien — un garde qui refuse tout ressemble à un garde qui mord.
echo "1. le hub réel : le maillon passe et AFFIRME son compte"
attendus=$(sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "$HUB/tools/PORTILLON.txt" | wc -l)
sortie=$(bash "$GARDE" 2>&1); code=$?
if [ $code -ne 0 ]; then
  echo "   ÉCHEC : le maillon rougit sur le hub réel (sortie $code)"; echec=1
elif ! printf '%s' "$sortie" | grep -q "✓ gardes documentaires — $attendus outil(s)"; then
  echo "   ÉCHEC : le compte affirmé ne vaut pas les $attendus outils nommés par l'autorité"; echec=1
else
  echo "   passe, et affirme $attendus outil(s) lancé(s) ✔"
fi

# ═══ 2 à 4. LES TROIS MORTS SILENCIEUSES ═══
refuse() { # refuse <numéro> <intitulé> <motif attendu dans la sortie>
  local sortie code
  sortie=$(BP3_HUB="$Z" bash "$GARDE" 2>&1); code=$?
  if [ $code -eq 0 ]; then
    echo "   ÉCHEC : laisse passer — $2"; echec=1
  elif ! printf '%s' "$sortie" | grep -q "$3"; then
    echo "   ÉCHEC : refuse sans nommer sa cause ($3)"; echec=1
  else
    echo "   refuse (sortie $code) et nomme sa cause ✔"
  fi
}

echo "2. la liste d'autorité est INTROUVABLE — sans elle le maillon ne sait pas quoi lancer"
poser_hub ''
refuse 2 "une liste absente laisserait le portillon se déclarer complet" "liste d'autorité introuvable"

echo "3. la liste ne nomme AUCUN outil — que des commentaires"
poser_hub '# rien que des commentaires
#   garde-navigation.py'
refuse 3 "une boucle sur rien sort au vert" "ne nomme AUCUN outil"

echo "4. un outil est NOMMÉ et absent du disque"
poser_hub 'garde-zorglub.py'
refuse 4 "un outil manquant se sauterait en silence" "garde-zorglub.py"

# ═══ 5. LE BRANCHEMENT — la liste est-elle vraiment SUIVIE ? ═══
# Un leurre nommé dans la liste dépose un marqueur puis refuse. Marqueur présent = le maillon
# lance ce que l'autorité nomme, et non une liste qu'il porterait encore en dur.
poser_leurre() { # poser_leurre <code de sortie>
  rm -f "$T/marqueur"
  printf '#!/usr/bin/env python3\nimport pathlib,sys\npathlib.Path("%s").touch()\nsys.exit(%s)\n' \
    "$T/marqueur" "$1" >"$Z/tools/garde-leurre.py"
  chmod +x "$Z/tools/garde-leurre.py"
}

echo "5. un outil NOMMÉ PAR LA LISTE seule est bien lancé, et son refus arrête le maillon"
poser_hub 'garde-leurre.py'
poser_leurre 1
sortie=$(BP3_HUB="$Z" bash "$GARDE" 2>&1); code=$?
if [ ! -f "$T/marqueur" ]; then
  echo "   ÉCHEC : le leurre n'a pas été lancé — la liste est lue, pas suivie"; echec=1
elif [ $code -eq 0 ]; then
  echo "   ÉCHEC : le maillon rend 0 malgré le refus de l'outil"; echec=1
else
  echo "   lancé, et son refus arrête le maillon (sortie $code) ✔"
fi

echo "6. ⛔ TÉMOIN NON NUL du volet 5 — le même leurre qui passe doit laisser le maillon vert"
poser_leurre 0
sortie=$(BP3_HUB="$Z" bash "$GARDE" 2>&1); code=$?
if [ ! -f "$T/marqueur" ]; then
  echo "   ÉCHEC : le leurre n'a pas été lancé"; echec=1
elif [ $code -ne 0 ]; then
  echo "   ÉCHEC : rougit même quand l'outil passe — le volet 5 ne prouvait rien"; echec=1
elif ! printf '%s' "$sortie" | grep -q "✓ gardes documentaires — 1 outil(s)"; then
  echo "   ÉCHEC : n'affirme pas avoir lancé le seul outil nommé"; echec=1
else
  echo "   passe et affirme 1 outil ✔ — le rouge du volet 5 vient bien du leurre"
fi

echo "─────────────────────────────────────────────"
[ $echec -eq 0 ] && echo "MORSURE PROUVÉE : les trois morts silencieuses refusent, et la liste d'autorité est suivie." \
                 || echo "MORSURE NON PROUVÉE — le maillon documentaire ne protège pas ce qu'il annonce."
exit $echec
