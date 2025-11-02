# Networking Guide

## Overview

The Podman Lab uses **dual network mode** by default, allowing containers to operate on both isolated and physical networks simultaneously:

- **`labnet` (bridge network)**: Internal network for container-to-container communication
- **`labnet-lan` (macvlan network)**: Optional connection to your physical LAN

This architecture gives you the best of both worlds:
- Containers can always communicate with each other via the bridge network
- Containers can optionally be visible on your physical LAN for real-world testing
- You can enable/disable LAN access anytime without rebuilding containers

## Network Modes

### Bridge Mode (Default)

All containers start on the `labnet` bridge network, providing isolated communication:

```
┌─────────────────────────────────────────┐
│  Podman Lab (labnet bridge)            │
│                                         │
│  ┌──────────┐    ┌──────────┐         │
│  │Container │◄──►│Container │         │
│  │    A     │    │    B     │         │
│  └──────────┘    └──────────┘         │
└─────────────────────────────────────────┘
```

**Use cases:**
- Development and testing in isolation
- Learning and experimentation
- CI/CD pipelines

### Dual Network Mode (Bridge + LAN)

Containers can be attached to both networks simultaneously:

```
Physical LAN (192.168.1.0/24)
        │
        │ macvlan (labnet-lan)
        │
┌───────┼─────────────────────────────────┐
│  Pod  │                                 │
│  Lab  │    ┌──────────┐                 │
│       ├───►│Container │                 │
│       │    │    A     │◄───┐            │
│       │    └──────────┘    │ labnet     │
│       │                    │ (bridge)   │
│       │    ┌──────────┐    │            │
│       │    │Container │◄───┘            │
│       │    │    B     │                 │
│       │    └──────────┘                 │
└─────────────────────────────────────────┘
```

**Use cases:**
- Network capture from physical LAN (network-capture container)
- Exposing web services to LAN (http-server, gvm-scanner)
- Real-world security testing
- Device discovery and monitoring

## Quick Start

### Check Available Network Interfaces

First, identify your physical network interface:

**macOS:**
```bash
# List all interfaces
networksetup -listallhardwareports

# Common interfaces:
# - en0: Wi-Fi
# - en1: Ethernet (Thunderbolt/USB)
```

**Linux:**
```bash
# List all interfaces
ip link show

# Common interfaces:
# - eth0, enp0s3: Ethernet
# - wlan0, wlp2s0: Wi-Fi
```

### Enable LAN for Specific Containers

Connect individual containers to your physical LAN:

```bash
# Start the lab normally
./setup-podman-lab.sh

# Connect network-capture to LAN for real packet capture
./setup-podman-lab.sh lan-enable network-capture --lan-interface en0

# Connect http-server to LAN to expose web service
./setup-podman-lab.sh lan-enable http-server --lan-interface en0

# Check LAN status
./setup-podman-lab.sh lan-status
```

###Enable LAN for All Containers

Connect all running containers to LAN at once:

```bash
# Start lab and connect everything to LAN
./setup-podman-lab.sh --lan-mode --lan-interface en0

# Or enable for all running containers
./setup-podman-lab.sh lan-enable all --lan-interface en0
```

### Disable LAN Access

Disconnect containers from LAN (they remain on bridge network):

```bash
# Disconnect specific container
./setup-podman-lab.sh lan-disable network-capture

# Disconnect all containers
./setup-podman-lab.sh lan-disable all
```

## Command Reference

### LAN Commands

| Command | Description | Example |
|---------|-------------|---------|
| `lan-enable CONTAINER` | Connect container to LAN | `./setup-podman-lab.sh lan-enable network-capture --lan-interface en0` |
| `lan-enable all` | Connect all containers to LAN | `./setup-podman-lab.sh lan-enable all --lan-interface en0` |
| `lan-disable CONTAINER` | Disconnect container from LAN | `./setup-podman-lab.sh lan-disable network-capture` |
| `lan-disable all` | Disconnect all containers from LAN | `./setup-podman-lab.sh lan-disable all` |
| `lan-status` | Show LAN network status | `./setup-podman-lab.sh lan-status` |

