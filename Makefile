# BP3 Engine — Unified Makefile
#
# Targets:
#   make linux          → bp3 (Linux native)
#   make windows        → bp.exe (Windows via WSL gcc)
#   make all            → linux + windows
#   make clean-linux    → remove Linux .o only
#   make clean-windows  → remove Windows .o only
#   make clean          → remove all build artifacts
#
# Incremental by default: only recompiles changed files.
# Use -j8 for parallel builds: make -j8 all

# === Directories ===
NATIVE_SRC  = source/BP3
BUILD       = build
LINUX_OBJ   = $(BUILD)/linux/obj
WINDOWS_OBJ = $(BUILD)/windows/obj

# === Compilers ===
GCC      = gcc
MINGW    = x86_64-w64-mingw32-gcc

# === Shared compiler flags ===
CFLAGS_COMMON = -O2 -g -fno-common

# Native flags (Linux + Windows)
NATIVE_CFLAGS = $(CFLAGS_COMMON) -I$(NATIVE_SRC) -MMD -MP

# === Linker flags ===
# libcurl : dependance introduite par le moteur amont en v3.4.7 (-BP3.h:97), pour la
# fonction « enter_notes » qui pousse une capture MIDI vers un projet web. On passe par
# pkg-config plutot que d'ecrire -I/usr/include/curl en dur : sur cette machine l'en-tete
# est au chemin multiarch /usr/include/x86_64-linux-gnu/curl/, qu'un chemin fige raterait.
CURL_CFLAGS := $(shell pkg-config --cflags libcurl 2>/dev/null)
CURL_LIBS   := $(shell pkg-config --libs libcurl 2>/dev/null || echo -lcurl)
LINUX_LDFLAGS   = -lm -lasound $(CURL_LIBS)
WINDOWS_LDFLAGS = -lm -lwinmm

# === Source files ===

# Native sources: everything in source/BP3/
NATIVE_SRCS = $(wildcard $(NATIVE_SRC)/*.c)

# === Object files ===

# Native: source/BP3/Foo.c → build/{linux,windows}/obj/Foo.o
LINUX_OBJS   = $(patsubst $(NATIVE_SRC)/%.c,$(LINUX_OBJ)/%.o,$(NATIVE_SRCS))
WINDOWS_OBJS = $(patsubst $(NATIVE_SRC)/%.c,$(WINDOWS_OBJ)/%.o,$(NATIVE_SRCS))

# === Dependency files ===
LINUX_DEPS   = $(LINUX_OBJS:.o=.d)
WINDOWS_DEPS = $(WINDOWS_OBJS:.o=.d)

-include $(LINUX_DEPS)
-include $(WINDOWS_DEPS)

# === Outputs ===
LINUX_BIN   = bp3
WINDOWS_BIN = bp.exe

# === Phony targets ===
.PHONY: all linux windows clean clean-linux clean-windows

all: linux windows

linux: $(LINUX_BIN)

windows: $(WINDOWS_BIN)

# === Directory creation ===
$(LINUX_OBJ) $(WINDOWS_OBJ):
	mkdir -p $@

# === Linux build ===
$(LINUX_OBJ)/%.o: $(NATIVE_SRC)/%.c | $(LINUX_OBJ)
	$(GCC) $(NATIVE_CFLAGS) -MF $(LINUX_OBJ)/$*.d -c $< -o $@

$(LINUX_BIN): $(LINUX_OBJS)
	$(GCC) $(CFLAGS_COMMON) $(CURL_CFLAGS) -o $@ $^ $(LINUX_LDFLAGS)
	@echo "==> Built $(LINUX_BIN)"

# === Windows build (cross-compile with mingw-w64) ===
# Install: sudo apt install gcc-mingw-w64-x86-64
WINDOWS_CFLAGS = $(CFLAGS_COMMON) -I$(NATIVE_SRC) -MMD -MP

$(WINDOWS_OBJ)/%.o: $(NATIVE_SRC)/%.c | $(WINDOWS_OBJ)
	$(MINGW) $(WINDOWS_CFLAGS) -MF $(WINDOWS_OBJ)/$*.d -c $< -o $@

$(WINDOWS_BIN): $(WINDOWS_OBJS)
	$(MINGW) $(CFLAGS_COMMON) -o $@ $^ $(WINDOWS_LDFLAGS)
	@echo "==> Built $(WINDOWS_BIN)"

# === Clean ===
clean-linux:
	rm -rf $(LINUX_OBJ) $(LINUX_BIN)

clean-windows:
	rm -rf $(WINDOWS_OBJ) $(WINDOWS_BIN)

clean:
	rm -rf $(BUILD) $(LINUX_BIN) $(WINDOWS_BIN)
