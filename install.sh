#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/blaknite/agent-skills"
ARCHIVE_URL="${REPO_URL}/archive/refs/heads/main.tar.gz"
SKILLS_DIR="${HOME}/.config/agents/skills"
SKILL_DIRS=(
  buildkite-pipelines
  buildkite-test-engine
  contextual-code-review
  gathering-branch-context
  linear
  notion-pages
  reading-pull-requests
  starting-linear-issue
  submitting-pull-requests
  technical-discovery
  writing-adrs
  writing-linear-issues
  writing-linear-project-updates
  writing-prds
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

resolve_conflict() {
  local skill="$1"
  local source_dir="$2"
  local target_dir="$3"

  while true; do
    echo ""
    warn "Skill '${skill}' already exists"
    echo "    [o] Overwrite - replace with new version"
    echo "    [s] Skip     - keep existing version"
    echo "    [d] Diff     - show differences, then decide"
    echo "    [b] Backup   - backup existing, then install new"
    read -rp "    Choose [o/s/d/b]: " choice < /dev/tty

    case "$(echo "$choice" | tr '[:upper:]' '[:lower:]')" in
      o)
        rm -rf "$target_dir"
        cp -R "$source_dir" "$target_dir"
        success "Overwrote ${skill}"
        return
        ;;
      s)
        info "Skipped ${skill}"
        return
        ;;
      d)
        echo ""
        echo "--- Differences in ${skill} ---"
        diff -ru "$target_dir" "$source_dir" --exclude='.git' 2>/dev/null || true
        echo "--- End of diff ---"
        ;;
      b)
        local backup="${target_dir}.backup.$(date +%Y%m%d%H%M%S)"
        mv "$target_dir" "$backup"
        cp -R "$source_dir" "$target_dir"
        success "Backed up to $(basename "$backup"), installed new ${skill}"
        return
        ;;
      *)
        echo "    Invalid choice. Please enter o, s, d, or b."
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-deps)
      SKIP_DEPS=true
      shift
      ;;
    *)
      error "Unknown option: $1"
      echo "Usage: $0 [--skip-deps]"
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
