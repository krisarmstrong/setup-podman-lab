#!/usr/bin/env bash

LAB_OPTIONAL_COMPONENTS=(
  fedora-dev
  go-dev
  python-dev
  c-dev
  cpp-dev
  node-dev
  rust-dev
  alpine-tools
  database-dev
  web-server
  ansible-control
  pdf-builder
  gvm-scanner
  iperf-tools
  http-server
  librenms
  librenms-db
  snmp-demo
)

LAB_COMPONENT_FILTER_ACTIVE="false"
LAB_COMPONENT_FILTER_ARRAY=()
LAB_COMPONENT_FILTER_LIST=""
LAB_COMPONENT_FILTER_STRING=""
# shellcheck disable=SC2034
LAB_SELECTED_PROFILE="all"
# shellcheck disable=SC2034
LAB_AVAILABLE_PROFILES="all,dev,net,sec,monitor"

lab_component_known() {
  local name="$1"
  local candidate
  for candidate in "${LAB_PROJECT_DIRS[@]}"; do
    if [ "$candidate" = "$name" ]; then
      return 0
    fi
  done
  return 1
}

lab_profile_exists() {
  local name="$1"
  case "$name" in
    ""|all|dev|net|sec|monitor|infra) return 0 ;;
    *) return 1 ;;
  esac
}

lab_profile_components() {
  local name="$1"
  case "$name" in
    all|"") printf '%s\n' "${LAB_PROJECT_DIRS[*]}" ;;
    dev) printf 'ubuntu-dev fedora-dev go-dev python-dev c-dev cpp-dev node-dev rust-dev alpine-tools pdf-builder' ;;
    net) printf 'nmap-tools network-capture iperf-tools http-server snmp-demo' ;;
    sec) printf 'kali-vnc gvm-scanner nmap-tools network-capture' ;;
    monitor) printf 'librenms librenms-db snmp-demo http-server' ;;
    infra) printf 'database-dev web-server ansible-control' ;;
    *) printf '' ;;
  esac
}

lab_components_parse_list() {
  local raw="$1"
  if [ -z "$raw" ]; then
    printf ''
    return
  fi

  local parsed=()
  local original_ifs="$IFS"
  IFS=','
  read -r -a parsed <<<"$raw"
  IFS="$original_ifs"

  local cleaned=()
  local item
  for item in "${parsed[@]}"; do
    item="$(printf '%s' "$item" | tr '[:upper:]' '[:lower:]')"
    item="${item//[[:space:]]/}"
    if [ -z "$item" ]; then
      continue
    fi
    if lab_component_known "$item"; then
      if [[ " ${cleaned[*]} " != *" $item "* ]]; then
        cleaned+=("$item")
      fi
    else
      lab_log_warn "Ignoring unknown component '$item' in filter list."
    fi
  done

  printf '%s\n' "${cleaned[*]}"
}

lab_components_init() {
  local profile="$1"
  local explicit="$2"

  LAB_COMPONENT_FILTER_ACTIVE="false"
  LAB_COMPONENT_FILTER_ARRAY=()
  LAB_COMPONENT_FILTER_LIST=""
  LAB_COMPONENT_FILTER_STRING=""
  LAB_SELECTED_PROFILE="all"

  local cleaned_list=""

  if [ -n "$explicit" ]; then
    cleaned_list="$(lab_components_parse_list "$explicit")"
    LAB_SELECTED_PROFILE="custom"
  else
    if [ -z "$profile" ]; then
      profile="all"
    fi
    if ! lab_profile_exists "$profile"; then
      lab_log_warn "Unknown profile '$profile'. Falling back to 'all'."
      profile="all"
    fi
    # shellcheck disable=SC2034
    LAB_SELECTED_PROFILE="$profile"
    if [ "$profile" != "all" ]; then
      cleaned_list="$(lab_profile_components "$profile")"
    fi
  fi

  if [ -n "$cleaned_list" ]; then
    read -r -a LAB_COMPONENT_FILTER_ARRAY <<<"$cleaned_list"
    if [ "${#LAB_COMPONENT_FILTER_ARRAY[@]}" -gt 0 ]; then
      LAB_COMPONENT_FILTER_ACTIVE="true"
      LAB_COMPONENT_FILTER_LIST="${LAB_COMPONENT_FILTER_ARRAY[*]}"
      local temp
      temp="${LAB_COMPONENT_FILTER_ARRAY[*]}"
      LAB_COMPONENT_FILTER_STRING="$(printf '%s' "$temp" | tr ' ' ',')"
    fi
  fi
}

lab_component_filters_active() {
  [ "$LAB_COMPONENT_FILTER_ACTIVE" = "true" ]
}

lab_component_filter_string() {
  printf '%s' "$LAB_COMPONENT_FILTER_STRING"
}

lab_component_selected() {
  local name="$1"
  if ! lab_component_filters_active; then
    return 0
  fi
  case " $LAB_COMPONENT_FILTER_LIST " in
    *" $name "*) return 0 ;;
    *) return 1 ;;
  esac
}

lab_component_is_optional() {
  local name="$1"
  local optional
  for optional in "${LAB_OPTIONAL_COMPONENTS[@]}"; do
    if [ "$optional" = "$name" ]; then
      return 0
    fi
  done
  return 1
}

__lab_component_enabled() {
  local name="$1"
  local emit_logs="$2"
  if ! lab_component_selected "$name"; then
    if [ "$emit_logs" = "true" ]; then
      lab_log_debug "Component '$name' skipped (filtered)."
    fi
    return 1
  fi
  if [ "$LIGHT" = "true" ] && lab_component_is_optional "$name" && ! lab_component_filters_active; then
    if [ "$emit_logs" = "true" ]; then
      lab_log_debug "Component '$name' skipped (light mode)."
    fi
    return 1
  fi
  return 0
}

lab_component_enabled() {
  __lab_component_enabled "$1" "true"
}

lab_component_enabled_quiet() {
  __lab_component_enabled "$1" "false"
}

lab_components_selected_profile() {
  printf '%s' "$LAB_SELECTED_PROFILE"
}
