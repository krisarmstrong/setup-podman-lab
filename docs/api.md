# API Documentation

## Main Script

**Script**: `setup-podman-lab.sh`

Automated Podman lab environment bootstrap and management.

### Usage

```bash
./setup-podman-lab.sh [MODE] [OPTIONS]
```

### Modes

**Standard Mode** (default):
```bash
./setup-podman-lab.sh
```
Full container suite deployment with all profiles enabled.

**Light Mode**:
```bash
./setup-podman-lab.sh light
```
Reduced container set for resource-constrained systems.

**Teardown Mode**:
```bash
./setup-podman-lab.sh teardown
```
Complete cleanup: removes all containers, images, volumes, and directories.

### Environment Variables

#### Core Configuration

**`PODMAN_LAB_ROOT`**
- Default: `$HOME`
- Description: Base directory for PodmanProjects/ and PodmanData/
- Example: `PODMAN_LAB_ROOT="$PWD/lab-tmp" ./setup-podman-lab.sh`

**`PODMAN_MACHINE_DISK_SIZE`**
- Default: `40` (GB)
- Description: Disk allocation for Podman machine (macOS)
- Example: `PODMAN_MACHINE_DISK_SIZE=120 ./setup-podman-lab.sh`

**`LAB_BUILD_CONCURRENCY`**
- Default: `4`
- Description: Number of parallel container builds
- Example: `LAB_BUILD_CONCURRENCY=8 ./setup-podman-lab.sh`

#### Registry Configuration

**`LAB_REGISTRY_MIRROR`**
- Default: None
- Description: Registry mirror for base images
- Example: `LAB_REGISTRY_MIRROR="mirror.example.com/docker" ./setup-podman-lab.sh`

#### Output Control

**`LAB_VERBOSE`**
- Default: `false`
- Description: Enable verbose output
- Values: `true`, `false`

**`LAB_QUIET`**
- Default: `false`
- Description: Suppress progress messages
- Values: `true`, `false`

**`LAB_PROGRESS`**
- Default: `true`
- Description: Show build progress
- Values: `true`, `false`

### Container Profiles

#### Development Containers

**Ubuntu Dev**
- Base: Ubuntu latest
- User: `dev:dev`
- Tools: gcc, make, git, vim

**Fedora Dev**
- Base: Fedora latest
- User: `dev:dev`
- Tools: dnf, development tools

**Go Dev**
- Base: golang:latest
- User: `dev:dev`
- Go toolchain and modules

**Python Dev**
- Base: python:latest
- User: `dev:dev`
- pip, virtualenv, common packages

**Node Dev**
- Base: node:latest
- User: `dev:dev`
- npm, yarn, node tools

**C Dev**
- Base: gcc:latest
- Compiler toolchain
- Build utilities

**Alpine Dev**
- Base: alpine:latest
- Minimal footprint
- Basic development tools

#### Network Tools

**Nmap Container**
- Network scanning
- Port discovery
- Service detection

**Wireshark/Tshark Container**
- Packet capture
- Protocol analysis
- PCAP file processing

**iPerf3 Container**
- Network performance testing
- Bandwidth measurement
- TCP/UDP testing

#### Security Tools

**Kali Desktop (VNC)**
- Access: `localhost:5901`
- Password: `kali`
- User: `kali:kali`
- Full Kali Linux XFCE environment
- VNC server on port 5901

**GVM/OpenVAS**
- Access: `http://localhost:4000`
- Vulnerability scanning
- Security assessment
- Web-based interface

#### Monitoring Stack

**LibreNMS**
- Access: `http://localhost:8001`
- Network device monitoring
- SNMP polling
- Auto-discovery

**MariaDB**
- Backend database for LibreNMS
- User: `librenms`
- Password: `librenmspass`
- Root password: `librenmsroot`

**SNMP Demo Node**
- Test device for LibreNMS
- SNMP agent simulation
- Demo data generation

#### Utility Containers

**HTTP Test Server**
- Access: `http://localhost:8000`
- Python HTTP server
- Returns "OK" response
- Quick endpoint testing

**PDF Builder**
- ReportLab-based
- Floorplan PDF generation
- Output: `~/PodmanData/pdf-out`

## Installation Process

### Podman Setup

**macOS**:
```bash
# Installs via Homebrew
brew install podman
brew install podman-mac-helper

# Creates rootful machine
podman machine init --cpus 4 --memory 4096 --disk-size 40 --rootful lab
podman machine start lab
```

**Linux**:
```bash
# Uses system package manager
sudo apt-get install podman        # Debian/Ubuntu
sudo dnf install podman            # Fedora/RHEL
```

### Container Building

Build process phases:
1. Platform detection
2. Podman installation verification
3. Machine initialization (if needed)
4. Directory structure creation
5. Containerfile generation
6. Parallel image building
7. Container deployment
8. Network configuration
9. Volume mounting

## Command Examples

### Basic Usage

```bash
# Full deployment
./setup-podman-lab.sh

# Light deployment
./setup-podman-lab.sh light

# Complete cleanup
./setup-podman-lab.sh teardown
```

### Advanced Usage

```bash
# Custom root directory
PODMAN_LAB_ROOT="/opt/lab" ./setup-podman-lab.sh

# Larger disk allocation (macOS)
PODMAN_MACHINE_DISK_SIZE=120 ./setup-podman-lab.sh

# Use registry mirror
LAB_REGISTRY_MIRROR="mirror.local/docker" ./setup-podman-lab.sh

# Increase build parallelism
LAB_BUILD_CONCURRENCY=8 ./setup-podman-lab.sh

# Quiet mode for CI/CD
LAB_QUIET=true ./setup-podman-lab.sh light

# Verbose debugging
LAB_VERBOSE=true ./setup-podman-lab.sh
```

### Docker Hub Authentication

```bash
# Avoid rate limiting
podman login docker.io
./setup-podman-lab.sh
```

## Container Management

### Listing Containers

```bash
podman ps -a
```

### Accessing Containers

```bash
# Interactive shell
podman exec -it <container-name> /bin/bash

# Run command
podman exec <container-name> command
```

### Container Lifecycle

```bash
# Start container
podman start <container-name>

# Stop container
podman stop <container-name>

# Restart container
podman restart <container-name>

# Remove container
podman rm <container-name>
```

## Troubleshooting

### Common Issues

**Podman Not Found**
- Run script again (auto-installs)
- Check PATH configuration
- Verify installation manually

**Insufficient Resources**
- Use light mode
- Increase machine resources
- Adjust PODMAN_MACHINE_DISK_SIZE

**Container Build Failures**
- Check internet connectivity
- Verify registry access
- Review build logs
- Reduce LAB_BUILD_CONCURRENCY

**Port Conflicts**
- Check for services on ports 4000, 5901, 8000, 8001
- Stop conflicting services
- Modify port mappings in script

## Return Codes

- `0`: Success
- `1`: Installation error
- `2`: Build error
- `3`: Runtime error
- `4`: Configuration error

## Dependencies

### System Requirements

- macOS 10.15+ or Linux (Ubuntu 20.04+, Fedora 35+)
- 4GB+ RAM available
- 40GB+ free disk space
- Internet connectivity

### Software Dependencies

- Podman 4.0+
- Bash 4.0+
- curl or wget (for downloads)
- VNC viewer (for Kali desktop access)

## Security Notes

### Default Credentials

All default credentials are for development only:
- Change before production use
- Use strong passwords
- Implement proper authentication
- Follow security best practices

### Network Exposure

- Services bound to localhost by default
- Avoid exposing to external networks
- Use firewall rules appropriately
- Consider VPN for remote access

---
Author: Kris Armstrong
