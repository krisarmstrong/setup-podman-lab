#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/logging.sh
. "$SCRIPT_DIR/lib/logging.sh"
# shellcheck source=lib/version.sh
. "$SCRIPT_DIR/lib/version.sh"
# shellcheck source=lib/templates.sh
. "$SCRIPT_DIR/lib/templates.sh"
# shellcheck source=lib/runtime.sh
. "$SCRIPT_DIR/lib/runtime.sh"

LAB_VERSION_FALLBACK="0.5.0"
LAB_VERSION="$(lab_detect_version "$SCRIPT_DIR" "$LAB_VERSION_FALLBACK")"

DEV_USER="dev"
DEV_PASS="dev"   # TODO: change this for real use!
GVM_PASSWORD="${GVM_PASSWORD:-admin}"

LAB_ROOT="${PODMAN_LAB_ROOT:-$HOME}"
PROJECTS_DIR="$LAB_ROOT/PodmanProjects"
DATA_DIR="$LAB_ROOT/PodmanData"

LAB_VERBOSE="${LAB_VERBOSE:-0}"
LAB_LOG_DIR="${LAB_LOG_DIR:-}"
LAB_LOG_FILE="${LAB_LOG_FILE:-}"
LAB_PULL_POLICY="${LAB_PULL:-always}"

lab_init_logging "$LAB_ROOT" "$LAB_VERBOSE" "$LAB_LOG_DIR" "$LAB_LOG_FILE"
lab_log_info "setup-podman-lab.sh version $LAB_VERSION"
lab_log_info "Detailed output will be written to $LAB_LOG_FILE"

progress_bar() {
  local current="$1"
  local total="$2"
  local width=24
  local filled=$((current * width / total))
  local empty=$((width - filled))
  printf '['
  if [ "$filled" -gt 0 ]; then
    printf '#%.0s' $(seq 1 "$filled")
  fi
  if [ "$empty" -gt 0 ]; then
    printf '.%.0s' $(seq 1 "$empty")
  fi
  printf ']'
}

TOTAL_STEPS=7

UNAME_OUT="$(uname -s)"
IS_MAC=false
IS_LINUX=false
if [ "$UNAME_OUT" = "Darwin" ]; then IS_MAC=true; fi
if [ "$UNAME_OUT" = "Linux" ]; then IS_LINUX=true; fi
if $IS_MAC; then
  TOTAL_STEPS=$((TOTAL_STEPS + 1))
fi

STEP=0
step() {
  STEP=$((STEP + 1))
  local bar
  bar="$(progress_bar "$STEP" "$TOTAL_STEPS")"
  lab_log_info "==> [$STEP/$TOTAL_STEPS] $bar $1"
}

LIGHT="false"
if [ "${1:-}" = "light" ]; then
  LIGHT="true"
fi

if [ "${1:-}" = "teardown" ]; then
  lab_log_info "==> ❌ TEARDOWN MODE: Removing all containers, images, and folders."

  podman stop -a >/dev/null 2>&1 || true
  podman rm -f -a >/dev/null 2>&1 || true

  IMGS=$(podman images -q | uniq)
  if [ -n "$IMGS" ]; then
    printf '%s\n' "$IMGS" | while IFS= read -r img; do
      [ -n "$img" ] || continue
      podman rmi -f "$img" >/dev/null 2>&1 || true
    done
  fi

  podman machine stop >/dev/null 2>&1 || true
  podman machine rm -f >/dev/null 2>&1 || true

  rm -rf "$PROJECTS_DIR" "$DATA_DIR"

  lab_log_info "==> Cleanup complete. Folders $PROJECTS_DIR and $DATA_DIR removed."
  exit 0
fi

step "Detecting platform..."
if $IS_MAC; then
  lab_log_info "Detected macOS"
elif $IS_LINUX; then
  lab_log_info "Detected Linux"
else
  lab_log_warn "Unknown platform ($UNAME_OUT). Continuing with generic settings."
fi

if [ "$LIGHT" = "true" ]; then
  lab_log_info "==> Running in **LIGHT** mode (Dev Containers minimized)."
