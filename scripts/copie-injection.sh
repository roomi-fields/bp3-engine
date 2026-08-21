#!/usr/bin/env bash
# LA COPIE OU LES INJECTIONS S'ÉPROUVENT — hors de l'arbre de travail.
#
# ⛔ POURQUOI : le geste qui rend un garde crédible est exactement celui qui salit l'arbre.
# Mesuré ici le 2026-08-21 : le portillon écrivait SEPT fichiers dans l'arbre de travail,
# dont `source/BP3/PlayThings.c` — le code de Bernard Bel — et le binaire oracle. Chacun
# restauré en moins d'un dixième de seconde. Un voisin qui lit l'arbre dans cette fenêtre
# voit une modification NON DÉCLARÉE du moteur d'origine : la faute la plus grave de la
# charte, fabriquée par le portillon qui la surveille.
#
# CE QUE LA COPIE PORTE, et chaque clause vient d'un faux verdict mesuré dans la tour :
#   les RÉFÉRENCES         une archive nue fait rougir tout garde qui lit un commit publié
#   la CONFIGURATION       un clone frais perd `core.hooksPath` : « portillon non armé »
#   le TRAVAIL NON SUIVI   les modifications en cours, ET ce que le dépôt ignore
#                          délibérément — population invisible à `git status`
#   le NOM du dépôt        un garde qui s'identifie par son dossier annonce, sous un nom de
#                          circonstance, un dépôt que la tour ne connaît pas
#
# ⛔ LE CAS PROPRE À CE DÉPÔT : `builds/` pèse 730 Mo et porte les binaires natifs FIGÉS,
# qui sont l'oracle. Les recopier à chaque poussée est intenable ; les lier en dur exposerait
# l'oracle à une écriture. La copie les atteint donc par LIEN SYMBOLIQUE, et l'empreinte du
# binaire de référence est relevée avant et après : une écriture dessus fait échouer, elle
# n'avertit pas.
set -eu

SOURCE="$(cd "$(dirname "$0")/.." && pwd)"
NOM="$(basename "$SOURCE")"
# Hors de l'arbre : une copie posée dedans salirait ce qu'elle protège.
RACINE="${BP3_COPIE_RACINE:-${TMPDIR:-/tmp}/bp3-copie-injection}"
COPIE="$RACINE/$NOM"          # le dossier porte le NOM du dépôt, pas un nom de circonstance

ORACLE="builds/v3.5.1-iso.2/bp3"

case "${1:-poser}" in
poser)
  rm -rf "$RACINE"
  mkdir -p "$RACINE"

  # Références et objets PARTAGÉS : 1,6 Mo au lieu de 37, et l'historique est là.
  git clone --quiet --shared --no-hardlinks \
    --branch "$(git -C "$SOURCE" rev-parse --abbrev-ref HEAD)" \
    "$SOURCE" "$COPIE" 2>/dev/null

  # Les distants réels, que le clone remplace par un chemin local.
  git -C "$SOURCE" remote | while read -r r; do
    git -C "$COPIE" remote remove "$r" 2>/dev/null || true
    git -C "$COPIE" remote add "$r" "$(git -C "$SOURCE" remote get-url "$r")"
  done
  # Les références distantes, recopiées telles quelles : sans elles, tout garde qui lit
  # un commit publié rougit sur un dépôt sain.
  git -C "$SOURCE" for-each-ref --format='%(refname) %(objectname)' refs/remotes \
    | while read -r ref obj; do git -C "$COPIE" update-ref "$ref" "$obj" 2>/dev/null || true; done

  # La configuration locale — `core.hooksPath` en tête.
  git -C "$SOURCE" config --local --list | while IFS='=' read -r cle val; do
    case "$cle" in core.repositoryformatversion|core.bare|remote.*|branch.*) continue;; esac
    git -C "$COPIE" config --local "$cle" "$val" 2>/dev/null || true
  done

  # Le travail non enregistré ET ce que le dépôt ignore, sauf les gros artefacts de
  # construction que rien n'éprouve. `builds/` est traité à part, juste après.
  rsync -a --quiet \
    --exclude='.git/' --exclude='builds/' --exclude='build/' --exclude='build_v3.3.*/' \
    --exclude='.rtfm/' --exclude='php/' --exclude='__pycache__/' --exclude='*.o' \
    "$SOURCE"/ "$COPIE"/

  # L'oracle figé, atteint sans être recopié.
  ln -sfn "$SOURCE/builds" "$COPIE/builds"
  git -C "$SOURCE" hash-object "$ORACLE" > "$RACINE/.empreinte-oracle"

  echo "$COPIE"
  ;;

verifier)
  # ⛔ L'oracle figé a-t-il bougé pendant les injections ? Il est atteint par lien
  # symbolique : une écriture depuis la copie atteindrait l'original.
  attendu="$(cat "$RACINE/.empreinte-oracle")"
  obtenu="$(git -C "$SOURCE" hash-object "$ORACLE")"
  if [ "$attendu" != "$obtenu" ]; then
    echo "✗ L'ORACLE FIGÉ A ÉTÉ ÉCRIT PENDANT LES INJECTIONS — $ORACLE" >&2
    echo "  attendu $attendu, obtenu $obtenu. Toute mesure de référence est suspecte." >&2
    exit 1
  fi
  echo "oracle figé intact ($attendu)"
  ;;

retirer)
  rm -rf "$RACINE"
  ;;
esac