### LAN Options

| Option | Description | Example |
|--------|-------------|---------|
| `--lan-mode` | Enable LAN at startup | `./setup-podman-lab.sh --lan-mode --lan-interface en0` |
| `--lan-interface IF` | Specify physical interface | `--lan-interface en0` |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `LAB_LAN_MODE` | Enable LAN mode (0/1) | `0` |
| `LAB_LAN_INTERFACE` | Physical network interface | (none) |

## Use Cases

### 1. Network Packet Capture from Physical LAN

Capture real network traffic from your LAN:

```bash
# Start lab with network-capture on LAN
./setup-podman-lab.sh

# Connect to physical LAN
./setup-podman-lab.sh lan-enable network-capture --lan-interface en0

# Enter container and capture traffic
podman exec -it network-capture bash
sudo tcpdump -i eth1 -w /home/dev/captures/lan-capture.pcap

# Or use tshark
sudo tshark -i eth1 -w /home/dev/captures/lan-capture.pcapng
```

**Note:** `eth0` is the bridge network, `eth1` is the LAN network (macvlan).

### 2. Expose Web Services to LAN

Make http-server accessible from other devices on your network:

```bash
# Start lab with http-server
./setup-podman-lab.sh

# Connect http-server to LAN
./setup-podman-lab.sh lan-enable http-server --lan-interface en0

# Check the LAN IP address
./setup-podman-lab.sh lan-status

# Access from other devices
# http://<lan-ip>:8000
```

### 3. Security Scanning on LAN

Run GVM vulnerability scanner accessible from other machines:

```bash
# Start lab with security profile
./setup-podman-lab.sh --profile sec

# Connect gvm-scanner to LAN
./setup-podman-lab.sh lan-enable gvm-scanner --lan-interface en0

# Check LAN IP
./setup-podman-lab.sh lan-status

# Access from browser on another machine
# https://<lan-ip>:4000
```

### 4. Full Lab on LAN

Connect all containers to LAN from the start:

```bash
# Start with everything on LAN
./setup-podman-lab.sh --lan-mode --lan-interface en0

# Or with specific profile
./setup-podman-lab.sh --profile net --lan-mode --lan-interface en0
```

## Technical Details

### Macvlan Driver

The LAN network uses Podman's macvlan driver, which:
- Creates virtual network interfaces on the parent physical interface
- Assigns containers their own MAC addresses
- Makes containers appear as physical devices on the LAN
- Containers get IP addresses from your network's DHCP server

### Network Inspection

View detailed network information:

```bash
# List all networks
podman network ls

# Inspect bridge network
podman network inspect labnet

# Inspect LAN network (if created)
podman network inspect labnet-lan

# Check container's networks
podman inspect <container> | grep -A 10 NetworkSettings
```

### IP Address Management

**Bridge Network (`labnet`):**
- Subnet: Assigned by Podman (typically 10.89.x.0/24)
- IP allocation: Automatic within subnet
- DNS: Podman's built-in DNS

**LAN Network (`labnet-lan`):**
- Subnet: Your physical LAN subnet (e.g., 192.168.1.0/24)
- IP allocation: DHCP from your router/network
- DNS: Your network's DNS servers

## Troubleshooting

### LAN Network Not Created

**Problem:** `lan-enable` fails with "network not found"

**Solution:**
```bash
# The network is created automatically on first lan-enable
# If it fails, check your interface name:
ip link show           # Linux
networksetup -listallhardwareports  # macOS

# Try with correct interface
./setup-podman-lab.sh lan-enable network-capture --lan-interface <correct-if>
```

### Containers Not Getting LAN IP

**Problem:** Container shows no LAN IP address

**Possible causes:**
1. **DHCP server not responding**
   - Check if your router has DHCP enabled
   - Check if there are available DHCP addresses

2. **Interface not active**
   - Ensure the physical interface is connected and up
   - Check: `ip link show <interface>`

