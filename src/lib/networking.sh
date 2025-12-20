#!/usr/bin/env bash

# LAN networking using macvlan for dual network mode
# Containers can be on both labnet (bridge) and labnet-lan (macvlan)

LAB_LAN_NETWORK_NAME="labnet-lan"
LAB_LAN_INTERFACE="${LAB_LAN_INTERFACE:-}"
LAB_LAN_MODE="${LAB_LAN_MODE:-0}"

lab_lan_validate_interface() {
  local interface="$1"
  if [ -z "$interface" ]; then
    lab_log_error "No network interface specified. Use --lan-interface <interface>"
    return 1
  fi

  # Check if interface exists
  if ! ip link show "$interface" >/dev/null 2>&1; then
    lab_log_error "Network interface '$interface' not found."
    lab_log_info "Available interfaces:"
    ip -brief link show | awk '{print "  - " $1}' | tee -a "$LAB_LOG_FILE"
    return 1
  fi

  return 0
}

lab_lan_network_exists() {
  podman network exists "$LAB_LAN_NETWORK_NAME" >/dev/null 2>&1
}

lab_lan_create_network() {
  local interface="$1"

  if ! lab_lan_validate_interface "$interface"; then
    return 1
  fi

  if lab_lan_network_exists; then
    lab_log_debug "LAN network '$LAB_LAN_NETWORK_NAME' already exists."
    return 0
  fi

  # Check if running on macOS
  if [[ "$(uname -s)" == "Darwin" ]]; then
    lab_log_warn "⚠️  macOS Detected: Macvlan networking has limitations on macOS."
    lab_log_warn "Podman runs in a VM, which may prevent direct access to physical network interfaces."
    lab_log_warn ""
    lab_log_warn "Recommended alternatives for macOS:"
    lab_log_warn "  1. Use port forwarding: podman run -p 8000:8000 ..."
    lab_log_warn "  2. Access containers via Mac's IP address from LAN"
    lab_log_warn "  3. For advanced use, configure Podman VM networking manually"
    lab_log_warn ""
    lab_log_info "Attempting to create macvlan network anyway..."
  fi

  lab_log_info "Creating macvlan network '$LAB_LAN_NETWORK_NAME' on interface $interface..."

  if ! podman network create \
    --driver macvlan \
    --opt parent="$interface" \
    "$LAB_LAN_NETWORK_NAME" >>"$LAB_LOG_FILE" 2>&1; then
    lab_log_error "Failed to create macvlan network. Check $LAB_LOG_FILE for details."
    if [[ "$(uname -s)" == "Darwin" ]]; then
      lab_log_error ""
      lab_log_error "This is expected on macOS due to Podman VM limitations."
      lab_log_error "Use port forwarding instead: -p <host-port>:<container-port>"
    fi
    return 1
  fi

  lab_log_info "✔ LAN network created: $LAB_LAN_NETWORK_NAME"
  return 0
}

lab_lan_remove_network() {
  if ! lab_lan_network_exists; then
    lab_log_debug "LAN network '$LAB_LAN_NETWORK_NAME' does not exist."
    return 0
  fi

  lab_log_info "Removing LAN network '$LAB_LAN_NETWORK_NAME'..."

  if ! podman network rm "$LAB_LAN_NETWORK_NAME" >>"$LAB_LOG_FILE" 2>&1; then
    lab_log_error "Failed to remove LAN network. Check $LAB_LOG_FILE for details."
    return 1
  fi

  lab_log_info "✔ LAN network removed: $LAB_LAN_NETWORK_NAME"
  return 0
}

lab_lan_container_connected() {
  local container="$1"

  if ! podman container exists "$container" >/dev/null 2>&1; then
    return 1
  fi

  podman inspect "$container" --format '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' 2>/dev/null | \
    grep -q "$(podman network inspect "$LAB_LAN_NETWORK_NAME" --format '{{.ID}}' 2>/dev/null)"
}

lab_lan_connect_container() {
  local container="$1"
  local interface="$2"

  if ! podman container exists "$container" >/dev/null 2>&1; then
    lab_log_error "Container '$container' does not exist."
    return 1
  fi

  if ! lab_lan_network_exists; then
    lab_log_info "Creating LAN network first..."
    if ! lab_lan_create_network "$interface"; then
      return 1
    fi
  fi

  if lab_lan_container_connected "$container"; then
    lab_log_debug "Container '$container' already connected to LAN."
    return 0
  fi

  lab_log_info "Connecting container '$container' to LAN network..."

  if ! podman network connect "$LAB_LAN_NETWORK_NAME" "$container" >>"$LAB_LOG_FILE" 2>&1; then
    lab_log_error "Failed to connect container to LAN. Check $LAB_LOG_FILE for details."
    return 1
  fi

  lab_log_info "✔ Container '$container' connected to LAN"

  # Show IP addresses
  local lan_ip
  lan_ip=$(podman inspect "$container" \
    --format "{{range .NetworkSettings.Networks}}{{if eq .NetworkID \"$(podman network inspect "$LAB_LAN_NETWORK_NAME" --format '{{.ID}}')\"}}{{.IPAddress}}{{end}}{{end}}" 2>/dev/null)

  if [ -n "$lan_ip" ]; then
    lab_log_info "  LAN IP: $lan_ip"
  fi

  return 0
}

