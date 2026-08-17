#!/usr/bin/env bash
# La branche « library » — le jeu de grammaires natif, indépendant des deux lignes du dépôt.
#
#   construire   (re)fabrique la branche depuis wasm-deprecated
#   poser        pose le dossier library/ sur le disque, par arbre rattaché
#   retirer      retire ce dossier ; la branche reste
#
# ⛔ LA CONSTRUCTION PASSE PAR UN INDEX TEMPORAIRE, ET CE N'EST PAS UN DÉTOUR DE STYLE.
# La manœuvre évidente — basculer sur une branche orpheline, vider, extraire library/, committer —
# fait passer git sur l'arbre de travail. Mesuré dans un clone jetable le 2026-08-17 : elle salit
# 39 grammaires de test-data d'un coup, git voulant y convertir des fins de ligne CRLF (le dépôt
# n'a ni .gitattributes ni core.autocrlf). Ce dépôt est consommé par lien symbolique, et Kanopi
# refuse de démarrer en production quand un dépôt qu'il consomme porte des modifications non
# enregistrées. L'index temporaire ne touche aucun fichier du disque : c'est la seule raison.
#
# L'arbre rattaché est OPTIONNEL. Aucun code d'aucun dépôt n'ouvre bp3-engine/library/ — les
# scènes qui citent ce chemin le font en commentaire de traçabilité (mesuré par l'architecte sur
# les six dépôts, 2026-08-17). Il sert à qui veut ouvrir les fichiers et comparer.
set -eu

R=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
cd "$R"
SOURCE=origin/wasm-deprecated       # la branche où les 91 fichiers vivent depuis 4ea046e
BRANCHE=library

construire() {
    git rev-parse --verify -q "$SOURCE:library" >/dev/null \
        || { echo "⛔ $SOURCE:library introuvable — 'git fetch origin' d'abord"; exit 1; }
    local idx arbre commit
    idx=$(mktemp -u /tmp/library-index.XXXXXX)
    GIT_INDEX_FILE="$idx" git read-tree "$SOURCE:library"
    arbre=$(GIT_INDEX_FILE="$idx" git write-tree)
    rm -f "$idx"
    commit=$(git commit-tree "$arbre" -m "library: le jeu de grammaires natif, branche indépendante

91 fichiers, quatre familles — examples, experimental, tabla, western — plus index.json. Chaque
dossier porte grammar.gr, settings.json et parfois alphabet.al. Contenu repris tel quel de
$SOURCE, où il vit depuis 4ea046e.")
    git branch -f "$BRANCHE" "$commit"
    local n hors
    n=$(git ls-tree -r --name-only "$BRANCHE" | wc -l)
    hors=$(git ls-tree --name-only "$BRANCHE" | grep -cvE '^(examples|experimental|tabla|western|index\.json)$' || true)
    echo "branche $BRANCHE : $(git rev-parse --short "$BRANCHE") — $n fichiers, $hors hors des quatre familles"
    [ "$hors" -eq 0 ] || { echo "⛔ la branche porte autre chose que le jeu"; exit 1; }
}

poser() {
    [ -d library ] && { echo "library/ est déjà là"; return; }
    git worktree add -q library "$BRANCHE"
    echo "posé : $(find library -name grammar.gr | wc -l) grammaires, \
$(find library -name alphabet.al | wc -l) alphabets"
}

retirer() {
    git worktree remove --force library 2>/dev/null || rm -rf library
    echo "retiré ; la branche $BRANCHE reste"
}

case "${1:-}" in
    construire) construire ;;
    poser)      poser ;;
    retirer)    retirer ;;
    *) echo "usage: $0 {construire|poser|retirer}"; exit 2 ;;
esac
