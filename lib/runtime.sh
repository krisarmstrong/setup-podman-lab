#!/usr/bin/env bash

lab_image_name() {
  local dir_name="$1"
  local safe_name
  safe_name="$(printf '%s' "$dir_name" | tr '[:upper:]' '[:lower:]')"
  printf '%s/%s:latest' "$LAB_IMAGE_PREFIX" "$safe_name"
}

lab_setup_directories() {
  local lab_root="$1"
  local projects_dir="$2"
  local data_dir="$3"
  lab_log_info "Using lab root: $lab_root"

  local dir
  for dir in "${LAB_PROJECT_DIRS[@]}"; do
    mkdir -p "$projects_dir/$dir"
  done
  for dir in "${LAB_DATA_DIRS[@]}"; do
    mkdir -p "$data_dir/$dir"
  done
}

lab_ensure_container_absent() {
  local name="$1"
  if podman container exists "$name" >/dev/null 2>&1; then
    lab_run_logged "Removing existing container $name" podman rm -f "$name"
  fi
}

lab_create_labnet_network() {
  if ! podman network exists labnet >/dev/null 2>&1; then
    lab_run_logged "Creating podman network 'labnet'" podman network create labnet
  else
    lab_log_debug "podman network 'labnet' already present."
  fi
}

lab_verify_base_images() {
  local missing=()
  local component
  for component in "${LAB_PROJECT_DIRS[@]}"; do
    if ! lab_component_enabled_quiet "$component"; then
      continue
    fi
    local base_image raw_image
    raw_image="$(lab_base_image_for "$component")"
    if [ -z "$raw_image" ]; then
      continue
    fi
    base_image="$(lab_resolve_base "$raw_image")"
    if ! podman image exists "$base_image" >/dev/null 2>&1; then
      missing+=("$base_image")
    fi
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    lab_log_error "Offline mode requested but required base images are missing:"
    local img
    for img in "${missing[@]}"; do
      lab_log_error "  - $img"
    done
    lab_log_error "Import or pre-pull the images above (podman pull …) or disable LAB_OFFLINE_MODE."
    exit 1
  fi
}

lab_start_container_if_enabled() {
  local name="$1"
  local description="$2"
  shift 2
  if lab_component_enabled "$name"; then
    lab_ensure_container_absent "$name"
    lab_run_logged "Starting $description" podman run -d --name "$name" "$@"
  else
    lab_log_debug "Skipping '$name' (disabled)."
  fi
}

lab_run_job_if_enabled() {
  local name="$1"
  local description="$2"
  shift 2
  if lab_component_enabled "$name"; then
    lab_run_logged "Running $description" podman run "$@"
  else
    lab_log_debug "Skipping '$name' job (disabled)."
  fi
}

