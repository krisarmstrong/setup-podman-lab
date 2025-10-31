#!/usr/bin/env bash

# shellcheck disable=SC2034
LAB_PROJECT_DIRS=(
  kali-vnc
  pdf-builder
  ubuntu-dev
  fedora-dev
  go-dev
  python-dev
  c-dev
  node-dev
  alpine-tools
  nmap-tools
  packet-analyzer
  vulnerability-scanner
  iperf-tools
  http-test
  librenms
  librenms-db
  snmp-demo
)

# shellcheck disable=SC2034
LAB_DATA_DIRS=(
  kali-home
  pdf-out
  ubuntu-home
  fedora-home
  go-home
  python-home
  c-home
  node-home
  alpine-home
  network-out
  vulnerability-home
  iperf-out
  librenms-data
  librenms-db
)

lab_create_user_cmd() {
  local os_type="$1"
  local user_name="$2"
  local user_pass="$3"
  if [ "$os_type" = "fedora" ]; then
    printf "RUN useradd -m -s /bin/bash %s && echo '%s:%s' | chpasswd && usermod -aG wheel %s" \
      "$user_name" "$user_name" "$user_pass" "$user_name"
  else
    printf "RUN useradd -m -s /bin/bash %s && echo '%s:%s' | chpasswd && adduser %s sudo" \
      "$user_name" "$user_name" "$user_pass" "$user_name"
  fi
}