fi

step "Verifying Podman installation..."
if ! command -v podman >/dev/null 2>&1; then
  lab_log_info "Podman not found, installing..."
  if $IS_MAC; then
    if ! command -v brew >/dev/null 2>&1; then
      lab_log_warn "Homebrew not found. Network access is required to install it."
      if [ -z "${AUTO_INSTALL_HOMEBREW:-}" ]; then
        if [ -t 0 ]; then
          read -rp "Proceed with Homebrew install now? [y/N]: " reply
          case "$reply" in
            [Yy]* ) ;;
            * )
              lab_log_warn "Skipping automatic Homebrew install. Install it manually, set AUTO_INSTALL_HOMEBREW=1, or rerun when online."
              exit 1
              ;;
          esac
        else
          lab_log_warn "Set AUTO_INSTALL_HOMEBREW=1 to auto-install or install manually before rerunning."
          exit 1
        fi
      fi
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
      fi
    fi
    brew install podman
  elif [ -f /etc/debian_version ]; then
    sudo apt-get update && sudo apt-get install -y podman
  elif [ -f /etc/fedora-release ]; then
    sudo dnf -y install podman
  else
    lab_log_error "Unsupported OS. Install Podman manually and rerun."
    exit 1
  fi
else
  lab_log_info "Podman already installed."
fi

step "Creating clean host folders..."
lab_setup_directories "$LAB_ROOT" "$PROJECTS_DIR" "$DATA_DIR"

if $IS_MAC; then
  step "Resetting Podman machine to a clean state..."
  if podman machine list 2>/dev/null | grep -q 'podman-machine-default'; then
    lab_log_info "Stopping podman-machine-default (if running)..."
    if ! podman machine stop >>"$LAB_LOG_FILE" 2>&1; then
      lab_log_debug "podman machine stop returned non-zero (likely already stopped)."
    fi
    lab_log_info "Removing podman-machine-default..."
    podman machine rm -f >>"$LAB_LOG_FILE" 2>&1
  fi

  INIT_DISK_SIZE="${PODMAN_MACHINE_DISK_SIZE:-40}"
  lab_run_logged "Initializing Podman machine (4 CPU / 4GB RAM / ${INIT_DISK_SIZE}GB disk)" \
    podman machine init --cpus 4 --memory 4096 --disk-size "$INIT_DISK_SIZE"
  lab_run_logged "Configuring podman machine for rootful mode" podman machine set --rootful
  lab_run_logged "Starting podman machine" podman machine start

  lab_log_info "==> Installing Podman mac helper (if available)..."
  HELPER_PATH="$(brew --prefix podman)/bin/podman-mac-helper"
  if [ -x "$HELPER_PATH" ]; then
    lab_run_logged "Installing podman-mac-helper" sudo "$HELPER_PATH" install
    lab_log_info "==> Restarting Podman machine to apply helper..."
    lab_run_logged "Stopping podman machine after helper install" podman machine stop
    lab_run_logged "Restarting podman machine" podman machine start
  else
    lab_log_warn "podman-mac-helper not found under Homebrew path, skipping helper install."
  fi
else
  lab_log_info "Podman machine setup not required on this platform; using native Podman."
fi

step "Writing all container definitions..."
lab_write_containerfiles "$PROJECTS_DIR" "$DEV_USER" "$DEV_PASS"
lab_log_info "--> Generated dev and tooling Containerfiles under $PROJECTS_DIR"

step "Ensuring podman 'labnet' network exists..."
lab_create_labnet_network

step "Building images..."
lab_build_images "$PROJECTS_DIR" "$LAB_PULL_POLICY"

step "Running core containers and network tools..."
lab_start_containers "$DATA_DIR" "$DEV_USER" "$LIGHT" "$GVM_PASSWORD"

IS_MAC_STR="false"
if $IS_MAC; then
  IS_MAC_STR="true"
fi

lab_show_summary "$DATA_DIR" "$DEV_USER" "$DEV_PASS" "$GVM_PASSWORD" "$IS_MAC_STR"