lab_build_images() {
  local projects_dir="$1"
  local pull_policy="$2"
  local concurrency="${LAB_BUILD_CONCURRENCY:-2}"
  if ! [[ "$concurrency" =~ ^[0-9]+$ ]] || [ "$concurrency" -lt 1 ]; then
    concurrency=1
  fi

  local queue=()
  local img_dir
  for img_dir in "$projects_dir"/*; do
    [ -d "$img_dir" ] || continue
    if [ ! -f "$img_dir/Containerfile" ]; then
      lab_log_warn "    Skipping $(basename "$img_dir"): no Containerfile found."
      continue
    fi
    local base
    base=$(basename "$img_dir")
    if ! lab_component_enabled "$base"; then
      continue
    fi
    queue+=("$img_dir")
  done

  if [ "${#queue[@]}" -eq 0 ]; then
    lab_log_info "No images selected for build."
    return
  fi

  if [ "$concurrency" -le 1 ] || [ "${#queue[@]}" -eq 1 ]; then
    local dir
    for dir in "${queue[@]}"; do
      local tag
      tag="$(lab_image_name "$(basename "$dir")")"
      lab_run_logged "--> Building image: $tag" podman build --pull="$pull_policy" -t "$tag" "$dir"
    done
    return
  fi

  lab_log_info "Building images with concurrency=$concurrency ..."
  local -a pid_queue=()
  local -a tag_queue=()
  local active=0
  local idx=0
  while [ "$idx" -lt "${#queue[@]}" ]; do
    while [ "$idx" -lt "${#queue[@]}" ] && [ "$active" -lt "$concurrency" ]; do
      local dir="${queue[$idx]}"
      idx=$((idx + 1))
      local base
      base=$(basename "$dir")
      local tag
      tag="$(lab_image_name "$base")"
      (
        podman build --pull="$pull_policy" -t "$tag" "$dir"
      ) >>"$LAB_LOG_FILE" 2>&1 &
      local pid=$!
      pid_queue+=("$pid")
      tag_queue+=("$tag")
      active=${#pid_queue[@]}
      lab_log_info "--> Building image (async): $tag [pid $pid]"
    done

    if [ "${#pid_queue[@]}" -ge "$concurrency" ]; then
      local pid="${pid_queue[0]}"
      local tag="${tag_queue[0]}"
      wait "$pid"
      local status=$?
      if [ "${#pid_queue[@]}" -gt 1 ]; then
        pid_queue=("${pid_queue[@]:1}")
        tag_queue=("${tag_queue[@]:1}")
      else
        pid_queue=()
        tag_queue=()
      fi
      active=${#pid_queue[@]}
      if [ $status -ne 0 ]; then
        lab_log_error "Image build failed for $tag (exit $status). See $LAB_LOG_FILE."
        for pid in "${pid_queue[@]}"; do
          wait "$pid" >/dev/null 2>&1 || true
        done
        exit $status
      else
        lab_log_info "✔ Image build completed: $tag"
      fi
    fi
  done

  local idx_final
  for idx_final in "${!pid_queue[@]}"; do
    local pid="${pid_queue[$idx_final]}"
    local tag="${tag_queue[$idx_final]}"
    wait "$pid"
    local status=$?
    if [ $status -ne 0 ]; then
      lab_log_error "Image build failed for $tag (exit $status). See $LAB_LOG_FILE."
      exit $status
    else
      lab_log_info "✔ Image build completed: $tag"
    fi
  done
}

lab_start_containers() {
  local data_dir="$1"
  local dev_user="$2"
  local gvm_password="$3"

  # General Utilities
  lab_start_container_if_enabled "kali-vnc" "kali-vnc container" \
    -p 5901:5901 -v "$data_dir/kali-home:/home/kali" "$(lab_image_name "kali-vnc")"

  lab_run_job_if_enabled "pdf-builder" "pdf-builder job" \
    --rm -v "$data_dir/pdf-out:/out" "$(lab_image_name "pdf-builder")"

  # Dev Containers
  lab_start_container_if_enabled "ubuntu-dev" "ubuntu-dev container" \
    -v "$data_dir/ubuntu-home:/home/$dev_user" "$(lab_image_name "ubuntu-dev")"

  lab_start_container_if_enabled "fedora-dev" "fedora-dev container" \
    -v "$data_dir/fedora-home:/home/$dev_user" "$(lab_image_name "fedora-dev")"

  lab_start_container_if_enabled "go-dev" "go-dev container" \
    -v "$data_dir/go-home:/home/$dev_user/app" "$(lab_image_name "go-dev")"

  lab_start_container_if_enabled "python-dev" "python-dev container" \
    -v "$data_dir/python-home:/home/$dev_user" "$(lab_image_name "python-dev")"

  lab_start_container_if_enabled "c-dev" "c-dev container" \
    -v "$data_dir/c-home:/home/$dev_user" "$(lab_image_name "c-dev")"

  lab_start_container_if_enabled "node-dev" "node-dev container" \
    -v "$data_dir/node-home:/home/$dev_user/app" "$(lab_image_name "node-dev")"

  lab_start_container_if_enabled "alpine-tools" "alpine-tools container" \
    -v "$data_dir/alpine-home:/home/$dev_user" "$(lab_image_name "alpine-tools")"

  # Networking / Security
  lab_start_container_if_enabled "nmap-tools" "nmap-tools container" \
    "$(lab_image_name "nmap-tools")"

  lab_start_container_if_enabled "packet-analyzer" "packet-analyzer container" \
    --net=host \
    --cap-add=NET_ADMIN --cap-add=NET_RAW \
    -v "$data_dir/network-out:/home/$dev_user/captures" \
    "$(lab_image_name "packet-analyzer")"

  lab_start_container_if_enabled "iperf-tools" "iperf-tools container" \
    -v "$data_dir/iperf-out:/home/$dev_user" \
    "$(lab_image_name "iperf-tools")"

  lab_start_container_if_enabled "vulnerability-scanner" "vulnerability-scanner container" \
    -p 4000:443 \
    -e PASSWORD="$gvm_password" \
    -v "$data_dir/vulnerability-home:/var/lib/openvas" \
    "$(lab_image_name "vulnerability-scanner")"

  lab_start_container_if_enabled "http-test" "http-test container" \
    -p 8000:8000 "$(lab_image_name "http-test")"

  # LibreNMS stack
  lab_start_container_if_enabled "librenms-db" "librenms-db (MariaDB) container" \
    --network labnet \
    -v "$data_dir/librenms-db:/var/lib/mysql" \
    "$(lab_image_name "librenms-db")"

  lab_start_container_if_enabled "librenms" "librenms application container" \
    --network labnet \
    -p 8001:8000 \
    -v "$data_dir/librenms-data:/data" \
    "$(lab_image_name "librenms")"

  # SNMP demo
  lab_start_container_if_enabled "snmp-demo" "snmp-demo container" \
    --network labnet \
    "$(lab_image_name "snmp-demo")"
}

lab_show_summary() {
  local data_dir="$1"
  local dev_user="$2"
  local dev_pass="$3"
  local gvm_password="$4"
  local is_mac="$5"

  lab_log_info ""
  lab_log_info "✅ Setup complete! To clean up, run: $0 teardown"
  lab_log_info "Running containers:"
  podman ps --format 'table {{.Names}}\t{{.Ports}}\t{{.Status}}' | tee -a "$LAB_LOG_FILE"

  lab_log_info ""
  lab_log_info "### Access Information ###"
  lab_log_info "Common Dev User/Pass: $dev_user / $dev_pass"

  if lab_component_enabled_quiet "kali-vnc"; then
    lab_log_info ""
    lab_log_info "🖥️ Kali Desktop (VNC):"
    lab_log_info "  Connect to: localhost:5901"
    lab_log_info "  User: kali   Pass: kali"
    lab_log_info "  VNC password: kali"
  fi

  if lab_component_enabled_quiet "pdf-builder"; then
    lab_log_info ""
    lab_log_info "📄 Floor plan PDFs:"
    lab_log_info "  $data_dir/pdf-out/"
  fi

  local dev_commands=()
  if lab_component_enabled_quiet "ubuntu-dev"; then dev_commands+=("podman exec -it ubuntu-dev bash"); fi
  if lab_component_enabled_quiet "fedora-dev"; then dev_commands+=("podman exec -it fedora-dev bash"); fi
  if lab_component_enabled_quiet "go-dev"; then dev_commands+=("podman exec -it go-dev bash"); fi
  if lab_component_enabled_quiet "python-dev"; then dev_commands+=("podman exec -it python-dev bash"); fi
  if lab_component_enabled_quiet "c-dev"; then dev_commands+=("podman exec -it c-dev bash"); fi
  if lab_component_enabled_quiet "node-dev"; then dev_commands+=("podman exec -it node-dev bash"); fi
  if lab_component_enabled_quiet "alpine-tools"; then dev_commands+=("podman exec -it alpine-tools bash"); fi
  if [ "${#dev_commands[@]}" -gt 0 ]; then
    lab_log_info ""
    lab_log_info "💻 Dev Containers:"
    local cmd
    for cmd in "${dev_commands[@]}"; do
      lab_log_info "  $cmd"
    done
  fi

  local net_lines=()
  if lab_component_enabled_quiet "nmap-tools"; then net_lines+=("podman exec -it nmap-tools nmap -v <target>"); fi
  if lab_component_enabled_quiet "packet-analyzer"; then net_lines+=("podman exec -it packet-analyzer bash   # sudo tshark -i eth0"); fi
  if lab_component_enabled_quiet "iperf-tools"; then net_lines+=("podman exec -it iperf-tools bash       # iperf3 -s / -c"); fi
  if lab_component_enabled_quiet "vulnerability-scanner"; then net_lines+=("GVM: https://localhost:4000  (maps to container port 443; default login admin / $gvm_password)"); fi
  if [ "${#net_lines[@]}" -gt 0 ]; then
    lab_log_info ""
    lab_log_info "🌐 Net/Sec:"
    local line
    for line in "${net_lines[@]}"; do
      lab_log_info "  $line"
    done
  fi

  if lab_component_enabled_quiet "http-test"; then
    lab_log_info ""
    lab_log_info "🧪 HTTP Test:"
    lab_log_info "  http://localhost:8000  -> 'OK'"
  fi

  if lab_component_enabled_quiet "librenms" || lab_component_enabled_quiet "librenms-db"; then
    lab_log_info ""
    lab_log_info "📡 LibreNMS:"
    if lab_component_enabled_quiet "librenms"; then
      lab_log_info "  http://localhost:8001"
    fi
    if lab_component_enabled_quiet "librenms-db"; then
      lab_log_info "  DB: mariadb on container 'librenms-db' (network: labnet)"
    fi
    lab_log_info "  Note: first run may take 1–2 minutes to finish migrations."
  fi

  if lab_component_enabled_quiet "packet-analyzer"; then
    lab_log_info ""
    lab_log_info "  NOTE: on macOS/Podman this captures from the VM, not your Mac's Wi-Fi."
  fi

  if [ "$is_mac" = "true" ]; then
    local sock
    sock=$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')
    lab_log_info "🐳 Docker-compatible socket (macOS):"
    lab_log_info "  export DOCKER_HOST='unix://$sock'"
    lab_log_info "  # Add that to ~/.zshrc if you want it permanent"
  fi
}
