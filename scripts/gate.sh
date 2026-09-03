#!/usr/bin/env bash
# PORTILLON du dépôt bp3-engine — volet 2 de la décision Romain du 2026-07-19
# (hub/decisions/2026-07-19-confronter-via-oracle-et-restaurer-tous-les-guards.md)
#
# Avant cette décision : 13 fichiers de garde portés, ZÉRO lancé par un portillon.
# Aucun hook git, aucune intégration continue, aucune cible « test » au Makefile.
#
# Deux voies, volontairement séparées :
#   RAPIDE   — gardes qui passent aujourd'hui, doivent rester verts.
#   ROUGE    — vrais gardes qui ÉCHOUENT sur un défaut réel du moteur. Ils restent
#              branchés et rouges. On ne les réécrit PAS pour faire verdir : c'est le
#              CODE qui doit bouger (règle explicite de la décision).

set -u
cd "$(dirname "$0")/.."
VOIE="${1:-rapide}"
ROUGE=0; VERT=0

lancer() { # lancer <nom> <delai> <commande...>
  local n=$1 d=$2; shift 2
  printf '  %-26s ' "$n"
  if timeout "$d" "$@" >"/tmp/gate.$n.log" 2>&1; then
    echo "vert"; VERT=$((VERT+1))
  else
    local c=$?
    [ $c -eq 124 ] && echo "DÉPASSE $d s" || echo "ROUGE (sortie $c)"
    ROUGE=$((ROUGE+1))
  fi
  # ⛔ LA MENTION DE RÉGIME REMONTE, VERT COMME ROUGE. Le portillon retient la sortie de
  # chaque maillon dans un journal ; une mention qui y reste ne qualifie rien, puisque
  # personne ne lit le journal quand tout est vert. Elle s'affiche sous son maillon.
  grep -h '^\[regime\]' "/tmp/gate.$n.log" 2>/dev/null | sed 's/^/    /' || true
}

