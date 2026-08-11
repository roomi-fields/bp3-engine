# BP3 Engine — le moteur natif et son oracle

Fork du [Bol Processor BP3](https://github.com/bolprocessor/bolprocessor) (Bernard Bel) avec
build unifié. Le binaire natif de ce dépôt est l'**oracle** de tout l'écosystème : toute
mesure de référence s'y prend.

**Branche active :** `wasm` (synchronisée avec `graphics-for-BP3` de Bernard)

## Architecture

```
source/BP3/    Un seul arbre de sources — moteur amont + nos ajouts (bp3_timed_events, bp3_random)
test-data/     Corpus d'origine : grammaires -gr et leurs auxiliaires
baseline-native/  La référence gelée, son scellé et l'outil de capture
builds/        Archives versionnées (non tracké git)
build.sh       Script de build + archivage
Makefile       Build unifié linux/windows
```

## Build

Prérequis :
- GCC et `libasound2-dev` (Linux natif)
- mingw-w64 (`x86_64-w64-mingw32-gcc`, pour le cross-compile Windows)

```bash
# Compiler les deux cibles
./build.sh all

# Compiler + archiver avec un tag de version
./build.sh all --archive --version=v3.5.2-build.1

# Compiler une seule cible
./build.sh linux
./build.sh windows

# Voir le status
./build.sh --status
```

`build.sh` produit :
- `bp3` — binaire Linux natif, l'oracle
- `bp.exe` — binaire Windows (cross-compilé via mingw)

`bp.exe` est déployé dans MAMP/bolprocessor/ si le répertoire existe ; `bp3` reste en place,
utilisé directement par l'outil de capture.

## Archivage

```bash
# Archiver le build courant
./build.sh all --archive --version=v3.5.2-build.1

# Le tag est écrit dans builds/LAST
cat builds/LAST
```

Les archives sont dans `builds/{tag}/` avec les binaires + un `BUILD_INFO.md`. Les archives
antérieures au 2026-08-11 portent un suffixe `-wasm.N` : c'est un compteur de construction,
et il reste lisible par la numérotation automatique.

## Synchronisation avec Bernard

```bash
# Récupérer les dernières sources de Bernard
git fetch upstream

# Comparer
git diff upstream/graphics-for-BP3 -- source/BP3/

# Mettre à jour source/BP3/ depuis Bernard
git checkout upstream/graphics-for-BP3 -- source/BP3/
```

Les fichiers qui portent nos deltas se fusionnent à trois voies (`git merge-file`).

## Changelog

- `CHANGELOG_ENGINE.md` — Modifications au code moteur de Bernard
