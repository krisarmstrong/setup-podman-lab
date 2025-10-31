#!/usr/bin/env bash

# Initializes logging configuration. Arguments:
#   $1 - lab root directory (used for default log dir)
#   $2 - verbose flag (0/1)
#   $3 - explicit log dir (optional)
#   $4 - explicit log file path (optional)
# Sets globals: LAB_VERBOSE, LAB_LOG_DIR, LAB_LOG_FILE.
lab_init_logging() {
  local lab_root="$1"
  local verbose="${2:-0}"
  local log_dir="$3"
  local log_file="$4"

  LAB_VERBOSE="$verbose"
  if [ -z "$log_dir" ]; then
    log_dir="$lab_root/logs"
  fi
  LAB_LOG_DIR="$log_dir"

  if [ -z "$log_file" ]; then
    log_file="$LAB_LOG_DIR/setup-podman-lab-$(date +%Y%m%d-%H%M%S).log"
  fi
  LAB_LOG_FILE="$log_file"

  mkdir -p "$LAB_LOG_DIR"
  touch "$LAB_LOG_FILE"
}

lab_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

lab_log_msg() {
  local level="$1"
  shift
  local msg="$*"
  local ts
  ts="$(lab_timestamp)"
  printf '[%s] [%s] %s\n' "$ts" "$level" "$msg" >>"$LAB_LOG_FILE"
  case "$level" in
    DEBUG)
      if [ "$LAB_VERBOSE" = "1" ]; then
        echo "$msg"
      fi
      ;;
    *)
      echo "$msg"
      ;;
  esac
}

lab_log_info()  { lab_log_msg INFO "$@"; }
lab_log_warn()  { lab_log_msg WARN "$@"; }
lab_log_error() { lab_log_msg ERROR "$@"; }
lab_log_debug() { lab_log_msg DEBUG "$@"; }

# Runs a command while routing detailed output to the log file.
# Arguments:
#   $1 - description for logs
#   $2+ - command to execute
lab_run_logged() {
  local desc="$1"
  shift
  lab_log_info "$desc"
  lab_log_debug "Running: $*"
  local status
  if [ "$LAB_VERBOSE" = "1" ]; then
    set +e
    "$@" 2>&1 | tee -a "$LAB_LOG_FILE"
    status=${PIPESTATUS[0]}
    set -e
  else
    set +e
    "$@" >>"$LAB_LOG_FILE" 2>&1
    status=$?
    set -e
  fi
  if [ "$status" -ne 0 ]; then
    lab_log_error "$desc failed (exit $status). See $LAB_LOG_FILE for details."
    exit "$status"
  fi
}
