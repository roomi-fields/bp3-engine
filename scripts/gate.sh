#!/usr/bin/env bash
# PORTILLON du dépôt bp3-engine — volet 2 de la décision Romain du 2026-07-19
# (hub/decisions/2026-07-19-confronter-via-oracle-et-restaurer-tous-les-guards.md)
#
# Avant cette décision : 13 fichiers de garde portés, ZÉRO lancé par un portillon.
# Aucun hook git, aucune intégration continue, aucune cible « test » au Makefile.
#
# Trois voies, volontairement séparées :
#   RAPIDE   — gardes qui passent aujourd'hui, doivent rester verts.
#   ROUGE    — vrais gardes qui ÉCHOUENT sur un défaut réel du moteur. Ils restent
#              branchés et rouges. On ne les réécrit PAS pour faire verdir : c'est le
#              CODE qui doit bouger (règle explicite de la décision).
#   LENTE    — gardes réels mais longs (> 90 s), hors voie rapide.
# Les outils d'EXPLORATION (rapport imprimé, sortie toujours nulle, mise au point d'un
# bug précis) sont exclus NOMMÉMENT en bas de fichier, avec leur motif.

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
}

if [ "$VOIE" = rapide ] || [ "$VOIE" = tout ]; then
  echo "── voie RAPIDE ───────────────────────────────"
  # Listés un par un, et non par une boucle : le méta-garde anti-bypass doit pouvoir
  # lire ce fichier sans interpréter du shell. Un garde qui doit deviner ne garde rien.
  lancer "test-midi-bug"          60 node scripts/test-midi-bug.js
  lancer "test-midi-reinit"       60 node scripts/test-midi-reinit.js
  lancer "test-reinit"            60 node scripts/test-reinit.js
  lancer "test-repro-exact"       60 node scripts/test-repro-exact.js
  lancer "test-sequence"          60 node scripts/test-sequence.js
  lancer "test-visser3-only"      60 node scripts/test-visser3-only.js
  lancer "test-visser3-sequence"  60 node scripts/test-visser3-sequence.js
  lancer "test-visser3-setting"   60 node scripts/test-visser3-setting.js
  lancer "test-settings-params"   60 node scripts/test-settings-params.js
  lancer "baseline-integrite" 60 python3 scripts/gate-baseline.py
  lancer "anti-bypass"        60 python3 scripts/gate-meta.py
  lancer "anti-bypass-morsure" 90 ./scripts/gate-meta-injection.sh
  lancer "anti-retrocompat"   60 python3 scripts/gate-legacy.py
  lancer "anti-retro-morsure" 90 ./scripts/gate-legacy-injection.sh
  lancer "ancrages-locaux"    60 python3 scripts/gate-ancrages.py
  lancer "ancrages-morsure"   90 ./scripts/gate-ancrages-injection.sh
  lancer "effondrement-morsure" 90 ./scripts/gate-effondrement-injection.sh
  lancer "non-retour-bug55"   60 ./scripts/verif-bug55.sh
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

if [ "$VOIE" = lente ] || [ "$VOIE" = tout ]; then
  echo "── voie LENTE ────────────────────────────────"
  # ⚠ COUVERTURE REELLE MESUREE : 25 grammaires sur 110 (23 %). Il ne va PAS plus loin :
  # il est bloque sur `cloches1` (production galopante, BPE-14), pas lent par volume —
  # 25 traitees a 60 s, toujours 25 a 200 s. Ne pas lire son « vert » comme une couverture
  # du corpus tant que BPE-14 n'est pas corrige.
  lancer "test-all" 600 node scripts/test-all.js
fi

echo "─────────────────────────────────────────────"
echo "  $VERT vert(s), $ROUGE rouge(s)"
[ "$VOIE" = rouge ] && exit 0   # cette voie est informative : son rouge est attendu
exit $(( ROUGE > 0 ? 1 : 0 ))

# ── EXCLUS NOMMÉMENT — outils d'exploration, pas des gardes ───────────────────
# scripts/test-crashers.js        aucun code de sortie non nul : il imprime un rapport
#                                 et sort toujours zéro. Ne peut rien garder.
# scripts/test-visser3-bisect.js  outil de bissection, sert à isoler un cas, pas à garder.
# scripts/test-visser3-debug.js   outil de mise au point d'un écart d'état, idem.
