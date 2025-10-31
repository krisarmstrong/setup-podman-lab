# 🧰 Podman Lab Bootstrap

**A full-featured local lab environment for developers, hackers, and network engineers — in one command.**  
Automatically installs Podman (if missing), builds a clean container suite (dev, network, and security tools), and spins up everything from a **Kali VNC desktop** to **LibreNMS with MariaDB**.  

See the [Repository Guidelines](AGENTS.md) before contributing changes.

No Docker Desktop tax. No manual setup. No excuses.

---

## 🚀 Features

- **Automatic setup**  
  - Installs Podman (macOS/Linux)
  - Creates clean folder structure
  - Builds and runs all containers from scratch
  - Supports `light` mode for smaller environments

- **Teardown mode**  
  ```bash
  ./setup-podman-lab.sh teardown
  ```
  Wipes all containers, images, and folders. Back to factory clean.

- **Rootful Podman machine (Mac/Linux)**  
  - Allocates 4 CPUs, 4GB RAM, 40GB disk (macOS)
  - Automatically installs `podman-mac-helper` for native networking

- **Self-contained Containers**
  - 🖥️ **Kali XFCE Desktop (VNC)** – for GUI hacking & testing  
  - 🧑‍💻 **Dev Containers** – Ubuntu, Fedora, Go, Python, Node, C, Alpine  
  - 📡 **Networking / Security Tools** – Nmap, Wireshark/Tshark, iPerf3, GVM/OpenVAS  
  - 🌐 **HTTP Test Server** – Python HTTP server for quick endpoint checks  
  - 🧾 **PDF Builder** – Generates floorplan PDFs via ReportLab  
  - 📈 **LibreNMS Stack** – LibreNMS + MariaDB + SNMP Demo node
- **Flexible automation**
  - Profiles for dev / net / security / monitoring stacks
  - Target specific components or split build/run phases
  - Quiet / verbose / progress toggles for CI scripts

---

## 🏗️ Setup Instructions

1. Clone or copy the repo:
   ```bash
   git clone https://github.com/krisarmstrong/setup-podman-lab.git
   cd setup-podman-lab
   chmod +x setup-podman-lab.sh
   ```

2. Run the bootstrap:
   ```bash
   ./setup-podman-lab.sh
   ```

   Or, if you’re on a Mac that’s *barely breathing*:
   ```bash
   ./setup-podman-lab.sh light
   ```

3. Grab coffee ☕ — it builds ~15 containers.

> Running in a sandbox or on a shared machine? Set `PODMAN_LAB_ROOT` to redirect the generated `PodmanProjects/` and `PodmanData/` folders, for example:  
> `PODMAN_LAB_ROOT="$PWD/lab-tmp" ./setup-podman-lab.sh light`
>
> On macOS, adjust the Podman VM disk size with `PODMAN_MACHINE_DISK_SIZE=120` if you need more space.
>
> First-time pull? Avoid Docker Hub throttling by authenticating once:  
> `podman login docker.io`

---

## 🧠 Default Credentials

| Container | Username | Password |
|------------|-----------|-----------|
| General Dev Containers | `dev` | `dev` |
| Kali Desktop | `kali` | `kali` |
| LibreNMS DB | `librenms` | `librenmspass` |
| LibreNMS Root | `librenmsroot` | *(internal only)* |

> Change these before using in anything production-like.  
> Or don’t — just don’t email me from your breach report.

---

## 🌍 Access Points

| Service | Address | Notes |
|----------|----------|-------|
| **Kali VNC Desktop** | `localhost:5901` | Password: `kali` |
| **LibreNMS Web UI** | `http://localhost:8001` | May take 1–2 min first run |
| **HTTP Test Server** | `http://localhost:8000` | Returns “OK” |
| **OpenVAS / GVM** | `http://localhost:4000` | Vulnerability scanner |
| **PDF Output Folder** | `~/PodmanData/pdf-out` | Auto-generated floorplans |

---

## 🧰 Common Commands

| Command | Purpose |
|----------|----------|
| `podman ps` | List running containers |
| `./setup-podman-lab.sh --profile dev --build-only` | Rebuild just the dev stack |
| `./setup-podman-lab.sh --profile dev --run-only` | Restart previously built dev containers |
| `./setup-podman-lab.sh --components kali-vnc,http-test` | Target specific components |
| `podman exec -it ubuntu-dev bash` | Open a shell in the Ubuntu dev container |
| `podman exec -it packet-analyzer bash` | Run Wireshark CLI (tshark) |
| `podman logs librenms` | Check LibreNMS startup logs |
| `podman machine inspect` | Show machine config (Mac) |

