#!/usr/bin/env bash

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

lab_build_images() {
  local projects_dir="$1"
  local pull_policy="$2"
  local img_dir img
  for img_dir in "$projects_dir"/*; do
    [ -d "$img_dir" ] || continue
    if [ -f "$img_dir/Containerfile" ]; then
      img=$(basename "$img_dir" | tr '[:upper:]' '[:lower:]')
      lab_run_logged "--> Building image: $img" podman build --pull="$pull_policy" -t "$img" "$img_dir"
    else
      lab_log_warn "    Skipping $(basename "$img_dir"): no Containerfile found."
    fi
  done
}

lab_start_containers() {
  local data_dir="$1"
  local dev_user="$2"
  local light_flag="$3"
  local gvm_password="$4"

  # General Utilities
  lab_ensure_container_absent "kali-vnc"
  lab_run_logged "Starting kali-vnc container" \
    podman run -d --name kali-vnc -p 5901:5901 -v "$data_dir/kali-home:/home/kali" kali-vnc
  lab_run_logged "Generating initial floor plan PDFs" \
    podman run --rm -v "$data_dir/pdf-out:/out" pdf-builder

  # Dev Containers
  lab_ensure_container_absent "ubuntu-dev"
  lab_run_logged "Starting ubuntu-dev container" \
    podman run -d --name ubuntu-dev -v "$data_dir/ubuntu-home:/home/$dev_user" ubuntu-dev

  if [ "$light_flag" != "true" ]; then
    lab_ensure_container_absent "fedora-dev"
    lab_run_logged "Starting fedora-dev container" \
      podman run -d --name fedora-dev -v "$data_dir/fedora-home:/home/$dev_user" fedora-dev

    lab_ensure_container_absent "go-dev"
    lab_run_logged "Starting go-dev container" \
      podman run -d --name go-dev -v "$data_dir/go-home:/home/$dev_user/app" go-dev

    lab_ensure_container_absent "python-dev"
    lab_run_logged "Starting python-dev container" \
      podman run -d --name python-dev -v "$data_dir/python-home:/home/$dev_user" python-dev

    lab_ensure_container_absent "c-dev"
    lab_run_logged "Starting c-dev container" \
      podman run -d --name c-dev -v "$data_dir/c-home:/home/$dev_user" c-dev

    lab_ensure_container_absent "node-dev"
    lab_run_logged "Starting node-dev container" \
      podman run -d --name node-dev -v "$data_dir/node-home:/home/$dev_user/app" node-dev

    lab_ensure_container_absent "alpine-tools"
    lab_run_logged "Starting alpine-tools container" \
      podman run -d --name alpine-tools -v "$data_dir/alpine-home:/home/$dev_user" alpine-tools
  fi

  # Networking / Security
  lab_ensure_container_absent "nmap-tools"
  lab_run_logged "Starting nmap-tools container" podman run -d --name nmap-tools nmap-tools

  lab_ensure_container_absent "packet-analyzer"
  lab_run_logged "Starting packet-analyzer container" \
    podman run -d --name packet-analyzer \
      --net=host \
      --cap-add=NET_ADMIN --cap-add=NET_RAW \
      -v "$data_dir/network-out:/home/$dev_user/captures" \
      packet-analyzer

  lab_ensure_container_absent "iperf-tools"
  lab_run_logged "Starting iperf-tools container" \
    podman run -d --name iperf-tools \
      -v "$data_dir/iperf-out:/home/$dev_user" \
      iperf-tools

  lab_ensure_container_absent "vulnerability-scanner"
  lab_run_logged "Starting vulnerability-scanner container" \
    podman run -d --name vulnerability-scanner \
      -p 4000:443 \
      -e PASSWORD="$gvm_password" \
      -v "$data_dir/vulnerability-home:/var/lib/openvas" \
      vulnerability-scanner

  lab_ensure_container_absent "http-test"
  lab_run_logged "Starting http-test container" podman run -d --name http-test -p 8000:8000 http-test

  # LibreNMS stack
  lab_ensure_container_absent "librenms-db"
  lab_run_logged "Starting librenms-db (MariaDB) container" \
    podman run -d --name librenms-db \
      --network labnet \
      -v "$data_dir/librenms-db:/var/lib/mysql" \
      librenms-db

  lab_ensure_container_absent "librenms"
  lab_run_logged "Starting librenms application container" \
    podman run -d --name librenms \
      --network labnet \
      -p 8001:8000 \
      -v "$data_dir/librenms-data:/data" \
      librenms

  # SNMP demo
  lab_ensure_container_absent "snmp-demo"
  lab_run_logged "Starting snmp-demo container" \
    podman run -d --name snmp-demo \
      --network labnet \
      snmp-demo
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
  lab_log_info ""
  lab_log_info "🖥️ Kali Desktop (VNC):"
  lab_log_info "  Connect to: localhost:5901"
  lab_log_info "  User: kali   Pass: kali"
  lab_log_info "  VNC password: kali"
  lab_log_info ""
  lab_log_info "📄 Floor plan PDFs:"
  lab_log_info "  $data_dir/pdf-out/"
  lab_log_info ""
  lab_log_info "💻 Dev Containers:"
  lab_log_info "  podman exec -it ubuntu-dev bash"
  lab_log_info "  podman exec -it fedora-dev bash"
  lab_log_info "  podman exec -it go-dev bash"
  lab_log_info "  podman exec -it python-dev bash"
  lab_log_info "  podman exec -it c-dev bash"
  lab_log_info "  podman exec -it node-dev bash"
  lab_log_info "  podman exec -it alpine-tools bash"
  lab_log_info ""
  lab_log_info "🌐 Net/Sec:"
  lab_log_info "  podman exec -it nmap-tools nmap -v <target>"
  lab_log_info "  podman exec -it packet-analyzer bash   # sudo tshark -i eth0"
  lab_log_info "  podman exec -it iperf-tools bash       # iperf3 -s / -c"
  lab_log_info "  GVM: https://localhost:4000  (maps to container port 443; default login admin / $gvm_password)"
  lab_log_info ""
  lab_log_info "🧪 HTTP Test:"
  lab_log_info "  http://localhost:8000  -> 'OK'"
  lab_log_info ""
  lab_log_info "📡 LibreNMS:"
  lab_log_info "  http://localhost:8001"
  lab_log_info "  DB: mariadb on container 'librenms-db' (network: labnet)"
  lab_log_info "  Note: first run may take 1–2 minutes to finish migrations."
  lab_log_info ""
  lab_log_info "  NOTE: on macOS/Podman this captures from the VM, not your Mac's Wi-Fi."

  if [ "$is_mac" = "true" ]; then
    local sock
    sock=$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')
    lab_log_info "🐳 Docker-compatible socket (macOS):"
    lab_log_info "  export DOCKER_HOST='unix://$sock'"
    lab_log_info "  # Add that to ~/.zshrc if you want it permanent"
  fi
}
