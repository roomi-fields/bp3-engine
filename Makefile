# BP3 Engine — Unified Makefile
#
# Targets:
#   make linux          → bp3 (Linux native)
#   make windows        → bp.exe (Windows via WSL gcc)
#   make wasm           → build/bp3.js + bp3.wasm (Emscripten)
#   make all            → linux + windows + wasm
#   make sync           → csrc/bp3/ → source/BP3/ (checksum-based)
#   make clean-linux    → remove Linux .o only
#   make clean-windows  → remove Windows .o only
#   make clean-wasm     → remove WASM .o only
#   make clean          → remove all build artifacts
#
# Incremental by default: only recompiles changed files.
# Use -j8 for parallel builds: make -j8 all

# === Directories ===
SHARED_SRC  = csrc/bp3
WASM_SRC    = csrc/wasm
NATIVE_SRC  = source/BP3
BUILD       = build
LINUX_OBJ   = $(BUILD)/linux/obj
WINDOWS_OBJ = $(BUILD)/windows/obj
WASM_OBJ    = $(BUILD)/wasm/obj

# === Compilers ===
GCC      = gcc
MINGW    = x86_64-w64-mingw32-gcc
EMCC     = emcc

# === Shared compiler flags ===
CFLAGS_COMMON = -O2 -g -fno-common

# Native flags (Linux + Windows)
NATIVE_CFLAGS = $(CFLAGS_COMMON) -I$(NATIVE_SRC) -MMD -MP

# WASM flags
WASM_CFLAGS = $(CFLAGS_COMMON) \
	-include $(WASM_SRC)/bp3_wasm_platform.h \
	-D__BP3_WASM__=1 \
	-I$(SHARED_SRC) \
	-Wno-implicit-function-declaration \
	-Wno-int-conversion \
	-Wno-incompatible-pointer-types \
	-MMD -MP

# === Linker flags ===
LINUX_LDFLAGS   = -lm -lasound
WINDOWS_LDFLAGS = -lm -lwinmm
WASM_LDFLAGS = \
	-s EXPORTED_FUNCTIONS='["_bp3_init","_bp3_load_grammar","_bp3_load_alphabet","_bp3_load_settings","_bp3_load_settings_params","_bp3_load_tonality","_bp3_load_csound_resources","_bp3_produce","_bp3_get_result","_bp3_get_messages","_bp3_get_midi_events","_bp3_get_midi_event_count","_bp3_get_timed_tokens","_bp3_get_timed_token_count","_bp3_load_object_prototypes","_bp3_set_seed","_bp3_set_write_midi","_bp3_set_timed_tokens_verbose","_bp3_provision_file","_bp3_set_trace","_bp3_get_flag_state","_bp3_set_flag","_bp3_get_flag_names","_malloc","_free","_emscripten_stack_get_base","_emscripten_stack_get_end"]' \
	-s EXPORTED_RUNTIME_METHODS='["ccall","cwrap","UTF8ToString","FS"]' \
	-s ALLOW_MEMORY_GROWTH=1 \
	-s MAXIMUM_MEMORY=4294967296 \
	-s INITIAL_MEMORY=67108864 \
	-s STACK_SIZE=33554432 \
	-s MODULARIZE=1 \
	-s EXPORT_NAME='BP3Module' \
	-s FILESYSTEM=1 \
	--preload-file $(WASM_SRC)/console_strings.json@/console_strings.json \
	-lm

# === Source files ===

