#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/blaknite/agent-skills"
ARCHIVE_URL="${REPO_URL}/archive/refs/heads/main.tar.gz"
SKILLS_DIR="${HOME}/.config/agents/skills"
SKILL_DIRS=(
  using-buildkite
  debugging-failed-builds
  debugging-failed-tests
  reviewing-code-with-context
  gathering-context
  using-linear
  reading-notion
  reading-pull-requests
  starting-linear-issue
  submitting-code-reviews
  submitting-pull-requests
  giving-kind-feedback
  performing-technical-discovery
  reading-slack
  responding-to-review-feedback
  specifying-behaviour
  writing-code-reviews
  writing-linear-issues
  writing-linear-project-updates
  writing-prds
  processing-zoom-recordings
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${BLUE}==>${RESET} ${BOLD}$*${RESET}"; }
success() { echo -e "${GREEN}==>${RESET} ${BOLD}$*${RESET}"; }
warn()    { echo -e "${YELLOW}==>${RESET} ${BOLD}$*${RESET}"; }
error()   { echo -e "${RED}==>${RESET} ${BOLD}$*${RESET}" >&2; }

command_exists() { command -v "$1" &>/dev/null; }

check_dependency() {
  local cmd="$1"
  local name="$2"
  local install_hint="$3"

  if command_exists "$cmd"; then
    success "$name found: $(command -v "$cmd")"
    return 0
  else
    warn "$name not found"
    echo "    Install: $install_hint"
    return 1
  fi
}

install_amp() {
  info "Checking for Amp..."

  if command_exists amp; then
    success "Amp is already installed: $(amp --version 2>/dev/null || echo 'version unknown')"
    return
  fi

  info "Installing Amp..."
  curl -fsSL https://ampcode.com/install.sh | bash
  success "Amp installed"
}

install_dependencies() {
  info "Checking skill dependencies..."
  echo ""

  local missing=0

  check_dependency "gh" "GitHub CLI" "brew install gh && gh auth login" || missing=$((missing + 1))
  check_dependency "bk" "Buildkite CLI" "brew install buildkite/buildkite/bk && bk configure" || missing=$((missing + 1))
  check_dependency "linear" "Linear CLI" "brew install schpet/tap/linear" || missing=$((missing + 1))
  check_dependency "slack" "slack-cli" "brew install lox/tap/slack-cli" || missing=$((missing + 1))
  check_dependency "jq" "jq" "brew install jq" || missing=$((missing + 1))
  check_dependency "ruby" "Ruby" "brew install ruby" || missing=$((missing + 1))
  check_dependency "go" "Go" "brew install go (needed for notion-cli)" || missing=$((missing + 1))

  echo ""

  check_dependency "notion-cli" "notion-cli" "go install github.com/lox/notion-cli@latest" || missing=$((missing + 1))

  echo ""

  if [[ $missing -gt 0 ]]; then
    warn "$missing optional dependencies missing (skills that need them may not work)"
  else
    success "All dependencies found"
  fi
}

# Returns 0 if the two directories differ, 1 if they are identical.
# (diff -rq exits 0 when identical, 1 when different — we invert that.)
dirs_differ() {
  local dir1="$1"
  local dir2="$2"
  if diff -rq --exclude='.git' "$dir1" "$dir2" &>/dev/null; then
    return 1  # identical
  else
    return 0  # different
  fi
}

resolve_conflict() {
  local skill="$1"
  local source_dir="$2"
  local target_dir="$3"

  # --- Global conflict mode: skip-all ---
  if [[ "$CONFLICT_MODE" == "skip-all" ]]; then
    info "Skipped ${skill} (--skip-all)"
    return
  fi

  # --- Global conflict mode: overwrite-all ---
  if [[ "$CONFLICT_MODE" == "overwrite-all" ]]; then
    rm -rf "$target_dir"
    cp -R "$source_dir" "$target_dir"
    success "Overwrote ${skill} (--overwrite-all)"
    return
  fi

  # --- Global conflict mode: smart ---
  if [[ "$CONFLICT_MODE" == "smart" ]]; then
    if dirs_differ "$target_dir" "$source_dir"; then
      rm -rf "$target_dir"
      cp -R "$source_dir" "$target_dir"
      success "Updated ${skill} (changes detected)"
    else
      info "Skipped ${skill} (no changes)"
    fi
    return
  fi

  # --- Default: ask interactively ---
  while true; do
    echo ""
    warn "Skill '${skill}' already exists"
    echo "    [o] Overwrite     - replace with new version"
    echo "    [O] Overwrite All - overwrite this and all remaining conflicts"
    echo "    [s] Skip          - keep existing version"
    echo "    [S] Skip All      - skip this and all remaining conflicts"
    echo "    [d] Diff          - show differences, then decide"
    echo "    [m] Smart         - overwrite remaining only if changed"
    echo "    [b] Backup        - backup existing, then install new"
    read -rp "    Choose [o/O/s/S/d/m/b]: " choice < /dev/tty

    case "$choice" in
      o)
        rm -rf "$target_dir"
        cp -R "$source_dir" "$target_dir"
        success "Overwrote ${skill}"
        return
        ;;
      O)
        CONFLICT_MODE="overwrite-all"
        rm -rf "$target_dir"
        cp -R "$source_dir" "$target_dir"
        success "Overwrote ${skill} (overwrite-all mode enabled for remaining)"
        return
        ;;
      s)
        info "Skipped ${skill}"
        return
        ;;
      S)
        CONFLICT_MODE="skip-all"
        info "Skipped ${skill} (skip-all mode enabled for remaining)"
        return
        ;;
      d)
        echo ""
        echo "--- Differences in ${skill} ---"
        diff -ru "$target_dir" "$source_dir" --exclude='.git' 2>/dev/null || true
        echo "--- End of diff ---"
        ;;
      m)
        CONFLICT_MODE="smart"
        if dirs_differ "$target_dir" "$source_dir"; then
          rm -rf "$target_dir"
          cp -R "$source_dir" "$target_dir"
          success "Updated ${skill} (smart mode enabled, changes detected)"
        else
          info "Skipped ${skill} (smart mode enabled, no changes)"
        fi
        return
        ;;
      b)
        local backup="${target_dir}.backup.$(date +%Y%m%d%H%M%S)"
        mv "$target_dir" "$backup"
        cp -R "$source_dir" "$target_dir"
        success "Backed up to $(basename "$backup"), installed new ${skill}"
        return
        ;;
      *)
        echo "    Invalid choice. Please enter o, O, s, S, d, m, or b."
        ;;
    esac
  done
}