if [ "$VOIE" = rapide ] || [ "$VOIE" = tout ]; then
  echo "── voie RAPIDE ───────────────────────────────"
  # ⛔ LES INJECTIONS S'ÉPROUVENT DANS UNE COPIE, JAMAIS DANS L'ARBRE DE TRAVAIL.
  # Mesuré le 2026-08-21 : elles écrivaient sept fichiers ici, dont `source/BP3/PlayThings.c`
  # — le code de Bernard Bel — et le binaire oracle. Un voisin qui lisait l'arbre pendant
  # une poussée voyait l'apparence exacte de la faute la plus grave de la charte.
  # Sans copie, PAS D'INJECTION : un repli sur l'arbre réel rendrait le défaut invisible.
  COPIE="$(./scripts/copie-injection.sh poser)" || {
    echo "  ✗ la copie d'injection n'a pas pu être posée — les morsures ne s'éprouvent pas ici"
    exit 1
  }
  # Listés un par un, et non par une boucle : le méta-garde anti-bypass doit pouvoir
  # lire ce fichier sans interpréter du shell. Un garde qui doit deviner ne garde rien.
  lancer "baseline-integrite" 60 python3 scripts/gate-baseline.py
  lancer "anti-bypass"        60 python3 scripts/gate-meta.py
  lancer "anti-bypass-morsure" 90 "$COPIE/scripts/gate-meta-injection.sh"
  lancer "anti-retrocompat"   60 python3 scripts/gate-legacy.py
  lancer "anti-retro-morsure" 90 "$COPIE/scripts/gate-legacy-injection.sh"
  lancer "ancrages-locaux"    60 python3 scripts/gate-ancrages.py
  lancer "ancrages-morsure"   90 "$COPIE/scripts/gate-ancrages-injection.sh"
  lancer "effondrement-morsure" 90 "$COPIE/scripts/gate-effondrement-injection.sh"
  lancer "non-retour-bug55"   60 ./scripts/verif-bug55.sh
  lancer "sonde-morsure"     120 "$COPIE/scripts/gate-sonde-injection.sh"
  lancer "correspondance"     60 python3 scripts/gate-correspondance.py
  lancer "correspondance-morsure" 90 "$COPIE/scripts/gate-correspondance-injection.sh"
  lancer "gel-baseline"       60 python3 scripts/gel-baseline.py
  lancer "gel-morsure"        90 "$COPIE/scripts/gate-gel-injection.sh"
  lancer "autonomie"          60 python3 scripts/gate-autonomie.py
  lancer "autonomie-morsure"  90 "$COPIE/scripts/gate-autonomie-injection.sh"
  # Le garde de fenêtre vit en TÊTE de ce même crochet : il refuse avant que le portillon
  # ne démarre. Sa morsure s'éprouve ici, dans la copie — le volet qui prouve son branchement
  # lance `build.sh --clean`, qui écrit.
  lancer "fenetre-morsure"    90 "$COPIE/scripts/gate-fenetre-injection.sh"
  # ⛔ Le garde du RETARD DE PUBLICATION vit lui aussi en tête du crochet, et sa ligne se
  # retirait sans que rien ne rougisse — mesuré : 21 verts sur un crochet amputé. Ce maillon
  # tourne DANS L'ARBRE parce que son sujet est le crochet que GIT EXÉCUTE ici, lu par
  # core.hooksPath ; depuis la copie il prouverait le crochet de la copie. Il n'écrit rien :
  # ses leurres vivent dans un dossier jetable, atteints en substituant HOME.
  lancer "retard-morsure"     60 ./scripts/gate-retard-injection.sh
  # L'oracle figé est atteint par lien symbolique depuis la copie : une écriture dessus
  # aurait touché l'original. Le vérifier fait partie du portillon, pas d'un journal.
  lancer "oracle-fige-intact" 30 ./scripts/copie-injection.sh verifier
  lancer "oracle-fige-morsure" 60 "$COPIE/scripts/gate-oracle-injection.sh"
  ./scripts/copie-injection.sh retirer
  # Les deux gardes documentaires du hub, appelés et non recopiés. Ils vivaient dans un bloc greffé
  # après `verify` dans le seul crochet de poussée : « verify vert » ne valait pas « portillon
  # vert ». Ici ils sont au même niveau que les seize autres.
  lancer "documentaires-hub"  90 ./scripts/garde-documentaires.sh
  # ⛔ CETTE INJECTION-CI TOURNE DANS L'ARBRE, ET C'EST DÉLIBÉRÉ. Son décor entier — un hub
  # fabriqué, ses leurres — vit dans un dossier jetable : elle n'écrit pas une ligne ici, ce qui
  # est la raison d'être de la copie. Et son volet nominal doit mesurer CE dépôt : depuis la
  # copie, les outils du hub seraient appelés avec le nom du dossier de copie, qu'aucune table
  # ne connaît, et le vert ne dirait rien de moi.
  lancer "documentaires-morsure" 90 ./scripts/gate-documentaires-injection.sh
fi

# La voie ROUGE porte les défauts MOTEUR connus et non corrigés. On ne les maquille jamais :
# ils restent branchés et rouges jusqu'à ce que le moteur bouge.
# Note historique : son premier occupant, test-settings-params, n'était pas rouge
# à cause du moteur mais à cause de LUI-MÊME — il passait la convention 1 (= FRANÇAIS) à
# une grammaire en notes anglaises. Aligné sur la vérité du moteur et RENFORCÉ (il exige
# désormais la symétrie des conventions), il est vert et vit en voie rapide. Voir BPE-21.
# La voie reste déclarée : le jour où un vrai défaut moteur apparaît, il a sa place.
if [ "$VOIE" = rouge ] || [ "$VOIE" = tout ]; then
  echo "── voie ROUGE (défauts moteur connus, NE PAS faire verdir) ──"
  echo "  (aucun garde dans cette voie — #55, son dernier occupant, est corrige"
  echo "   depuis la v3.4.7 et garde desormais sa non-reapparition en voie rapide)"
fi

echo "─────────────────────────────────────────────"
echo "  $VERT vert(s), $ROUGE rouge(s)"
[ "$VOIE" = rouge ] && exit 0   # cette voie est informative : son rouge est attendu
exit $(( ROUGE > 0 ? 1 : 0 ))
