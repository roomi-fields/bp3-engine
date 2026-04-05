# BP3 Engine — Fork WASM

Fork du [Bol Processor BP3](https://github.com/bolprocessor/bolprocessor) (Bernard Bel) avec portage WebAssembly et build unifié.

**Branche active :** `wasm` (synchronisée avec `graphics-for-BP3` de Bernard)

## Architecture

```
source/BP3/    Code moteur Bernard (v3.3.19) — synchronisé depuis upstream
csrc/bp3/      Copie de source/BP3/ + nos ajouts (bp3_timed_events, bp3_random)
csrc/wasm/     Couche API WASM (bp3_api.c, stubs, platform shim)
builds/        Archives versionnées (non tracké git)
build.sh       Script de build 3 targets + archivage
Makefile       Build unifié linux/windows/wasm
```

Le code dans `csrc/bp3/` est synchronisé avec `source/BP3/` via `make sync`. Les deux sont identiques sauf `bp3_timed_events.c/.h` (notre ajout).

## Build

Prérequis :
- GCC (Linux natif)
- mingw-w64 (`x86_64-w64-mingw32-gcc`, pour le cross-compile Windows)
- [Emscripten](https://emscripten.org/) (pour le WASM)

```bash
# Activer Emscripten
source /path/to/emsdk/emsdk_env.sh

# Compiler les 3 targets
./build.sh all

# Compiler + archiver avec un tag de version
./build.sh all --archive --version=v3.3.19-wasm.1

# Compiler un seul target
./build.sh linux
./build.sh windows
./build.sh wasm

# Voir le status
./build.sh --status
```

`build.sh` produit :
- `bp3` — binaire Linux natif
- `bp.exe` — binaire Windows (cross-compilé via mingw)
- `bp3.js` + `bp3.wasm` + `bp3.data` — module WASM

Les binaires sont déployés automatiquement dans :
- `BPscript/dist/` (WASM)
- `BPweb/dist/` (WASM)
- MAMP/bolprocessor/ (bp.exe, si disponible)

## Archivage

```bash
# Archiver le build courant
./build.sh all --archive --version=v3.3.19-wasm.1

# Le tag est écrit dans builds/LAST
cat builds/LAST
# → v3.3.19-wasm.1
```

Les archives sont dans `builds/{tag}/` avec les 3 binaires + un `BUILD_INFO.md`.

## Synchronisation avec Bernard

```bash
# Récupérer les dernières sources de Bernard
git fetch upstream

# Comparer
git diff upstream/graphics-for-BP3 -- source/BP3/

# Mettre à jour source/BP3/ depuis Bernard
git checkout upstream/graphics-for-BP3 -- source/BP3/

# Synchro source/BP3/ → csrc/bp3/
make sync
```

## API WASM

Voir `WASM_PORT.md` pour la documentation de l'API JavaScript (`bp3_init`, `bp3_load_grammar`, `bp3_produce`, `bp3_get_timed_tokens`, etc.).

## Changelogs

- `CHANGELOG_ENGINE.md` — Modifications au code moteur de Bernard (historique, tout intégré dans v3.3.19)
- `CHANGELOG_WASM.md` — Évolution de la couche WASM (bp3_api.c, stubs, builds)