---

## 🔄 Cleanup

When you’re done wrecking your lab:

```bash
./setup-podman-lab.sh teardown
```

That stops everything, deletes images, nukes volumes, and removes:
```
~/PodmanProjects
~/PodmanData
```

---

## 🧩 Folder Layout

```
~/PodmanProjects/   → Container build contexts
~/PodmanData/       → Persistent data (mounted volumes)
```

Each container gets its own subfolder, so nothing collides.

---

## ⚙️ macOS Notes

- Uses **Podman Machine** (VM-based)  
- `podman-mac-helper` installed automatically for native networking  
- Capture containers (like packet-analyzer) see VM interfaces, not Wi-Fi directly

**Avoid Docker Hub rate limiting:**  
Authenticate once before running the full lab so base images pull without throttling:
```bash
podman login docker.io
```
(If you prefer Docker CLI, `docker login` works too.)

To use Docker-style commands:
```bash
export DOCKER_HOST="unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')"
```

---

## 🧨 Troubleshooting

**Podman won’t connect (Mac):**
```bash
podman machine init
podman machine start
```

**LibreNMS web page blank:**
Wait a minute — migrations can take time on first boot.

**VNC client says “connection refused”:**
Ensure `kali-vnc` is running:
```bash
podman ps | grep kali-vnc
```

**Need more resources (Mac):**
```bash
podman machine set --cpus 8 --memory 8192
podman machine restart
```

**Hit Docker Hub “too many requests”:**  
Unauthenticated pulls are rate limited. Run `podman login docker.io`, or retry later once the limit resets.

---

## 🧭 Component Profiles & Flags

| Profile | Includes |
|---------|----------|
| `all` *(default)* | Everything in the lab |
| `dev` | ubuntu-dev, fedora-dev, go-dev, python-dev, c-dev, node-dev, alpine-tools, pdf-builder |
| `net` | nmap-tools, packet-analyzer, iperf-tools, http-test, snmp-demo |
| `sec` | kali-vnc, vulnerability-scanner, nmap-tools |
| `monitor` | librenms, librenms-db, snmp-demo, http-test |

### CLI switches

- `--profile NAME` Select one of the profiles above.
- `--components a,b,c` Build/run only the listed components (overrides profile).
- `--build-only` Run the builds but skip container startup.
- `--run-only` Start containers assuming images already exist.
- `--quiet` Suppress INFO-level console output (logs still written).
- `--verbose` Stream command output and include DEBUG logs.
- `--no-progress` / `--progress` Toggle the textual progress bar.

### Environment overrides

| Variable | Purpose |
|----------|---------|
| `LAB_PROFILE` | Default profile when `--profile` isn’t provided. |
| `LAB_COMPONENTS` | Default component list (comma-separated). |
| `LAB_PULL` | Podman pull policy; defaults to `if-needed` (set `always` for clean bases). |
| `LAB_IMAGE_PREFIX` | Namespace for built images (default `podman-lab`). |
| `LAB_PROGRESS_ENABLED` | Set `0` to disable the progress bar globally. |
| `LAB_VERBOSE` / `LAB_QUIET` | Default logging verbosity toggles. |
| `LAB_LOG_FILE` | Target log file path (defaults under `$PODMAN_LAB_ROOT/logs`). |
| `LAB_SKIP_REGISTRY_CHECK` | Set `1` to suppress the Docker Hub login warning. |

Detailed logs for every run live in `$(PODMAN_LAB_ROOT:-$HOME)/logs/setup-podman-lab-<timestamp>.log`.

---

## 👤 Author

**Kris Armstrong**  
Sales / Systems Engineer • Network & Cybersecurity Specialist  
**“The Man. The Myth. The Legend.”**

[LinkedIn](https://www.linkedin.com/in/kris-armstrong) | [GitHub](https://github.com/krisarmstrong)

---

## ⚠️ Disclaimer

This lab is **not hardened**. It’s intentionally permissive to make development and testing easy.  
Don’t expose any of these containers directly to the internet unless you’re doing a pen test and you *really* know what you’re doing.

---

## 🏁 License

MIT — because freedom smells like shell scripts and root shells.