# Native sources: everything in source/BP3/
NATIVE_SRCS = $(wildcard $(NATIVE_SRC)/*.c)

# WASM shared sources (from csrc/bp3/)
WASM_BP3_SRCS = \
	$(SHARED_SRC)/ConsoleMain.c \
	$(SHARED_SRC)/ConsoleMemory.c \
	$(SHARED_SRC)/ConsoleMessages.c \
	$(SHARED_SRC)/ConsoleStubs.c \
	$(SHARED_SRC)/CompileGrammar.c \
	$(SHARED_SRC)/CompileProcs.c \
	$(SHARED_SRC)/ProduceItems.c \
	$(SHARED_SRC)/Compute.c \
	$(SHARED_SRC)/Inits.c \
	$(SHARED_SRC)/Misc.c \
	$(SHARED_SRC)/Strings.c \
	$(SHARED_SRC)/CTextHandles.c \
	$(SHARED_SRC)/cJSON.c \
	$(SHARED_SRC)/Encode.c \
	$(SHARED_SRC)/Polymetric.c \
	$(SHARED_SRC)/FillPhaseDiagram.c \
	$(SHARED_SRC)/GetRelease.c \
	$(SHARED_SRC)/DisplayArg.c \
	$(SHARED_SRC)/DisplayThings.c \
	$(SHARED_SRC)/SetObjectFeatures.c \
	$(SHARED_SRC)/TimeSetFunctions.c \
	$(SHARED_SRC)/TimeSet.c \
	$(SHARED_SRC)/Tonality.c \
	$(SHARED_SRC)/Arithmetic.c \
	$(SHARED_SRC)/Automata.c \
	$(SHARED_SRC)/Zouleb.c \
	$(SHARED_SRC)/Interface2.c \
	$(SHARED_SRC)/SaveLoads1.c \
	$(SHARED_SRC)/SaveLoads3.c \
	$(SHARED_SRC)/SoundObjects2.c \
	$(SHARED_SRC)/SoundObjects3.c \
	$(SHARED_SRC)/bp3_random.c \
	$(SHARED_SRC)/bp3_timed_events.c \
	$(SHARED_SRC)/MakeSound.c

# WASM-only sources
WASM_ONLY_SRCS = \
	$(WASM_SRC)/bp3_wasm_stubs.c \
	$(WASM_SRC)/bp3_api.c

WASM_ALL_SRCS = $(WASM_BP3_SRCS) $(WASM_ONLY_SRCS)

# === Object files ===

# Native: source/BP3/Foo.c → build/{linux,windows}/obj/Foo.o
LINUX_OBJS   = $(patsubst $(NATIVE_SRC)/%.c,$(LINUX_OBJ)/%.o,$(NATIVE_SRCS))
WINDOWS_OBJS = $(patsubst $(NATIVE_SRC)/%.c,$(WINDOWS_OBJ)/%.o,$(NATIVE_SRCS))

# WASM: csrc/bp3/Foo.c → build/wasm/obj/Foo.o, csrc/wasm/Foo.c → build/wasm/obj/wasm_Foo.o
WASM_BP3_OBJS  = $(patsubst $(SHARED_SRC)/%.c,$(WASM_OBJ)/%.o,$(WASM_BP3_SRCS))
WASM_ONLY_OBJS = $(patsubst $(WASM_SRC)/%.c,$(WASM_OBJ)/wasm_%.o,$(WASM_ONLY_SRCS))
WASM_ALL_OBJS  = $(WASM_BP3_OBJS) $(WASM_ONLY_OBJS)

# === Dependency files ===
LINUX_DEPS   = $(LINUX_OBJS:.o=.d)
WINDOWS_DEPS = $(WINDOWS_OBJS:.o=.d)
WASM_DEPS    = $(WASM_ALL_OBJS:.o=.d)

-include $(LINUX_DEPS)
-include $(WINDOWS_DEPS)
-include $(WASM_DEPS)

# === Outputs ===
LINUX_BIN   = bp3
WINDOWS_BIN = bp.exe
WASM_TARGET = $(BUILD)/bp3.js

# === Phony targets ===
.PHONY: all linux windows wasm sync clean clean-linux clean-windows clean-wasm

all: linux windows wasm

linux: sync $(LINUX_BIN)

windows: sync $(WINDOWS_BIN)

wasm: $(WASM_TARGET)

# === Sync csrc/bp3/ → source/BP3/ (shared files only, checksum-based) ===
sync:
	@echo "=== Syncing csrc/bp3/ → source/BP3/ (shared files only) ==="
	@for f in $(SHARED_SRC)/*.c $(SHARED_SRC)/*.h; do \
		base=$$(basename "$$f"); \
		dest="$(NATIVE_SRC)/$$base"; \
		if [ -f "$$dest" ]; then \
			if ! cmp -s "$$f" "$$dest"; then \
				cp "$$f" "$$dest"; \
				echo "  updated: $$base"; \
			fi; \
		else \
			cp "$$f" "$$dest"; \
			echo "  added: $$base"; \
		fi; \
	done
	@echo "  sync done."

# === Directory creation ===
$(LINUX_OBJ) $(WINDOWS_OBJ) $(WASM_OBJ):
	mkdir -p $@

# === Linux build ===
$(LINUX_OBJ)/%.o: $(NATIVE_SRC)/%.c | $(LINUX_OBJ)
	$(GCC) $(NATIVE_CFLAGS) -MF $(LINUX_OBJ)/$*.d -c $< -o $@

$(LINUX_BIN): $(LINUX_OBJS)
	$(GCC) $(CFLAGS_COMMON) -o $@ $^ $(LINUX_LDFLAGS)
	@echo "==> Built $(LINUX_BIN)"

# === Windows build (cross-compile with mingw-w64) ===
# Install: sudo apt install gcc-mingw-w64-x86-64
WINDOWS_CFLAGS = $(CFLAGS_COMMON) -I$(NATIVE_SRC) -MMD -MP

$(WINDOWS_OBJ)/%.o: $(NATIVE_SRC)/%.c | $(WINDOWS_OBJ)
	$(MINGW) $(WINDOWS_CFLAGS) -MF $(WINDOWS_OBJ)/$*.d -c $< -o $@

$(WINDOWS_BIN): $(WINDOWS_OBJS)
	$(MINGW) $(CFLAGS_COMMON) -o $@ $^ $(WINDOWS_LDFLAGS)
	@echo "==> Built $(WINDOWS_BIN)"

# === WASM build ===
$(WASM_OBJ)/%.o: $(SHARED_SRC)/%.c | $(WASM_OBJ)
	$(EMCC) $(WASM_CFLAGS) -MF $(WASM_OBJ)/$*.d -c $< -o $@

$(WASM_OBJ)/wasm_%.o: $(WASM_SRC)/%.c | $(WASM_OBJ)
	$(EMCC) $(WASM_CFLAGS) -MF $(WASM_OBJ)/wasm_$*.d -c $< -o $@

$(WASM_TARGET): $(WASM_ALL_OBJS)
	$(EMCC) $(CFLAGS_COMMON) $^ -o $@ $(WASM_LDFLAGS)
	@echo "==> Built $(WASM_TARGET)"

# === Clean ===
clean-linux:
	rm -rf $(LINUX_OBJ) $(LINUX_BIN)

clean-windows:
	rm -rf $(WINDOWS_OBJ) $(WINDOWS_BIN)

clean-wasm:
	rm -rf $(WASM_OBJ) $(WASM_TARGET) $(BUILD)/bp3.wasm $(BUILD)/bp3.data

clean:
	rm -rf $(BUILD) $(LINUX_BIN) $(WINDOWS_BIN)