lab_write_containerfiles() {
  local projects_dir="$1"
  local dev_user="$2"
  local dev_pass="$3"

  # --- Kali Desktop (VNC) ---
  {
    printf 'FROM %s\n' "$(lab_resolve_base "$(lab_base_image_for "kali-vnc")")"
    cat <<'EOF'
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        kali-linux-headless \
        xfce4 xfce4-goodies \
        tightvncserver \
        dbus-x11 x11-xserver-utils \
        firefox-esr \
        sudo \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash kali && echo "kali:kali" | chpasswd && adduser kali sudo
USER kali
WORKDIR /home/kali
RUN mkdir -p /home/kali/.vnc && \
    echo "kali" | vncpasswd -f > /home/kali/.vnc/passwd && \
    chmod 600 /home/kali/.vnc/passwd && \
    printf '#!/bin/bash\nstartxfce4 &\n' > /home/kali/.vnc/xstartup && \
    chmod +x /home/kali/.vnc/xstartup
EXPOSE 5901
CMD ["sh", "-c", "vncserver :1 -geometry 1280x800 -depth 24 && tail -F /home/kali/.vnc/*.log"]
EOF
  } > "$projects_dir/kali-vnc/Containerfile"

  # --- PDF Generator ---
  {
    printf 'FROM %s\n' "$(lab_resolve_base "$(lab_base_image_for "pdf-builder")")"
    cat <<'EOF'
RUN pip install reportlab
WORKDIR /work
VOLUME ["/out"]
COPY floorplan_generator.py /work/floorplan_generator.py
CMD ["python", "floorplan_generator.py", "/out"]
EOF
  } > "$projects_dir/pdf-builder/Containerfile"

  cat > "$projects_dir/pdf-builder/floorplan_generator.py" <<'EOF'
from reportlab.lib.pagesizes import landscape, letter
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas
import os, sys
series = {
    "NOB": ["StandardOffice","ExecutiveWing","CallCenter","LShaped","CornerOffice","TrainingHub","MultiTenant","Collaborative","Engineering","CompactBranch"],
    "MED": ["GeneralClinic","UrgentCare","DentalClinic","PediatricOffice","ImagingCenter","SurgicalCenter","LabDiagnostics","FamilyPractice","SpecialtyClinic","Outpatient"],
    "MFG": ["General","LongBayAssembly","DualDock","HeavyFab","LightAssembly","WarehouseFirst","CleanRoom","MixedUse","Distribution","CompactWorkshop"]
}
def draw_common(c,t):
    c.setFont("Helvetica-Bold",18); c.drawString(1*inch,7.75*inch,t)
    c.setFont("Helvetica",10); c.drawString(1*inch,0.5*inch,"Scale: 1 in = 10 ft")
    c.drawString(9.3*inch,0.5*inch,"N↑")
    c.line(9.3*inch,0.55*inch,9.3*inch,0.75*inch)
def draw_layout(c,cat):
    c.setLineWidth(2)
    c.rect(1.5*inch,1*inch,8*inch,6.5*inch)
    c.setLineWidth(1)
    if cat=="NOB":
        for i in range(3):
            c.line(1.5*inch, (2+i*1.5)*inch, 9.5*inch, (2+i*1.5)*inch)
        c.drawString(1.6*inch, 7.1*inch, "Offices / Conf / Open")
    elif cat=="MED":
        for i in range(4):
            c.rect(1.5*inch,1*inch+i*1.5*inch,2.5*inch,1.5*inch)
        c.drawString(4.2*inch, 4*inch, "Exam / Nurse / Lab")
    else:
        for x in range(4):
            c.line(1.5*inch+(x*2)*inch,1*inch,1.5*inch+(x*2)*inch,7.5*inch)
        c.drawString(4*inch, 4*inch, "Production / Storage")
outdir = sys.argv[1] if len(sys.argv)>1 else "/out"
os.makedirs(outdir, exist_ok=True)
for cat, layouts in series.items():
    for name in layouts:
        filename = os.path.join(outdir, f"{cat}_{name}.pdf")
        c = canvas.Canvas(filename, pagesize=landscape(letter))
        draw_common(c, f"{cat} – {name}")
        draw_layout(c, cat)
        c.showPage()
        c.save()
        print("wrote", filename)
EOF

  # --- Dev Containers (generated) ---
  cat > "$projects_dir/ubuntu-dev/Containerfile" <<EOF
FROM $(lab_resolve_base "$(lab_base_image_for "ubuntu-dev")")
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y build-essential curl git sudo pkg-config ca-certificates && apt-get clean && rm -rf /var/lib/apt/lists/*
$(lab_create_user_cmd "ubuntu" "$dev_user" "$dev_pass")
USER $dev_user
WORKDIR /home/$dev_user
CMD ["bash"]
EOF

  cat > "$projects_dir/c-dev/Containerfile" <<EOF
FROM $(lab_resolve_base "$(lab_base_image_for "c-dev")")
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y build-essential gdb clang make cmake pkg-config git sudo && apt-get clean && rm -rf /var/lib/apt/lists/*
$(lab_create_user_cmd "ubuntu" "$dev_user" "$dev_pass")
USER $dev_user
WORKDIR /home/$dev_user
CMD ["bash"]
EOF

  cat > "$projects_dir/go-dev/Containerfile" <<EOF
FROM $(lab_resolve_base "$(lab_base_image_for "go-dev")")
$(lab_create_user_cmd "debian" "$dev_user" "$dev_pass")
USER $dev_user
WORKDIR /home/$dev_user/app
CMD ["bash"]
EOF

  cat > "$projects_dir/python-dev/Containerfile" <<EOF
FROM $(lab_resolve_base "$(lab_base_image_for "python-dev")")
$(lab_create_user_cmd "debian" "$dev_user" "$dev_pass")
USER $dev_user
WORKDIR /home/$dev_user
CMD ["bash"]
EOF

  cat > "$projects_dir/node-dev/Containerfile" <<EOF
FROM $(lab_resolve_base "$(lab_base_image_for "node-dev")")
$(lab_create_user_cmd "debian" "$dev_user" "$dev_pass")
USER $dev_user
WORKDIR /home/$dev_user/app
CMD ["bash"]
EOF

  cat > "$projects_dir/fedora-dev/Containerfile" <<EOF
FROM $(lab_resolve_base "$(lab_base_image_for "fedora-dev")")
RUN dnf -y update && dnf -y install @development-tools sudo git curl && dnf clean all
$(lab_create_user_cmd "fedora" "$dev_user" "$dev_pass")
USER $dev_user
WORKDIR /home/$dev_user
CMD ["bash"]
EOF

  cat > "$projects_dir/alpine-tools/Containerfile" <<EOF
FROM $(lab_resolve_base "$(lab_base_image_for "alpine-tools")")
RUN apk update && apk add git curl wget openssh bash sudo shadow
RUN adduser -D -s /bin/bash $dev_user && echo '$dev_user:$dev_pass' | chpasswd && usermod -aG wheel $dev_user
USER $dev_user
WORKDIR /home/$dev_user
CMD ["bash"]
EOF

  # --- Networking / Security Containers ---
  {
    printf 'FROM %s\n' "$(lab_resolve_base "$(lab_base_image_for "nmap-tools")")"
    cat <<'EOF'

RUN apt-get update \
  && apt-get install -y --no-install-recommends nmap ca-certificates \
  && rm -rf /var/lib/apt/lists/*

USER root
WORKDIR /
CMD ["nmap"]
EOF
  } > "$projects_dir/nmap-tools/Containerfile"

  cat > "$projects_dir/packet-analyzer/Containerfile" <<EOF
FROM $(lab_resolve_base "$(lab_base_image_for "packet-analyzer")")
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y tshark sudo && apt-get clean && rm -rf /var/lib/apt/lists/*
$(lab_create_user_cmd "ubuntu" "$dev_user" "$dev_pass")
USER $dev_user
WORKDIR /home/$dev_user/captures
CMD ["bash"]
EOF

  {
    printf 'FROM %s\n' "$(lab_resolve_base "$(lab_base_image_for "vulnerability-scanner")")"
    cat <<'EOF'
EXPOSE 443
EOF
  } > "$projects_dir/vulnerability-scanner/Containerfile"

  cat > "$projects_dir/iperf-tools/Containerfile" <<EOF
FROM $(lab_resolve_base "$(lab_base_image_for "iperf-tools")")
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y iperf iperf3 net-tools curl && apt-get clean && rm -rf /var/lib/apt/lists/*
$(lab_create_user_cmd "ubuntu" "$dev_user" "$dev_pass")
USER $dev_user
WORKDIR /home/$dev_user
CMD ["bash"]
EOF

  {
    printf 'FROM %s\n' "$(lab_resolve_base "$(lab_base_image_for "http-test")")"
    cat <<'EOF'
WORKDIR /srv
RUN mkdir -p /srv/www && echo 'OK' > /srv/www/index.html
EXPOSE 8000
CMD ["python", "-m", "http.server", "8000", "--directory", "/srv/www"]
EOF
  } > "$projects_dir/http-test/Containerfile"

  {
    printf 'FROM %s\n' "$(lab_resolve_base "$(lab_base_image_for "snmp-demo")")"
    cat <<'EOF'
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y snmpd && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN printf "agentAddress udp:0.0.0.0:161\nrocommunity public 0.0.0.0/0\nsysLocation Podman-Lab\nsysContact lab-admin@example.com\n" > /etc/snmp/snmpd.conf
EXPOSE 161/udp
CMD ["snmpd", "-f", "-Lo"]
EOF
  } > "$projects_dir/snmp-demo/Containerfile"

  # --- LibreNMS DB (MariaDB) ---
  {
    printf 'FROM %s\n' "$(lab_resolve_base "$(lab_base_image_for "librenms-db")")"
    cat <<'EOF'
ENV MARIADB_ROOT_PASSWORD=librenmsroot
ENV MARIADB_DATABASE=librenms
ENV MARIADB_USER=librenms
ENV MARIADB_PASSWORD=librenmspass
VOLUME ["/var/lib/mysql"]
EXPOSE 3306
EOF
  } > "$projects_dir/librenms-db/Containerfile"

  # --- LibreNMS App ---
  {
    printf 'FROM %s\n' "$(lab_resolve_base "$(lab_base_image_for "librenms")")"
    cat <<'EOF'
ENV DB_HOST=librenms-db
ENV DB_NAME=librenms
ENV DB_USER=librenms
ENV DB_PASSWORD=librenmspass
ENV DB_TIMEOUT=60
ENV APP_URL=http://localhost:8001
ENV BASE_DIR=/data
VOLUME ["/data"]
EXPOSE 8000
CMD ["/init"]
EOF
  } > "$projects_dir/librenms/Containerfile"
}
lab_base_image_for() {
  case "$1" in
    kali-vnc) printf 'kalilinux/kali-rolling' ;;
    pdf-builder) printf 'python:3.12-slim' ;;
    ubuntu-dev) printf 'ubuntu:latest' ;;
    fedora-dev) printf 'fedora:latest' ;;
    go-dev) printf 'golang:latest' ;;
    python-dev) printf 'python:latest' ;;
    node-dev) printf 'node:latest' ;;
    c-dev) printf 'ubuntu:latest' ;;
    alpine-tools) printf 'alpine:latest' ;;
    nmap-tools) printf 'debian:bookworm-slim' ;;
    packet-analyzer) printf 'ubuntu:latest' ;;
    vulnerability-scanner) printf 'mikesplain/openvas:latest' ;;
    iperf-tools) printf 'ubuntu:latest' ;;
    http-test) printf 'python:3.12-slim' ;;
    librenms) printf 'librenms/librenms:latest' ;;
    librenms-db) printf 'mariadb:11' ;;
    snmp-demo) printf 'debian:stable-slim' ;;
    *) printf '' ;;
  esac
}

lab_resolve_base() {
  local image="$1"
  local mirror="${LAB_REGISTRY_MIRROR:-}"
  if [ -z "$mirror" ]; then
    printf '%s' "$image"
    return
  fi

  local prefix=""
  local remainder="$image"
  local has_host=0

  if [[ "$image" == */* ]]; then
    prefix="${image%%/*}"
    remainder="${image#*/}"
    if [[ "$prefix" == *.* || "$prefix" == *:* || "$prefix" == "localhost" ]]; then
      has_host=1
    fi
  else
    prefix=""
    remainder="$image"
  fi

  if [ $has_host -eq 1 ]; then
    printf '%s' "$image"
    return
  fi

  if [ -n "$prefix" ]; then
    printf '%s/%s/%s' "${mirror%/}" "$prefix" "$remainder"
  else
    printf '%s/library/%s' "${mirror%/}" "$remainder"
  fi
}