install_skills() {
  info "Downloading skills from ${REPO_URL}..."

  TMPDIR_CLEANUP=$(mktemp -d)
  local tmpdir="$TMPDIR_CLEANUP"
  trap 'rm -rf "$TMPDIR_CLEANUP"' EXIT

  if ! curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$tmpdir"; then
    error "Failed to download skills archive"
    return 1
  fi

  local extracted_dir="${tmpdir}/agent-skills-main"

  if [[ ! -d "$extracted_dir" ]]; then
    error "Unexpected archive structure"
    return 1
  fi

  mkdir -p "$SKILLS_DIR"

  local installed=0
  local skipped=0

  for skill in "${SKILL_DIRS[@]}"; do
    local source_dir="${extracted_dir}/${skill}"

    if [[ ! -d "$source_dir" ]]; then
      warn "Skill '${skill}' not found in archive, skipping"
      skipped=$((skipped + 1))
      continue
    fi

    local target_dir="${SKILLS_DIR}/${skill}"

    if [[ -d "$target_dir" ]]; then
      resolve_conflict "$skill" "$source_dir" "$target_dir"
    else
      cp -R "$source_dir" "$target_dir"
      success "Installed ${skill}"
    fi

    installed=$((installed + 1))
  done

  echo ""
  success "Done. ${installed} skills processed, ${skipped} skipped."
}

SKIP_DEPS=false
CONFLICT_MODE="ask"

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --skip-deps        Skip dependency checks"
  echo "  --skip-all         Skip all conflicting skills (keep existing)"
  echo "  --overwrite-all    Overwrite all conflicting skills without prompting"
  echo "  --smart            Only overwrite skills that have changed"
  echo "  --help             Show this help message"
  echo ""
  echo "When no conflict option is given, the installer will prompt for each conflict."
  echo "During prompts you can also switch to a global mode for remaining conflicts."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-deps)
      SKIP_DEPS=true
      shift
      ;;
    --skip-all)
      CONFLICT_MODE="skip-all"
      shift
      ;;
    --overwrite-all)
      CONFLICT_MODE="overwrite-all"
      shift
      ;;
    --smart)
      CONFLICT_MODE="smart"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

main() {
  echo ""
  echo -e "${BOLD}Amp Agent Skills Installer${RESET}"
  echo -e "Source: ${REPO_URL}"
  echo ""

  if [[ "$SKIP_DEPS" == false ]]; then
    install_amp
    echo ""
    install_dependencies
    echo ""
  else
    info "Skipping dependency checks (--skip-deps)"
    echo ""
  fi

  install_skills

  echo ""
  success "Installation complete."
  echo "    Skills installed to: ${SKILLS_DIR}"
  echo "    Amp will automatically discover skills in this directory."
  echo ""
}

main
