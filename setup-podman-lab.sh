#!/usr/bin/env bash
set -e

# ------------------------------------------------------------
# Podman Lab Bootstrap (Mac / Linux)
# ------------------------------------------------------------
# - installs podman if missing
# - creates clean host folders
# - (re)creates podman machine, rootful
# - writes all Containerfiles
# - builds everything
# - runs core lab containers
# - includes NMS (LibreNMS + MariaDB)
# - includes teardown mode
# ------------------------------------------------------------

DEV_USER="dev"
DEV_PASS="dev"   # TODO: change this for real use!

LAB_ROOT="${PODMAN_LAB_ROOT:-$HOME}"
PROJECTS_DIR="$LAB_ROOT/PodmanProjects"
DATA_DIR="$LAB_ROOT/PodmanData"

# ---------------------------
# TEARDOWN MODE
# ---------------------------
if [ "$1" = "teardown" ]; then
  echo "==> ❌ TEARDOWN MODE: Removing all containers, images, and folders."

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

  echo "==> Cleanup complete. Folders $PROJECTS_DIR and $DATA_DIR removed."
  exit 0
fi

UNAME_OUT="$(uname -s)"
IS_MAC=false
IS_LINUX=false
if [ "$UNAME_OUT" = "Darwin" ]; then IS_MAC=true; fi
if [ "$UNAME_OUT" = "Linux" ]; then IS_LINUX=true; fi

TOTAL_STEPS=7
if $IS_MAC; then
  TOTAL_STEPS=$((TOTAL_STEPS + 1))
fi

STEP=0
step() {
  STEP=$((STEP + 1))
  echo "==> [$STEP/$TOTAL_STEPS] $1"
}

PLATFORM="unknown"
if $IS_MAC; then
  PLATFORM="macOS"
elif $IS_LINUX; then
  PLATFORM="Linux"
fi

step "Detecting platform..."
echo "Detected $PLATFORM"

LIGHT=false
if [ "$1" = "light" ]; then
  LIGHT=true
  echo "==> Running in **LIGHT** mode (Dev Containers minimized)."
fi

#######################################
# Install Podman if missing
#######################################
step "Verifying Podman installation..."
if ! command -v podman >/dev/null 2>&1; then
  echo "==> Podman not found, installing..."
  if $IS_MAC; then
    if ! command -v brew >/dev/null 2>&1; then
      echo "Homebrew not found. Network access is required to install it."
      if [ -z "${AUTO_INSTALL_HOMEBREW:-}" ]; then
        if [ -t 0 ]; then
          read -rp "Proceed with Homebrew install now? [y/N]: " reply
          case "$reply" in
            [Yy]* ) ;;
            * )
              echo "Skipping automatic Homebrew install. Install it manually, set AUTO_INSTALL_HOMEBREW=1, or rerun when online."
              exit 1
              ;;
          esac
        else
          echo "Set AUTO_INSTALL_HOMEBREW=1 to auto-install or install manually before rerunning."
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
    echo "Unsupported OS. Install Podman manually and rerun."
    exit 1
  fi
else
  echo "==> Podman already installed."
fi

# --- helper for per-container users ---
create_user_cmd() {
  local os_type="$1"
  local user_name="$DEV_USER"
  local user_pass="$DEV_PASS"
  if [ "$os_type" = "fedora" ]; then
    echo "RUN useradd -m -s /bin/bash $user_name && echo '$user_name:$user_pass' | chpasswd && usermod -aG wheel $user_name"
  else
    echo "RUN useradd -m -s /bin/bash $user_name && echo '$user_name:$user_pass' | chpasswd && adduser $user_name sudo"
  fi
}

ensure_container_absent() {
  local name="$1"
  if podman container exists "$name" >/dev/null 2>&1; then
    podman rm -f "$name" >/dev/null
  fi
}

#######################################
# Folder Layout
#######################################
step "Creating clean host folders..."
echo "Using lab root: $LAB_ROOT"
mkdir -p \
  "$PROJECTS_DIR"/{kali-vnc,pdf-builder,ubuntu-dev,fedora-dev,go-dev,python-dev,c-dev,node-dev,alpine-tools,nmap-tools,packet-analyzer,vulnerability-scanner,iperf-tools,http-test,librenms,librenms-db,snmp-demo} \
  "$DATA_DIR"/{kali-home,pdf-out,ubuntu-home,fedora-home,go-home,python-home,c-home,node-home,alpine-home,network-out,vulnerability-home,iperf-out,librenms-data,librenms-db}

