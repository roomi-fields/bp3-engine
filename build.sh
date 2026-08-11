#!/usr/bin/env bash
#
# build.sh — Build BP3 engine (Linux, Windows)
#
# Usage:
#   ./build.sh                    → build both targets
#   ./build.sh linux              → build Linux only
#   ./build.sh windows            → build Windows only
#   ./build.sh linux windows      → build Linux + Windows
#   ./build.sh all --archive      → build all + archive in builds/
#   ./build.sh --status           → show build status (dates, staleness)
#   ./build.sh --clean            → clean all build artifacts
#
# Incremental by default. Only recompiles changed .o files.
# Parallel compilation with -j (auto-detects cores).

set -e

# === Paths ===
ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Deploy destinations (migration PC2 natif 2026-06-14 : ex-WSL /mnt/c, /mnt/d morts)
BPSCRIPT_DIR="/home/romi/dev/bp/BPscript"
BPSCRIPT_DIST="$BPSCRIPT_DIR/dist"
# BPweb et MAMP Windows n'existent plus sur PC2 natif. Laissés vides → déploiements
# gardés par `[ -d ]` donc simplement sautés. Oracle S0 = bp3 natif (plus de bp.exe).
BPWEB_DIST=""
MAMP_DIR=""

# Parallelism
JOBS=$(nproc 2>/dev/null || echo 4)

# === Colors ===
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# === Parse arguments ===
TARGETS=()
DO_ARCHIVE=0
DO_STATUS=0
DO_CLEAN=0
ARCHIVE_VERSION=""

for arg in "$@"; do
    case "$arg" in
        linux|windows) TARGETS+=("$arg") ;;
        all)           TARGETS=(linux windows) ;;
        --archive)          DO_ARCHIVE=1 ;;
        --status)           DO_STATUS=1 ;;
        --clean)            DO_CLEAN=1 ;;
        --version=*)        ARCHIVE_VERSION="${arg#--version=}" ;;
        -h|--help)
            echo "Usage: $0 [linux|windows|all] [--archive] [--status] [--clean] [--version=TAG]"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown argument: $arg${NC}"
            exit 1
            ;;
    esac
done

