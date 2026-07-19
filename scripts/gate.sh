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
  for t in midi-bug midi-reinit reinit repro-exact sequence \
           visser3-only visser3-sequence visser3-setting; do
    lancer "test-$t" 60 node "scripts/test-$t.js"
  done
  lancer "baseline-integrite" 60 python3 scripts/gate-baseline.py
fi

if [ "$VOIE" = rouge ] || [ "$VOIE" = tout ]; then
  echo "── voie ROUGE (défauts moteur connus, NE PAS faire verdir) ──"
  lancer "test-settings-params" 60 node scripts/test-settings-params.js
fi

if [ "$VOIE" = lente ] || [ "$VOIE" = tout ]; then
  echo "── voie LENTE ────────────────────────────────"
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