#######################################
# Podman Machine Setup (macOS only)
#######################################
if $IS_MAC; then
  step "Resetting Podman machine to a clean state..."
  if podman machine list 2>/dev/null | grep -q 'podman-machine-default'; then
    podman machine stop >/dev/null 2>&1 || true
    podman machine rm -f >/dev/null 2>&1 || true
  fi

  # init machine
  INIT_DISK_SIZE="${PODMAN_MACHINE_DISK_SIZE:-40}"
  echo "Initializing Podman machine with 4 CPUs, 4GB RAM, and ${INIT_DISK_SIZE}GB disk..."
  podman machine init --cpus 4 --memory 4096 --disk-size "$INIT_DISK_SIZE"

  podman machine set --rootful
  podman machine start

  # macOS helper
  echo "==> Installing Podman mac helper (if available)..."
  HELPER_PATH="$(brew --prefix podman)/bin/podman-mac-helper"
  if [ -x "$HELPER_PATH" ]; then
    sudo "$HELPER_PATH" install
    echo "==> Restarting Podman machine to apply helper..."
    podman machine stop
    podman machine start
  else
    echo "⚠️  podman-mac-helper not found under Homebrew path, skipping helper install."
  fi
else
  echo "==> Podman machine setup not required on this platform; using native Podman."
fi

#######################################
# Containerfiles
#######################################
step "Writing all container definitions..."

# --- Kali Desktop (VNC) ---
cat > "$PROJECTS_DIR/kali-vnc/Containerfile" <<'EOF'
FROM kalilinux/kali-rolling
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

# --- PDF Generator ---
cat > "$PROJECTS_DIR/pdf-builder/Containerfile" <<'EOF'
FROM python:3.12-slim
RUN pip install reportlab
WORKDIR /work
VOLUME ["/out"]
COPY floorplan_generator.py /work/floorplan_generator.py
CMD ["python", "floorplan_generator.py", "/out"]
EOF