3. **macOS Podman VM limitation**
   - On macOS, the Podman VM must have network access
   - The VM might need additional configuration

### Cannot Access Container from LAN

**Problem:** Other devices can't reach container on LAN

**Check:**
1. **Firewall rules**
   - macOS: System Settings → Network → Firewall
   - Linux: `sudo iptables -L -n`

2. **Container is on LAN network**
   ```bash
   ./setup-podman-lab.sh lan-status
   ```

3. **Port is exposed**
   - Check container's exposed ports: `podman ps`

4. **Service is running**
   - Enter container and check: `podman exec -it <container> bash`

### macOS-Specific Issues

**Problem:** Macvlan not working on macOS

**Note:** macOS Podman runs in a VM, which can complicate macvlan:
- The physical interface is on macOS, not in the Podman VM
- The VM might not have direct access to your physical network
- You may need to use port forwarding instead of macvlan

**Alternative for macOS:**
```bash
# Use port forwarding instead
podman run -p 8000:8000 ...

# Access from LAN using Mac's IP
# http://<mac-ip>:8000
```

## Best Practices

### Security Considerations

1. **Firewall Rules**
   - Containers on LAN are accessible from your network
   - Ensure proper firewall rules are in place
   - Consider network segmentation for security testing

2. **Default Credentials**
   - Change default passwords before enabling LAN mode
   - Review security settings in exposed containers

3. **Network Isolation**
   - Use VLANs or separate networks for security testing
   - Don't expose vulnerable services to untrusted networks

### Performance

1. **Network Interface**
   - Use Ethernet (en1) instead of Wi-Fi (en0) for better performance
   - Wired connections provide more reliable packet capture

2. **Selective LAN Access**
   - Only connect containers that need LAN access
   - Keep development containers on bridge network only

### Workflow

1. **Development Phase**
   - Start with bridge network only (default)
   - Develop and test in isolation

2. **Integration Testing**
   - Enable LAN for specific containers as needed
   - Test interaction with real network devices

3. **Cleanup**
   - Disable LAN when not needed
   - Remove LAN network if desired:
     ```bash
     podman network rm labnet-lan
     ```

## Examples

### Example 1: Network Traffic Analysis Lab

```bash
# Start security profile
./setup-podman-lab.sh --profile sec

# Connect network tools to LAN
./setup-podman-lab.sh lan-enable network-capture --lan-interface en0
./setup-podman-lab.sh lan-enable nmap-tools --lan-interface en0

# Check status
./setup-podman-lab.sh lan-status

# Run network scan from nmap-tools
podman exec -it nmap-tools nmap -sn 192.168.1.0/24

# Capture traffic from network-capture
podman exec -it network-capture bash
sudo tcpdump -i eth1 host 192.168.1.100
```

### Example 2: Web Development with LAN Access

```bash
# Start with infrastructure profile
./setup-podman-lab.sh --profile infra

# Connect web-server to LAN
./setup-podman-lab.sh lan-enable web-server --lan-interface en0

# Get LAN IP
./setup-podman-lab.sh lan-status
# Note the web-server LAN IP (e.g., 192.168.1.150)

# Add your website files
echo "<h1>Hello LAN!</h1>" > ~/PodmanData/web-data/index.html

# Access from phone/tablet on same network
# http://192.168.1.150:8080
```

### Example 3: Kubernetes/Docker Testing with LAN

```bash
# Start with ansible-control on LAN
./setup-podman-lab.sh --components ansible-control --lan-mode --lan-interface en0

# Check LAN IP
./setup-podman-lab.sh lan-status

# SSH into ansible-control from another machine
ssh dev@<lan-ip>  # password: dev

# Run playbooks against LAN devices
ansible-playbook -i lan-inventory.yml deploy.yml
```

## Additional Resources

- [Podman Networking Documentation](https://docs.podman.io/en/latest/markdown/podman-network.1.html)
- [Macvlan Driver Details](https://docs.docker.com/network/macvlan/)
- [Container Networking Basics](https://docs.podman.io/en/latest/networking.html)
