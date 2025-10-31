#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/logging.sh
. "$SCRIPT_DIR/lib/logging.sh"
# shellcheck source=lib/version.sh
. "$SCRIPT_DIR/lib/version.sh"
# shellcheck source=lib/templates.sh
. "$SCRIPT_DIR/lib/templates.sh"
# shellcheck source=lib/components.sh
. "$SCRIPT_DIR/lib/components.sh"
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
LAB_PULL_POLICY="${LAB_PULL:-if-needed}"
LAB_IMAGE_PREFIX="${LAB_IMAGE_PREFIX:-podman-lab}"
LAB_PROGRESS_ENABLED="${LAB_PROGRESS_ENABLED:-1}"
LAB_QUIET="${LAB_QUIET:-0}"
LAB_OFFLINE="${LAB_OFFLINE_MODE:-0}"
# Remove trailing slash for consistency
LAB_IMAGE_PREFIX="${LAB_IMAGE_PREFIX%/}"

if [ "$LAB_OFFLINE" = "true" ]; then
  LAB_OFFLINE=1
fi
if [ "$LAB_OFFLINE" = "1" ]; then
  LAB_PULL_POLICY="never"
fi

lab_init_logging "$LAB_ROOT" "$LAB_VERBOSE" "$LAB_LOG_DIR" "$LAB_LOG_FILE"
lab_log_info "setup-podman-lab.sh version $LAB_VERSION"
lab_log_info "Detailed output will be written to $LAB_LOG_FILE"

usage() {
  cat <<'EOF'
Usage: setup-podman-lab.sh [command] [options]

Commands:
  (default)        Build and run the selected profile/components
  light            Shortcut for default run with dev/light stack
  teardown         Stop containers, remove images, and delete lab folders
  rebuild TARGET   Build images for the specified component list/profile
  rerun TARGET     Run containers for the specified component list/profile

Options:
  --components LIST   Build/run only the specified comma-separated components.
  --build-only        Execute build phase only (skip container startup).
  --run-only          Skip image builds and only start containers.
  --profile NAME      Use a predefined component profile (all, dev, net, sec, monitor).
  --no-progress       Disable progress bar output.
  --progress          Enable progress bar output.
  --quiet             Suppress informational console output (logs still recorded).
  --verbose           Stream command output and show debug logs.
  --help              Show this message and exit.

Environment overrides:
  LAB_COMPONENTS      Default component filter (comma-separated).
  LAB_PROFILE         Default profile to apply (all, dev, net, sec, monitor).
  LAB_PULL            Podman build pull policy (default: if-needed).
  LAB_IMAGE_PREFIX    Image tag namespace (default: podman-lab).
  LAB_PROGRESS_ENABLED  Default progress bar toggle (1 enabled, 0 disabled).
  LAB_BUILD_CONCURRENCY  Parallel builds (default 2, set 1 to disable).
  LAB_REGISTRY_MIRROR  Prefix for hostless base images (e.g. registry.example.com/docker).
  LAB_VERBOSE         Default verbose toggle (0/1).
  LAB_QUIET           Default quiet toggle (0/1).
  LAB_LOG_FILE        Override log file path.
  LAB_SKIP_REGISTRY_CHECK  Set to 1 to skip Docker Hub login warning.
  LAB_OFFLINE_MODE    Set to 1 to require pre-pulled base images (disables pulls).
EOF
}

LIGHT="false"
TEARDOWN="false"
DO_BUILD="true"
DO_RUN="true"
COMPONENT_FILTER="${LAB_COMPONENTS:-}"
PROFILE="${LAB_PROFILE:-all}"
TARGET_SPEC=""

while [ $# -gt 0 ]; do
  case "$1" in
    light)
      LIGHT="true"
      ;;
    teardown)
      TEARDOWN="true"
      ;;
    rebuild)
      DO_BUILD="true"
      DO_RUN="false"
      if [ $# -ge 2 ] && [[ "$2" != --* ]]; then
        TARGET_SPEC="$2"
        shift
      fi
      ;;
    rerun)
      DO_BUILD="false"
      DO_RUN="true"
      if [ $# -ge 2 ] && [[ "$2" != --* ]]; then
        TARGET_SPEC="$2"
        shift
      fi
      ;;
    --components)
      if [ $# -lt 2 ]; then
        lab_log_error "--components requires a comma-separated list."
        exit 1
      fi
      COMPONENT_FILTER="$2"
      shift
      ;;
    --components=*)
      COMPONENT_FILTER="${1#*=}"
      ;;
    --build-only)
      DO_RUN="false"
      ;;
    --run-only)
      DO_BUILD="false"
      ;;
    --profile)
      if [ $# -lt 2 ]; then
        lab_log_error "--profile requires a profile name."
        exit 1
      fi
      PROFILE="$2"
      shift
      ;;
    --profile=*)
      PROFILE="${1#*=}"
      ;;
    --no-progress)
      LAB_PROGRESS_ENABLED=0
      ;;
    --progress)
      LAB_PROGRESS_ENABLED=1
      ;;
    --quiet)
      LAB_QUIET=1
      LAB_VERBOSE=0
      ;;
    --verbose)
      LAB_VERBOSE=1
      LAB_QUIET=0
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      lab_log_warn "Unrecognized argument '$1' (ignored)."
      ;;
  esac
  shift
