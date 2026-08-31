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
# LA LISTE DES OUTILS SE DÉRIVE DE `hub/tools/PORTILLON.txt`, qui fait autorité. Une liste écrite
# ici protégerait de la DISPARITION d'un outil et serait AVEUGLE à son APPARITION : un outil neuf
# du hub n'entrerait jamais dans ce portillon sans que quelqu'un édite la ligne. Mesuré le
# 2026-08-31 : la liste en dur portait deux noms quand le hub en nommait trois, et
# `garde-source-voisine.py` n'était atteint ni par lancement ni par lecture — zéro sur les deux
# axes, trace du crochet entier, témoins non nuls.
#
# ⛔ ET UNE LISTE DÉRIVÉE PERD LE REFUS DE ZÉRO QUE LA LISTE EN DUR DONNAIT GRATUITEMENT : liste
# absente, ou ne nommant aucun outil, et la boucle tourne à vide puis sort au VERT en se déclarant
# complète. Les deux cas refusent ici, et le compte des outils lancés s'AFFIRME au lieu de se taire.
set -e

# BP3_HUB surcharge la racine du dossier partagé. Elle existe pour ÉPROUVER la branche « dossier
# introuvable » SANS DÉPLACER le dépôt de l'architecte : trois agents l'ont fait le 2026-08-14 et
# ont rendu ses outils invisibles aux quinze autres pendant leur mesure. On teste la BRANCHE, pas
# l'absence réelle.
racine="$(git rev-parse --show-toplevel)"
hub="${BP3_HUB:-$(cd "$racine/.." && pwd)/hub}"
moi="$(basename "$racine")"

if [ ! -d "$hub/tools" ]; then
  echo "✗ gardes documentaires INEXÉCUTABLES — dossier introuvable : $hub/tools" >&2
  echo "  Ces gardes ne se sautent pas : sans eux, le portillon n'est pas complet." >&2
  exit 1
fi

LISTE="$hub/tools/PORTILLON.txt"
if [ ! -f "$LISTE" ]; then
  echo "✗ gardes documentaires INEXÉCUTABLES — liste d'autorité introuvable : $LISTE" >&2
  echo "  Sans elle, ce maillon ne sait pas ce qu'il doit lancer, et un vert ne vaudrait rien." >&2
  exit 1
fi
# Une ligne = un outil. Les commentaires et les lignes vides se sautent.
OUTILS="$(sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "$LISTE")"
attendus=0
for g in $OUTILS; do attendus=$((attendus + 1)); done
if [ "$attendus" -eq 0 ]; then
  echo "✗ gardes documentaires INEXÉCUTABLES — $LISTE ne nomme AUCUN outil." >&2
  echo "  Une boucle sur rien sort au vert en se déclarant complète : elle est refusée ici." >&2
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

# ⛔ LA MENTION DE RÉGIME — décision de l'architecte du 2026-08-19.
# Ce maillon n'appelle pas une donnée du voisin, il EXÉCUTE SON CODE, pris dans son arbre de
# travail. Son verdict change quand le hub écrit, sans qu'une ligne bouge ici : il n'est pas
# reproductible, et inscrit à un registre il se lirait comme un fait.
# Elle ÉCHOUE plutôt que de s'afficher vide — une mention muette certifierait un verdict sans
# régime, l'inverse exact de ce qu'elle sert.
publie=$(git -C "$hub" rev-parse --short '@{u}' 2>/dev/null) || {
  echo "✗ gardes documentaires — régime de lecture INDÉTERMINABLE dans $hub" >&2
  echo "  Un verdict sans régime se lit comme reproductible ; il ne sort pas." >&2
  exit 1
}
[ -n "$publie" ] || { echo "✗ gardes documentaires — régime vide, refusé." >&2; exit 1; }
# ⛔ `--no-optional-locks` : sans lui, `git status` RAFRAÎCHIT l'index du voisin et y prend
# `.git/index.lock`. Celui qui subit voit sa commande git échouer sur « Unable to create
# index.lock », rare et inexplicable de son côté. Mesuré sur un cobaye à index périmé et arbre
# SALE : 1 verrou sans le drapeau, 0 avec, sortie identique à l'empreinte près. Le drapeau ne
# va QUE sur `status` — `rev-parse` et `log -1` prennent zéro verrou, il y serait décoratif.
[ -z "$(git --no-optional-locks -C "$hub" status --porcelain)" ] || publie="$publie~sale"
echo "[regime] SOURCE VIVE : hub @ $publie — code exécuté depuis son arbre de travail"

lances=0
for g in $OUTILS; do
  python3 "$hub/tools/$g" --depot "$moi"
  lances=$((lances + 1))
done
# ⛔ LE COMPTE S'AFFIRME. Un garde qui se contente de ne pas rougir ne dit pas s'il a examiné
# quelque chose ; celui-ci nomme combien d'outils il a lancés, et refuse d'en avoir lancé moins
# que la liste n'en nommait.
if [ "$lances" -ne "$attendus" ]; then
  echo "✗ gardes documentaires — $lances outil(s) lancé(s) pour $attendus nommé(s) dans $LISTE." >&2
  exit 1
fi
echo "✓ gardes documentaires — $lances outil(s) du hub lancé(s), dérivés de $LISTE"