lab_lan_disconnect_container() {
  local container="$1"

  if ! podman container exists "$container" >/dev/null 2>&1; then
    lab_log_error "Container '$container' does not exist."
    return 1
  fi

  if ! lab_lan_container_connected "$container"; then
    lab_log_debug "Container '$container' not connected to LAN."
    return 0
  fi

  lab_log_info "Disconnecting container '$container' from LAN network..."

  if ! podman network disconnect "$LAB_LAN_NETWORK_NAME" "$container" >>"$LAB_LOG_FILE" 2>&1; then
    lab_log_error "Failed to disconnect container from LAN. Check $LAB_LOG_FILE for details."
    return 1
  fi

  lab_log_info "✔ Container '$container' disconnected from LAN"
  return 0
}

lab_lan_show_status() {
  lab_log_info ""
  lab_log_info "=== LAN Network Status ==="

  if ! lab_lan_network_exists; then
    lab_log_info "LAN network not created."
    lab_log_info ""
    lab_log_info "To create LAN network:"
    lab_log_info "  ./setup-podman-lab.sh lan-enable all --lan-interface <interface>"
    return 0
  fi

  lab_log_info "LAN Network: $LAB_LAN_NETWORK_NAME (exists)"

  # Show network details
  local parent_interface
  parent_interface=$(podman network inspect "$LAB_LAN_NETWORK_NAME" --format '{{.Options.parent}}' 2>/dev/null)
  if [ -n "$parent_interface" ]; then
    lab_log_info "Parent Interface: $parent_interface"
  fi

  lab_log_info ""
  lab_log_info "Containers on LAN:"

  local found=0
  local container
  for container in $(podman ps --format '{{.Names}}'); do
    if lab_lan_container_connected "$container"; then
      local lan_ip
      lan_ip=$(podman inspect "$container" \
        --format "{{range .NetworkSettings.Networks}}{{if eq .NetworkID \"$(podman network inspect "$LAB_LAN_NETWORK_NAME" --format '{{.ID}}')\"}}{{.IPAddress}}{{end}}{{end}}" 2>/dev/null)
      lab_log_info "  ✔ $container ($lan_ip)"
      found=1
    fi
  done

  if [ "$found" -eq 0 ]; then
    lab_log_info "  (none)"
  fi

  lab_log_info ""
  lab_log_info "To connect a container:"
  lab_log_info "  ./setup-podman-lab.sh lan-enable <container> --lan-interface <interface>"
  lab_log_info ""
  lab_log_info "To disconnect a container:"
  lab_log_info "  ./setup-podman-lab.sh lan-disable <container>"
}

lab_lan_enable_all() {
  local interface="$1"

  if ! lab_lan_validate_interface "$interface"; then
    return 1
  fi

  lab_log_info "Enabling LAN for all running containers..."

  if ! lab_lan_create_network "$interface"; then
    return 1
  fi

  local failed=0
  local container
  for container in $(podman ps --format '{{.Names}}'); do
    if ! lab_lan_container_connected "$container"; then
      if ! lab_lan_connect_container "$container" "$interface"; then
        failed=1
      fi
    fi
  done

  if [ "$failed" -eq 1 ]; then
    lab_log_warn "Some containers failed to connect to LAN."
    return 1
  fi

  lab_log_info ""
  lab_log_info "✅ All containers connected to LAN"
  return 0
}

lab_lan_disable_all() {
  lab_log_info "Disabling LAN for all containers..."

  local failed=0
  local container
  for container in $(podman ps --format '{{.Names}}'); do
    if lab_lan_container_connected "$container"; then
      if ! lab_lan_disconnect_container "$container"; then
        failed=1
      fi
    fi
  done

  if [ "$failed" -eq 1 ]; then
    lab_log_warn "Some containers failed to disconnect from LAN."
    return 1
  fi

  lab_log_info ""
  lab_log_info "✅ All containers disconnected from LAN"
  return 0
}
