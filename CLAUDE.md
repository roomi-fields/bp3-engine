## BP3 Engine — WASM Build of Bol Processor 3

Fork of [bolprocessor/bolprocessor](https://github.com/bolprocessor/bolprocessor) with WebAssembly compilation support.

### Architecture
- `source/BP2/` — Bernard Bel's original C sources (upstream)
- `source/wasm/` — WASM adaptation layer (bp3_api.c, bp3_wasm_stubs.c, bp3_wasm_platform.h)
- `Makefile.emscripten` — Build with Emscripten → `build/bp3.js` + `build/bp3.wasm` + `build/bp3.data`
- `library/` — Shared grammar files (tabla, western, experimental, examples)

### Build
```bash
source /mnt/d/Claude/emsdk/emsdk_env.sh
make -f Makefile.emscripten
```

### Upstream sync
```bash
git fetch upstream
git checkout wasm
git merge upstream/BP3-develop
# Resolve conflicts, rebuild, test
```

### Key conventions
- WASM-specific code uses `#ifdef __BP3_WASM__` guards
- BP3 return values: OK=1, MISSED=0, ABORT=-4 (NOT standard C convention)
- Header files follow Bernard's naming: `-BP2.h`, `-BP2decl.h`, `-BP2main.h`
- Branch `wasm` = our working branch; `master` = upstream mirror

### RTFM — Indexed Knowledge Base

This project has been indexed with RTFM.

For any **exploratory search** (finding which files/modules/classes are relevant
to a topic), use `rtfm_search` instead of Glob, find, ls, or broad Grep.
Then use `rtfm_expand` to read easily most relevant files/sections.
