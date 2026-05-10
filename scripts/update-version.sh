#!/usr/bin/env bash
set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

readonly PACKAGE_REPO="anomalyco/opencode"
readonly RELEASE_BASE_URL="https://github.com/${PACKAGE_REPO}/releases/download"
readonly API_LATEST_URL="https://api.github.com/repos/${PACKAGE_REPO}/releases/latest"
readonly MAX_RETRIES=3
readonly RETRY_BASE_DELAY=2

readonly SYSTEMS=(
  "x86_64-linux:opencode-linux-x64.tar.gz"
  "aarch64-linux:opencode-linux-arm64.tar.gz"
  "x86_64-darwin:opencode-darwin-x64.zip"
  "aarch64-darwin:opencode-darwin-arm64.zip"
)

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

retry() {
  local max_attempts="$1"
  local base_delay="$2"
  shift 2

  for ((attempt = 1; attempt <= max_attempts; attempt++)); do
    local result
    result=$("$@") && [ -n "$result" ] && {
      echo "$result"
      return 0
    }

    if ((attempt < max_attempts)); then
      local delay=$((base_delay ** attempt))
      log_warn "Attempt $attempt/$max_attempts failed, retrying in ${delay}s..."
      sleep "$delay"
    fi
  done

  return 1
}

get_current_version() {
  jq -r '.version' sources.json
}

fetch_latest_version() {
  local latest_version=""

  if command -v gh >/dev/null 2>&1; then
    latest_version=$(GH_PAGER=cat gh release view -R "$PACKAGE_REPO" --json tagName --jq '.tagName' 2>/dev/null | sed 's/^v//' || true)
    if [ -n "$latest_version" ]; then
      echo "$latest_version"
      return 0
    fi
  fi

  local curl_args=(-fsSL --max-time 20)
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  curl "${curl_args[@]}" "$API_LATEST_URL" | jq -r '.tag_name | sub("^v"; "")'
}

get_latest_version() {
  retry "$MAX_RETRIES" "$RETRY_BASE_DELAY" fetch_latest_version
}

prefetch_hash() {
  local version="$1"
  local asset_name="$2"
  local url="${RELEASE_BASE_URL}/v${version}/${asset_name}"

  nix store prefetch-file --hash-type sha256 --json "$url" | jq -r '.hash'
}

write_sources_json() {
  local version="$1"
  local temp_file
  temp_file=$(mktemp)

  {
    echo "{"
    echo "  \"version\": \"$version\","

    local last_index=$((${#SYSTEMS[@]} - 1))
    for index in "${!SYSTEMS[@]}"; do
      IFS=":" read -r nix_system asset_name <<< "${SYSTEMS[$index]}"
      local hash
      hash=$(prefetch_hash "$version" "$asset_name")

      echo "  \"$nix_system\": {"
      echo "    \"name\": \"$asset_name\","
      echo "    \"hash\": \"$hash\""
      if [ "$index" -eq "$last_index" ]; then
        echo "  }"
      else
        echo "  },"
      fi
    done

    echo "}"
  } > "$temp_file"

  mv "$temp_file" sources.json
}

update_flake_lock() {
  log_info "Updating flake.lock..."
  nix flake update
}

verify_build() {
  log_info "Verifying build..."
  nix build .#opencode -o result --print-build-logs
  ./result/bin/opencode --version
}

update_to_version() {
  local new_version="$1"

  log_info "Updating to version $new_version..."
  write_sources_json "$new_version"
  update_flake_lock
  verify_build
}

ensure_in_repository_root() {
  if [ ! -f "flake.nix" ] || [ ! -f "package.nix" ] || [ ! -f "sources.json" ]; then
    log_error "flake.nix, package.nix, or sources.json not found. Please run this script from the repository root."
    exit 2
  fi
}

ensure_required_tools_installed() {
  command -v curl >/dev/null 2>&1 || {
    log_error "curl is required but not installed."
    exit 2
  }
  command -v jq >/dev/null 2>&1 || {
    log_error "jq is required but not installed."
    exit 2
  }
  command -v nix >/dev/null 2>&1 || {
    log_error "nix is required but not installed."
    exit 2
  }
}

print_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --version VERSION  Update to a specific OpenCode version"
  echo "  --check            Only check for updates, don't apply"
  echo "  --latest-version   Print the latest upstream version"
  echo "  --help             Show this help message"
}

parse_arguments() {
  target_version=""
  check_only=false
  latest_version_only=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version)
        if [ $# -lt 2 ]; then
          log_error "--version requires a value"
          exit 2
        fi
        target_version="${2#v}"
        shift 2
        ;;
      --check)
        check_only=true
        shift
        ;;
      --latest-version)
        latest_version_only=true
        shift
        ;;
      --help)
        print_usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        print_usage
        exit 2
        ;;
    esac
  done
}

main() {
  ensure_in_repository_root
  ensure_required_tools_installed
  parse_arguments "$@"

  local latest_version
  if [ -n "${target_version:-}" ]; then
    latest_version="$target_version"
  else
    latest_version=$(get_latest_version)
  fi

  if [ "${latest_version_only:-false}" = true ]; then
    echo "$latest_version"
    exit 0
  fi

  local current_version
  current_version=$(get_current_version)

  log_info "Current version: $current_version"
  log_info "Latest version: $latest_version"

  if [ "$current_version" = "$latest_version" ]; then
    log_info "Already up to date!"
    exit 0
  fi

  if [ "${check_only:-false}" = true ]; then
    log_info "Update available: $current_version -> $latest_version"
    exit 1
  fi

  update_to_version "$latest_version"
  log_info "Successfully updated opencode from $current_version to $latest_version"

  echo ""
  log_info "Changes made:"
  git diff --stat sources.json flake.lock 2>/dev/null || true
}

main "$@"