cat > "$PROJECTS_DIR/pdf-builder/floorplan_generator.py" <<'EOF'
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
cat > "$PROJECTS_DIR/ubuntu-dev/Containerfile" <<EOF
FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y build-essential curl git sudo pkg-config ca-certificates && apt-get clean && rm -rf /var/lib/apt/lists/*
$(create_user_cmd "ubuntu")
USER $DEV_USER
WORKDIR /home/$DEV_USER
CMD ["bash"]
EOF

cat > "$PROJECTS_DIR/c-dev/Containerfile" <<EOF
FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y build-essential gdb clang make cmake pkg-config git sudo && apt-get clean && rm -rf /var/lib/apt/lists/*
$(create_user_cmd "ubuntu")
USER $DEV_USER
WORKDIR /home/$DEV_USER
CMD ["bash"]
EOF

cat > "$PROJECTS_DIR/go-dev/Containerfile" <<EOF
FROM golang:latest
$(create_user_cmd "debian")
USER $DEV_USER
WORKDIR /home/$DEV_USER/app
CMD ["bash"]
EOF

cat > "$PROJECTS_DIR/python-dev/Containerfile" <<EOF
FROM python:latest
$(create_user_cmd "debian")
USER $DEV_USER
WORKDIR /home/$DEV_USER
CMD ["bash"]
EOF

cat > "$PROJECTS_DIR/node-dev/Containerfile" <<EOF
FROM node:latest
$(create_user_cmd "debian")
USER $DEV_USER
WORKDIR /home/$DEV_USER/app
CMD ["bash"]
EOF

cat > "$PROJECTS_DIR/fedora-dev/Containerfile" <<EOF
FROM fedora:latest
RUN dnf -y update && dnf -y install @development-tools sudo git curl && dnf clean all
$(create_user_cmd "fedora")
USER $DEV_USER
WORKDIR /home/$DEV_USER
CMD ["bash"]
EOF

cat > "$PROJECTS_DIR/alpine-tools/Containerfile" <<EOF
FROM alpine:latest
RUN apk update && apk add git curl wget openssh bash sudo shadow
RUN adduser -D -s /bin/bash $DEV_USER && echo '$DEV_USER:$DEV_PASS' | chpasswd && usermod -aG wheel $DEV_USER
USER $DEV_USER
WORKDIR /home/$DEV_USER
CMD ["bash"]
EOF

# --- Networking / Security Containers ---
cat > "$PROJECTS_DIR/nmap-tools/Containerfile" <<'EOF'
FROM debian:bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends nmap ca-certificates \
  && rm -rf /var/lib/apt/lists/*

USER root
WORKDIR /
CMD ["nmap"]
EOF

cat > "$PROJECTS_DIR/packet-analyzer/Containerfile" <<EOF
FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y tshark sudo && apt-get clean && rm -rf /var/lib/apt/lists/*
$(create_user_cmd "ubuntu")
USER $DEV_USER
WORKDIR /home/$DEV_USER/captures
CMD ["bash"]
EOF

cat > "$PROJECTS_DIR/vulnerability-scanner/Containerfile" <<'EOF'
FROM greenbone/gvm:stable
# Expose GSA on default HTTPS port; runtime mapping keeps external port at 4000.
EXPOSE 9392
EOF

cat > "$PROJECTS_DIR/iperf-tools/Containerfile" <<EOF
FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y iperf iperf3 net-tools curl && apt-get clean && rm -rf /var/lib/apt/lists/*
$(create_user_cmd "ubuntu")
USER $DEV_USER
WORKDIR /home/$DEV_USER
CMD ["bash"]
EOF

cat > "$PROJECTS_DIR/http-test/Containerfile" <<'EOF'
FROM python:3.12-slim
WORKDIR /srv
RUN mkdir -p /srv/www && echo 'OK' > /srv/www/index.html
EXPOSE 8000
CMD ["python", "-m", "http.server", "8000", "--directory", "/srv/www"]
EOF

cat > "$PROJECTS_DIR/snmp-demo/Containerfile" <<'EOF'
FROM debian:stable-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y snmpd && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN printf "agentAddress udp:0.0.0.0:161\nrocommunity public 0.0.0.0/0\nsysLocation Podman-Lab\nsysContact lab-admin@example.com\n" > /etc/snmp/snmpd.conf
EXPOSE 161/udp
CMD ["snmpd", "-f", "-Lo"]
EOF

# --- LibreNMS DB (MariaDB) ---
cat > "$PROJECTS_DIR/librenms-db/Containerfile" <<'EOF'
FROM mariadb:11
ENV MARIADB_ROOT_PASSWORD=librenmsroot
ENV MARIADB_DATABASE=librenms
ENV MARIADB_USER=librenms
ENV MARIADB_PASSWORD=librenmspass
VOLUME ["/var/lib/mysql"]
EXPOSE 3306
EOF

# --- LibreNMS App ---
cat > "$PROJECTS_DIR/librenms/Containerfile" <<'EOF'
FROM librenms/librenms:latest
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

# write generated containerfiles
echo "--> Generated dev and tooling Containerfiles under $PROJECTS_DIR"

#######################################
# Network for LibreNMS stack
#######################################
step "Ensuring podman 'labnet' network exists..."
if ! podman network exists labnet >/dev/null 2>&1; then
  podman network create labnet
fi

#######################################
# Build & Run
#######################################
step "Building images..."
for d in "$PROJECTS_DIR"/*; do
  [ -d "$d" ] || continue
  cd "$d"
  img=$(basename "$d" | tr '[:upper:]' '[:lower:]')
  echo "--> Building image: $img ..."
  if ls Containerfile >/dev/null 2>&1; then
    podman build --pull=always -t "$img" .
  else
    echo "    Skipping $img: no Containerfile found."
  fi
done

step "Running core containers and network tools..."

# General Utilities
ensure_container_absent "kali-vnc"
podman run -d --name kali-vnc -p 5901:5901 -v "$DATA_DIR/kali-home:/home/kali" kali-vnc
podman run --rm -v "$DATA_DIR/pdf-out:/out" pdf-builder

# Dev Shells
if ! $LIGHT; then
  ensure_container_absent "ubuntu-dev"
  podman run -d --name ubuntu-dev      -v "$DATA_DIR/ubuntu-home:/home/$DEV_USER" ubuntu-dev
  ensure_container_absent "fedora-dev"
  podman run -d --name fedora-dev      -v "$DATA_DIR/fedora-home:/home/$DEV_USER" fedora-dev
  ensure_container_absent "go-dev"
  podman run -d --name go-dev          -v "$DATA_DIR/go-home:/home/$DEV_USER/app" go-dev
  ensure_container_absent "python-dev"
  podman run -d --name python-dev      -v "$DATA_DIR/python-home:/home/$DEV_USER" python-dev
  ensure_container_absent "c-dev"
  podman run -d --name c-dev           -v "$DATA_DIR/c-home:/home/$DEV_USER" c-dev
  ensure_container_absent "node-dev"
  podman run -d --name node-dev        -v "$DATA_DIR/node-home:/home/$DEV_USER/app" node-dev
  ensure_container_absent "alpine-tools"
  podman run -d --name alpine-tools    -v "$DATA_DIR/alpine-home:/home/$DEV_USER" alpine-tools
else
  ensure_container_absent "ubuntu-dev"
  podman run -d --name ubuntu-dev      -v "$DATA_DIR/ubuntu-home:/home/$DEV_USER" ubuntu-dev
fi

# Networking / Security
ensure_container_absent "nmap-tools"
podman run -d --name nmap-tools nmap-tools

ensure_container_absent "packet-analyzer"
podman run -d --name packet-analyzer \
  --net=host \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  -v "$DATA_DIR/network-out:/home/$DEV_USER/captures" \
  packet-analyzer

ensure_container_absent "iperf-tools"
podman run -d --name iperf-tools \
  -v "$DATA_DIR/iperf-out:/home/$DEV_USER" \
  iperf-tools

ensure_container_absent "vulnerability-scanner"
podman run -d --name vulnerability-scanner \
  -p 4000:9392 \
  -v "$DATA_DIR/vulnerability-home:/data" \
  vulnerability-scanner

ensure_container_absent "http-test"
podman run -d --name http-test -p 8000:8000 http-test

# LibreNMS stack
ensure_container_absent "librenms-db"
podman run -d --name librenms-db \
  --network labnet \
  -v "$DATA_DIR/librenms-db:/var/lib/mysql" \
  librenms-db

ensure_container_absent "librenms"
podman run -d --name librenms \
  --network labnet \
  -p 8001:8000 \
  -v "$DATA_DIR/librenms-data:/data" \
  librenms

# SNMP demo target for LibreNMS
ensure_container_absent "snmp-demo"
podman run -d --name snmp-demo \
  --network labnet \
  snmp-demo

#######################################
# Final Output
#######################################
echo ""
echo "✅ Setup complete! To clean up, run: $0 teardown"
echo "Running containers:"
podman ps --format 'table {{.Names}}\t{{.Ports}}\t{{.Status}}'

echo ""
echo "### Access Information ###"
echo "Common Dev User/Pass: $DEV_USER / $DEV_PASS"
echo ""
echo "🖥️ Kali Desktop (VNC):"
echo "  Connect to: localhost:5901"
echo "  User: kali   Pass: kali"
echo "  VNC password: kali"
echo ""
echo "📄 Floor plan PDFs:"
echo "  $DATA_DIR/pdf-out/"
echo ""
echo "💻 Dev Containers:"
echo "  podman exec -it ubuntu-dev bash"
echo "  podman exec -it fedora-dev bash"
echo "  podman exec -it go-dev bash"
echo "  podman exec -it python-dev bash"
echo "  podman exec -it c-dev bash"
echo "  podman exec -it node-dev bash"
echo "  podman exec -it alpine-tools bash"
echo ""
echo "🌐 Net/Sec:"
echo "  podman exec -it nmap-tools nmap -v <target>"
echo "  podman exec -it packet-analyzer bash   # sudo tshark -i eth0"
echo "  podman exec -it iperf-tools bash       # iperf3 -s / -c"
echo "  GVM: https://localhost:4000  (proxied to container port 9392; first run can take a few mins)"
echo ""
echo "🧪 HTTP Test:"
echo "  http://localhost:8000  -> 'OK'"
echo ""
echo "📡 LibreNMS:"
echo "  http://localhost:8001"
echo "  DB: mariadb on container 'librenms-db' (network: labnet)"
echo "  Note: first run may take 1–2 minutes to finish migrations."
echo ""
echo "  NOTE: on macOS/Podman this captures from the VM, not your Mac's Wi-Fi."

if $IS_MAC; then
  SOCK=$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')
  echo "🐳 Docker-compatible socket (macOS):"
  echo "  export DOCKER_HOST='unix://$SOCK'"
  echo "  # Add that to ~/.zshrc if you want it permanent"
fi
