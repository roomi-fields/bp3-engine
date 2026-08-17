#!/usr/bin/env bash
# Installe les hooks versionnés du dépôt. À lancer une fois après un clone.
# Idempotent : relançable sans risque.
set -eu
racine="$(cd "$(dirname "$0")/.." && pwd)"
git -C "$racine" config core.hooksPath scripts/githooks
echo "hooks installés : core.hooksPath -> scripts/githooks"
echo "  pre-push : lance ./scripts/gate.sh rapide, refuse le push s'il est rouge."
