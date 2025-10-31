#!/usr/bin/env bash

LAB_OPTIONAL_COMPONENTS=(
  fedora-dev
  go-dev
  python-dev
  c-dev
  node-dev
  alpine-tools
)

LAB_COMPONENT_FILTER_ACTIVE="false"
LAB_COMPONENT_FILTER_ARRAY=()
LAB_COMPONENT_FILTER_LIST=""
LAB_COMPONENT_FILTER_STRING=""

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

lab_components_init() {
  local raw="$1"
  LAB_COMPONENT_FILTER_ACTIVE="false"
  LAB_COMPONENT_FILTER_ARRAY=()
  LAB_COMPONENT_FILTER_LIST=""
  LAB_COMPONENT_FILTER_STRING=""

  if [ -z "$raw" ]; then
    return
  fi

  local original_ifs="$IFS"
  IFS=','
  read -r -a LAB_COMPONENT_FILTER_ARRAY <<<"$raw"
  IFS="$original_ifs"

  local cleaned=()
  local item
  for item in "${LAB_COMPONENT_FILTER_ARRAY[@]}"; do
    item="$(printf '%s' "$item" | tr '[:upper:]' '[:lower:]')"
    item="${item//[[:space:]]/}"
    if [ -z "$item" ]; then
      continue
    fi
    if lab_component_known "$item"; then
      cleaned+=("$item")
    else
      lab_log_warn "Ignoring unknown component '$item' in filter list."
    fi
  done

  if [ "${#cleaned[@]}" -gt 0 ]; then
    LAB_COMPONENT_FILTER_ACTIVE="true"
    LAB_COMPONENT_FILTER_ARRAY=("${cleaned[@]}")
    LAB_COMPONENT_FILTER_LIST="${LAB_COMPONENT_FILTER_ARRAY[*]}"
    local temp
    temp="${LAB_COMPONENT_FILTER_ARRAY[*]}"
    LAB_COMPONENT_FILTER_STRING="$(printf '%s' "$temp" | tr ' ' ',')"
  else
    LAB_COMPONENT_FILTER_ARRAY=()
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
