#!/usr/bin/env bash
# GARDES DOCUMENTAIRES DU HUB, APPELÉS DEPUIS LE PORTILLON — décision de Romain du 2026-08-14.
#
# CE QUE CE MAILLON RÉPARE : les deux gardes vivaient dans un bloc greffé APRÈS `verify` dans le
# crochet de poussée. « verify vert » ne valait donc plus « portillon vert ». Les appeler depuis
# `gate.sh` les met au même niveau que mes seize autres contrôles.
#
# UN APPEL, PAS UNE COPIE : la logique reste à sa source unique, `hub/tools/`. Zéro ligne dupliquée.
#
# ⛔ IL ÉCHOUE PLUTÔT QU'IL N'AVERTIT quand le dossier partagé est introuvable : un garde désarmé
# par une absence est invisible, et la poussée passait au vert sans qu'il ait tourné.
#
# LA LISTE DES OUTILS EST UNE SEULE VARIABLE, et la sonde comme l'appel bouclent dessus. Forme de
# runtime-MIDI, meilleure que la sonde par nom : celle-ci corrige le défaut du jour, celle-là
# l'empêche de renaître à la prochaine addition. Un troisième garde s'ajoute à `OUTILS` et se
# retrouve sondé sans qu'on y pense.
set -e

# BP3_HUB surcharge la racine du dossier partagé. Elle existe pour ÉPROUVER la branche « dossier
# introuvable » SANS DÉPLACER le dépôt de l'architecte : trois agents l'ont fait le 2026-08-14 et
# ont rendu ses outils invisibles aux quinze autres pendant leur mesure. On teste la BRANCHE, pas
# l'absence réelle.
racine="$(git rev-parse --show-toplevel)"
hub="${BP3_HUB:-$(cd "$racine/.." && pwd)/hub}"
moi="$(basename "$racine")"

OUTILS="garde-navigation.py garde-copies.py"

if [ ! -d "$hub/tools" ]; then
  echo "✗ gardes documentaires INEXÉCUTABLES — dossier introuvable : $hub/tools" >&2
  echo "  Ces gardes ne se sautent pas : sans eux, le portillon n'est pas complet." >&2
  exit 1
fi

# LE DOSSIER PRÉSENT ET UN OUTIL ABSENT SONT DEUX CAUSES DISTINCTES, et elles se nomment
# séparément. Le message de l'architecte disait « hub introuvable » alors que le hub était là :
# un lecteur cherchait un dossier disparu quand il lui manquait un fichier.
manque=""
for g in $OUTILS; do
  [ -f "$hub/tools/$g" ] || manque="$manque $g"
done
if [ -n "$manque" ]; then
  echo "✗ gardes documentaires INEXÉCUTABLES — absent(s) de $hub/tools :$manque" >&2
  echo "  Ces gardes ne se sautent pas : sans eux, le portillon n'est pas complet." >&2
  exit 1
fi

for g in $OUTILS; do
  python3 "$hub/tools/$g" --depot "$moi"
done