done

if [ "$DO_BUILD" = "false" ] && [ "$DO_RUN" = "false" ]; then
  lab_log_error "Both build and run phases are disabled; nothing to do."
  exit 1
fi

# If a positional target was supplied for rebuild/rerun, map it to profile/components when flags absent
if [ -n "$TARGET_SPEC" ] && [ -z "$COMPONENT_FILTER" ]; then
  if lab_profile_exists "$TARGET_SPEC"; then
    PROFILE="$TARGET_SPEC"
  else
    COMPONENT_FILTER="$TARGET_SPEC"
  fi
fi

lab_components_init "$PROFILE" "$COMPONENT_FILTER"
if [ "$LAB_SELECTED_PROFILE" = "custom" ]; then
  lab_log_info "Profile: custom (explicit component selection)"
elif [ "$LAB_SELECTED_PROFILE" != "all" ]; then
  lab_log_info "Profile: $LAB_SELECTED_PROFILE"
fi
if lab_component_filters_active; then
  lab_log_info "Component filter active: $(lab_component_filter_string)"
fi

if [ "$LAB_OFFLINE" = "1" ]; then
  lab_log_info "Offline mode: expecting all base images to be available locally."
fi

if [ "$TEARDOWN" = "true" ]; then
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

lab_warn_registry_auth() {
  if [ "${LAB_SKIP_REGISTRY_CHECK:-0}" = "1" ]; then
    return
  fi
  if [ "$DO_BUILD" != "true" ]; then
    return
  fi
  if [ "$LAB_OFFLINE" = "1" ]; then
    return
  fi
  if ! command -v podman >/dev/null 2>&1; then
    return
  fi
  set +e
  podman login --get-login docker.io >/dev/null 2>&1
  local status=$?
  set -e
  if [ $status -ne 0 ]; then
    lab_log_warn "Docker Hub authentication not detected. Unauthenticated pulls are rate limited."
    lab_log_warn "Run 'podman login docker.io' before launching the lab to avoid throttling."
    lab_log_warn "Set LAB_SKIP_REGISTRY_CHECK=1 to silence this warning."
  fi
}

UNAME_OUT="$(uname -s)"
IS_MAC=false
IS_LINUX=false
if [ "$UNAME_OUT" = "Darwin" ]; then IS_MAC=true; fi
if [ "$UNAME_OUT" = "Linux" ]; then IS_LINUX=true; fi

TOTAL_STEPS=3
if $IS_MAC; then
  TOTAL_STEPS=$((TOTAL_STEPS + 1))
fi
TOTAL_STEPS=$((TOTAL_STEPS + 1)) # write container definitions
if [ "$DO_RUN" = "true" ]; then
  TOTAL_STEPS=$((TOTAL_STEPS + 1)) # ensure network
fi
if [ "$DO_BUILD" = "true" ]; then
  TOTAL_STEPS=$((TOTAL_STEPS + 1)) # build images
fi
if [ "$DO_RUN" = "true" ]; then
  TOTAL_STEPS=$((TOTAL_STEPS + 1)) # run containers
fi

STEP=0
step() {
  STEP=$((STEP + 1))
  if [ "$LAB_PROGRESS_ENABLED" = "1" ]; then
    local bar
    bar="$(progress_bar "$STEP" "$TOTAL_STEPS")"
    lab_log_info "==> [$STEP/$TOTAL_STEPS] $bar $1"
  else
    lab_log_info "==> [$STEP/$TOTAL_STEPS] $1"
  fi
}

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

if [ "$DO_RUN" = "true" ]; then
  step "Ensuring podman 'labnet' network exists..."
  lab_create_labnet_network
fi

if [ "$DO_BUILD" = "true" ]; then
  if [ "$LAB_OFFLINE" = "1" ]; then
    lab_log_info "Offline mode enabled: skipping remote pulls (LAB_PULL=never)."
    lab_verify_base_images
  fi
  lab_warn_registry_auth
  step "Building images..."
  lab_build_images "$PROJECTS_DIR" "$LAB_PULL_POLICY"
else
  lab_log_info "Skipping image build phase (run-only mode)."
fi

if [ "$DO_RUN" = "true" ]; then
  step "Running core containers and network tools..."
  lab_start_containers "$DATA_DIR" "$DEV_USER" "$GVM_PASSWORD"
else
  lab_log_info "Skipping container startup (build-only mode)."
fi

IS_MAC_STR="false"
if $IS_MAC; then
  IS_MAC_STR="true"
fi

if [ "$DO_RUN" = "true" ]; then
  lab_show_summary "$DATA_DIR" "$DEV_USER" "$DEV_PASS" "$GVM_PASSWORD" "$IS_MAC_STR"
else
  lab_log_info ""
  lab_log_info "✅ Build phase complete. Images tagged under ${LAB_IMAGE_PREFIX}/<component>:latest"
fi
