# Architecture

## Overview

Podman Lab Bootstrap is a full-featured local lab environment automation tool for developers, hackers, and network engineers. It provides a complete container-based infrastructure setup with a single command, featuring development environments, network tools, security utilities, and monitoring systems.

## System Architecture

### Core Components

1. **Bootstrap Script** (`setup-podman-lab.sh`)
   - Podman installation automation
   - Container image building
   - Multi-container orchestration
   - Environment configuration
   - Teardown and cleanup operations

2. **Container Suite**
   - Development containers (Ubuntu, Fedora, Go, Python, Node, C, Alpine)
   - Security tools (Kali XFCE Desktop with VNC, GVM/OpenVAS)
   - Network utilities (Nmap, Wireshark/Tshark, iPerf3)
   - Monitoring stack (LibreNMS + MariaDB + SNMP demo)
   - Utility containers (HTTP test server, PDF builder)

3. **Infrastructure Components**
   - Podman machine (rootful mode)
   - Native networking (podman-mac-helper on macOS)
   - Persistent data volumes
   - Custom network bridges
   - Resource allocation management

### Technical Implementation

#### Podman Machine Setup

Automated provisioning:
- Platform detection (macOS/Linux)
- Podman installation verification
- Rootful machine creation
- Resource allocation (4 CPU, 4GB RAM, 40GB disk)
- Network helper installation (macOS)
- Container runtime configuration

#### Container Architecture

Multi-tier container deployment:
- Base image selection and caching
- Registry mirror support
- Parallel image building
- Containerfile-based builds
- Volume mounting strategy
- Port mapping configuration

#### Build System

Intelligent build orchestration:
- Dependency resolution
- Parallel build execution (configurable concurrency)
- Build cache optimization
- Layer reuse strategies
- Progress reporting
- Error handling and recovery

### Data Flow

```
Bootstrap Script → Platform Detection → Podman Setup → Machine Init
                                                            ↓
                                                  Container Build Pipeline
                                                            ↓
                                              Parallel Image Construction
                                                            ↓
                                                  Container Deployment
                                                            ↓
                                              Network & Volume Setup
                                                            ↓
                                                    Service Launch
```

### Directory Structure

```
$PODMAN_LAB_ROOT/
├── PodmanProjects/          # Container build contexts
│   ├── dev-containers/      # Development environments
│   ├── net-containers/      # Network tools
│   ├── security/            # Security utilities
│   └── monitoring/          # Monitoring stack
└── PodmanData/              # Persistent data
    ├── librenms/            # LibreNMS data
    ├── mariadb/             # Database storage
    └── pdf-out/             # PDF generation output
```

### Container Profiles

**Dev Profile**:
- Ubuntu, Fedora, Alpine base containers
- Language-specific environments (Go, Python, Node, C)
- Development tools and utilities
- User authentication configured

**Network Profile**:
- Nmap for scanning
- Wireshark/Tshark for packet analysis
- iPerf3 for performance testing
- Network diagnostic utilities

**Security Profile**:
- Kali Linux XFCE desktop (VNC access)
- GVM/OpenVAS vulnerability scanner
- Security assessment tools
- Penetration testing utilities

**Monitoring Profile**:
- LibreNMS network monitoring
- MariaDB backend
- SNMP demo node
- Automated discovery

## Design Principles

1. **Automation**: Single-command setup and teardown
2. **Flexibility**: Modular profiles and configurations
3. **Portability**: Cross-platform support (macOS/Linux)
4. **Isolation**: Container-based separation
5. **Reproducibility**: Consistent environment creation

## Performance Characteristics

### Optimization Techniques

1. **Parallel Builds**: Concurrent image construction
2. **Build Caching**: Layer reuse across builds
3. **Registry Mirrors**: Reduced pull times
4. **Resource Management**: Configurable CPU/memory
5. **Light Mode**: Reduced container set for constrained systems

### Scalability

- Supports 15+ container deployments
- Configurable build concurrency
- Adjustable machine resources
- Modular profile activation
- Incremental deployment options

## Deployment Modes

### Standard Mode

Full deployment:
- All container profiles
- Complete tool suite
- Full resource allocation
- All services enabled

### Light Mode

Reduced footprint:
- Essential containers only
- Minimal resource usage
- Subset of tools
- Suitable for constrained systems

### Teardown Mode

Complete cleanup:
- Container removal
- Image deletion
- Volume cleanup
- Directory structure removal
- Machine destruction

## Network Architecture

### Port Mappings

- **5901**: Kali VNC Desktop
- **8001**: LibreNMS Web UI
- **8000**: HTTP Test Server
- **4000**: OpenVAS/GVM Web UI

### Container Networking

- Custom bridge networks
- Inter-container communication
- Host port forwarding
- Network isolation options

## Security Considerations

- Default credentials (development only)
- Rootful vs rootless modes
- Container isolation
- Network segmentation
- Volume permissions

## Resource Requirements

### Minimum

- 4 CPU cores
- 4GB RAM
- 40GB disk space
- macOS or Linux

### Recommended

- 8 CPU cores
- 8GB RAM
- 120GB disk space
- Fast internet connection

---
Author: Kris Armstrong
