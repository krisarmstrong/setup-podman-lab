# Container Changes and Additions

## Renamed Containers

| Old Name | New Name | Reason |
|----------|----------|--------|
| `packet-analyzer` | `network-capture` | More descriptive of actual function |
| `vulnerability-scanner` | `gvm-scanner` | More specific (uses GVM/OpenVAS) |
| `http-test` | `http-server` | Clearer purpose |

**Note**: Old names are maintained as aliases for backward compatibility.

## New Containers Added

### Development Containers
- **cpp-dev**: C++ development environment with g++, clang++, CMake, Boost, Eigen3
- **rust-dev**: Rust development environment with Cargo

### Infrastructure Containers
- **database-dev**: Multi-database environment (PostgreSQL, MySQL, Redis, SQLite)
- **web-server**: Nginx web server with Alpine base
- **ansible-control**: Ansible automation control node

## Container Enhancements

### network-capture (formerly packet-analyzer)
- Added tcpdump
- Added wireshark-common
- Added network utilities (net-tools, iputils-ping, iproute2)
- User added to wireshark group

### gvm-scanner (formerly vulnerability-scanner)
- Updated to use greenbone/gvm:stable
- Exposed additional port 9390
- Added volume for persistent data

### http-server (formerly http-test)
- Added volume mount for /srv/www

## New Profile

### infra
Includes infrastructure and automation tools:
- database-dev
- web-server
- ansible-control

## Updated Profiles

### dev
Now includes:
- ubuntu-dev, fedora-dev
- go-dev, python-dev, c-dev, **cpp-dev**, node-dev, **rust-dev**
- alpine-tools, pdf-builder

### net
Now includes:
- nmap-tools, **network-capture**, iperf-tools, **http-server**, snmp-demo

### sec
Now includes:
- kali-vnc, **gvm-scanner**, nmap-tools, **network-capture**

### monitor
Now includes:
- librenms, librenms-db, snmp-demo, **http-server**

## New Features

### Python Version Selection
```bash
LAB_PYTHON_VERSION=3.12 ./setup-podman-lab.sh
```

### Light Mode
Light mode now builds only essential containers for quick testing:
- ubuntu-dev (basic dev environment)
- kali-vnc (security workstation)
- nmap-tools (network scanning)
- network-capture (packet analysis)

```bash
./setup-podman-lab.sh light
```

### LAN Networking (Coming Soon)
```bash
LAB_LAN_MODE=1 LAB_LAN_INTERFACE=en0 ./setup-podman-lab.sh
```

## Data Directory Mappings

| Container | Data Directory |
|-----------|----------------|
| cpp-dev | cpp-home |
| rust-dev | rust-home |
| network-capture | network-captures |
| gvm-scanner | gvm-data |
| http-server | http-data |
| database-dev | database-data |
| web-server | web-data |
| ansible-control | ansible-data |