# Default: build all
if [ ${#TARGETS[@]} -eq 0 ] && [ $DO_STATUS -eq 0 ] && [ $DO_CLEAN -eq 0 ]; then
    TARGETS=(linux windows)
fi

cd "$ENGINE_DIR"

# === Status ===
if [ $DO_STATUS -eq 1 ]; then
    echo -e "${CYAN}=== Build Status ===${NC}"

    for target in linux windows; do
        case $target in
            linux)   bin="bp3";       src_dirs="source/BP3" ;;
            windows) bin="bp.exe";    src_dirs="source/BP3" ;;
        esac
        latest_src=$(find $src_dirs -name '*.c' -o -name '*.h' 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
        latest_src_date=$(stat -c '%Y' "$latest_src" 2>/dev/null || echo 0)
        if [ -f "$bin" ]; then
            bin_date=$(stat -c '%Y' "$bin" 2>/dev/null || echo 0)
            if [ "$bin_date" -ge "$latest_src_date" ]; then
                status="${GREEN}UP TO DATE${NC}"
            else
                status="${RED}STALE${NC} ($(basename "$latest_src") newer)"
            fi
            echo -e "  $target: $(ls -l --time-style=long-iso "$bin" | awk '{print $6,$7,$5}') $status"
        else
            echo -e "  $target: ${RED}NOT BUILT${NC}"
        fi
    done

    echo ""
    echo -e "${CYAN}=== Deploy Status ===${NC}"
    deploy_checks=("$BPSCRIPT_DIST/bp3.js")
    [ -n "$BPWEB_DIST" ] && deploy_checks+=("$BPWEB_DIST/bp3.js")
    [ -n "$MAMP_DIR" ]   && deploy_checks+=("$MAMP_DIR/bp.exe")
    for dest in "${deploy_checks[@]}"; do
        if [ -f "$dest" ]; then
            echo "  $(ls -l --time-style=long-iso "$dest" | awk '{print $6,$7}') $dest"
        else
            echo -e "  ${YELLOW}missing${NC} $dest"
        fi
    done

    # Show archived versions
    if [ -d builds ]; then
        echo ""
        echo -e "${CYAN}=== Archived Versions ===${NC}"
        if [ -f builds/LAST ]; then
            echo -e "  LAST → ${GREEN}$(cat builds/LAST)${NC}"
        fi
        ls -d builds/*/ 2>/dev/null | while read d; do
            v=$(basename "$d")
            date=$(head -5 "$d/BUILD_INFO.md" 2>/dev/null | grep "Date:" | sed 's/Date: //')
            echo "  $v  ($date)"
        done
    fi
    exit 0
fi

# === Clean ===
if [ $DO_CLEAN -eq 1 ]; then
    echo -e "${YELLOW}Cleaning all build artifacts...${NC}"
    make clean 2>/dev/null || true
    # Also clean old-style .o in source/BP3/
    rm -f source/BP3/*.o
    echo -e "${GREEN}Clean done.${NC}"
    exit 0
fi

# === Auto-archive safety net ===
# Before building, snapshot current binaries if they're newer than the last archive
auto_archive() {
    if [ ! -f builds/LAST ]; then return; fi
    local last_tag
    last_tag=$(cat builds/LAST)
    local last_dir="builds/$last_tag"
    if [ ! -d "$last_dir" ]; then return; fi

    local needs_archive=0
    for bin in bp3 bp.exe build/bp3.js; do
        if [ -f "$bin" ]; then
            local archived
            archived=$(basename "$bin")
            if [ -f "$last_dir/$archived" ] && [ "$bin" -nt "$last_dir/$archived" ]; then
                needs_archive=1
                break
            fi
        fi
    done

    if [ $needs_archive -eq 1 ]; then
        local auto_num
        auto_num=$(ls -d builds/${last_tag}_auto.* 2>/dev/null | grep -o '[0-9]*$' | sort -n | tail -1)
        auto_num=${auto_num:-0}
        auto_num=$((auto_num + 1))
        local auto_dir="builds/${last_tag}_auto.${auto_num}"
        mkdir -p "$auto_dir"
        [ -f bp3 ] && cp bp3 "$auto_dir/"
        [ -f bp.exe ] && cp bp.exe "$auto_dir/"
        echo -e "${YELLOW}Auto-archived current binaries → $auto_dir/${NC}"
    fi
}

if [ ${#TARGETS[@]} -gt 0 ]; then
    auto_archive
fi

# === Build targets ===
BUILT=()

for target in "${TARGETS[@]}"; do
    echo ""
    echo -e "${CYAN}━━━ Building $target ━━━${NC}"
    start_time=$(date +%s)

    case $target in
        linux)
            make -j"$JOBS" linux 2>&1
            BUILT+=("linux")
            ;;
        windows)
            if ! command -v x86_64-w64-mingw32-gcc &>/dev/null; then
                echo -e "${RED}mingw-w64 not found. Install with: sudo apt install gcc-mingw-w64-x86-64${NC}"
                exit 1
            fi
            make -j"$JOBS" windows 2>&1
            BUILT+=("windows")
            ;;
    esac

    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    echo -e "${GREEN}  $target built in ${elapsed}s${NC}"
done

# === Deploy ===
echo ""
echo -e "${CYAN}━━━ Deploy ━━━${NC}"

for target in "${BUILT[@]}"; do
    case $target in
        windows)
            if [ -f bp.exe ] && [ -d "$MAMP_DIR" ]; then
                cp bp.exe "$MAMP_DIR/bp.exe"
                echo -e "  bp.exe → ${GREEN}$MAMP_DIR/${NC}"
            fi
            ;;
        linux)
            # bp3 stays in engine dir, used directly by test scripts
            echo -e "  bp3 → ${GREEN}$ENGINE_DIR/bp3${NC} (in place)"
            ;;
    esac
done

# === Archive ===
if [ $DO_ARCHIVE -eq 1 ]; then
    echo ""
    echo -e "${CYAN}━━━ Archive ━━━${NC}"

    # Determine version
    # Use base tag from LAST (strip the build counter) or fall back to git tag on current branch
    # Les archives d'avant 2026-08-11 portent un suffixe -wasm.N : c'est un compteur de
    # construction, pas une etiquette de cible. On le lit encore, on n'en mint plus.
    git_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    if [ -f builds/LAST ]; then
        base_tag=$(cat builds/LAST | sed -E 's/-(wasm|build)\.[0-9]+$//')
    else
        base_tag=$(git tag --sort=-version:refname --merged HEAD 2>/dev/null | head -1)
    fi
    [ -z "$base_tag" ] && base_tag="unknown"

    mkdir -p builds
    if [ -n "$ARCHIVE_VERSION" ]; then
        version="$ARCHIVE_VERSION"
    else
        # Auto-increment: next build number for this base tag, legacy -wasm.N compris
        # pour que la numerotation ne reparte pas a 1.
        # Only consider primary archives (not _auto.N backups)
        last_num=$(ls -d builds/${base_tag}-wasm.[0-9]* builds/${base_tag}-build.[0-9]* 2>/dev/null | grep -v '_auto' | grep -oP '(?<=[-.])\d+$' | sort -n | tail -1 || echo 0)
        last_num=${last_num:-0}
        next_num=$((last_num + 1))
        version="${base_tag}-build.${next_num}"
    fi

    archive_dir="builds/$version"
    mkdir -p "$archive_dir"

    # Copy binaries
    [ -f bp3 ]           && cp bp3 "$archive_dir/"
    [ -f bp.exe ]        && cp bp.exe "$archive_dir/"

    # Collect changelog summaries
    changelog_engine=""
    if [ -f CHANGELOG_ENGINE.md ]; then
        changelog_engine=$(head -80 CHANGELOG_ENGINE.md | grep -E "^###|^- |^\| " | head -20)
    fi

    # FEEDBACK_BERNARD points count
    feedback_file="$BPSCRIPT_DIR/test/FEEDBACK_BERNARD.md"
    feedback_count=0
    if [ -f "$feedback_file" ]; then
        feedback_count=$(grep -c "^## [0-9]" "$feedback_file" 2>/dev/null || echo 0)
    fi

    # Diff since previous version
    prev_dir=$(ls -d builds/${base_tag}-wasm.* builds/${base_tag}-build.* 2>/dev/null | sort -t. -k2 -n | tail -2 | head -1)
    diff_section=""
    if [ -n "$prev_dir" ] && [ "$prev_dir" != "$archive_dir" ]; then
        prev_version=$(basename "$prev_dir")
        prev_hash=$(grep "Git hash:" "$prev_dir/BUILD_INFO.md" 2>/dev/null | awk '{print $NF}')
        if [ -n "$prev_hash" ]; then
            diff_section="## Changes since $prev_version
$(git log --oneline ${prev_hash}..${git_hash} 2>/dev/null)"
        fi
    fi

    # Build info
    cat > "$archive_dir/BUILD_INFO.md" <<EOF
# Build $version

Date: $(date '+%Y-%m-%d %H:%M')
Base tag: $base_tag
Git hash: $git_hash
Git branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
FEEDBACK_BERNARD points: $feedback_count

## Files
$(ls -la "$archive_dir"/ | grep -v BUILD_INFO | grep -v "^total" | grep -v "^d")

## Changelogs
See: CHANGELOG_ENGINE.md (fixes for Bernard)

### Engine highlights
$changelog_engine

$diff_section

## Recent commits
$(git log --oneline -10 2>/dev/null)
EOF

    # Update LAST pointer
    echo "$version" > builds/LAST
    echo -e "  Archived as ${GREEN}$version${NC} → $archive_dir/"
    echo -e "  LAST → ${GREEN}$version${NC}"
fi

# === Summary ===
echo ""
echo -e "${GREEN}━━━ Done ━━━${NC}"
for target in "${BUILT[@]}"; do
    case $target in
        linux)   echo -e "  ${GREEN}✓${NC} bp3      $(ls -l --time-style=long-iso bp3 2>/dev/null | awk '{print $5, $6, $7}')" ;;
        windows) echo -e "  ${GREEN}✓${NC} bp.exe   $(ls -l --time-style=long-iso bp.exe 2>/dev/null | awk '{print $5, $6, $7}')" ;;
    esac
done
