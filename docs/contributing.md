# Contributing to Podman Lab Bootstrap

## Welcome

Thank you for your interest in contributing to Podman Lab Bootstrap!

## Getting Started

### Prerequisites

- macOS 10.15+ or Linux (Ubuntu 20.04+, Fedora 35+)
- Bash 4.0 or higher
- Basic understanding of:
  - Podman/container technology
  - Shell scripting
  - Container networking
  - Containerfile syntax

### Setup

1. Clone the repository
2. Make the script executable:
   ```bash
   chmod +x setup-podman-lab.sh
   ```
3. Test in light mode first:
   ```bash
   PODMAN_LAB_ROOT="$PWD/lab-tmp" ./setup-podman-lab.sh light
   ```
4. Clean up after testing:
   ```bash
   PODMAN_LAB_ROOT="$PWD/lab-tmp" ./setup-podman-lab.sh teardown
   ```

## Development Workflow

### Making Changes

1. Create a new branch for your feature or fix
2. Make changes to `setup-podman-lab.sh`
3. Update relevant library files in `lib/`
4. Add or update Containerfiles as needed
5. Test changes thoroughly
6. Update documentation
7. Commit with clear, descriptive messages

### Code Standards

#### Shell Scripting Guidelines

- Follow existing code style and formatting
- Use meaningful variable names (uppercase for exports)
- Add comments for complex logic
- Use functions for reusable code
- Handle errors gracefully with proper exit codes
- Quote variables to prevent word splitting
- Use `set -euo pipefail` for safety

#### Containerfile Standards

- Use official base images when possible
- Minimize layer count
- Clean up package caches
- Document non-obvious steps
- Pin versions for reproducibility
- Follow best practices for security

### Testing

#### Local Testing

Test the complete workflow:
```bash
# Test light mode
PODMAN_LAB_ROOT="$PWD/lab-tmp" ./setup-podman-lab.sh light

# Verify containers running
podman ps

# Test container access
podman exec -it <container-name> /bin/bash

# Test teardown
PODMAN_LAB_ROOT="$PWD/lab-tmp" ./setup-podman-lab.sh teardown

# Verify cleanup
podman ps -a
ls lab-tmp/
```

#### Profile Testing

Test individual profiles:
```bash
# Test dev containers only
# (modify script to enable specific profiles)

# Test network tools
# Test security containers
# Test monitoring stack
```

#### Platform Testing

Test on multiple platforms:
- macOS (Intel and Apple Silicon)
- Ubuntu Linux
- Fedora Linux
- Other supported distributions

#### Resource Testing

Test with various configurations:
```bash
# Minimal resources
PODMAN_MACHINE_DISK_SIZE=40 ./setup-podman-lab.sh light

# Standard resources
./setup-podman-lab.sh

# High resources
PODMAN_MACHINE_DISK_SIZE=120 LAB_BUILD_CONCURRENCY=8 ./setup-podman-lab.sh
```

### Documentation

- Update README.md for new features
- Add comments in shell scripts
- Document new environment variables
- Include usage examples
- Update docs/ directory files
- Document container profiles

## Adding New Containers

### Container Addition Process

1. Create Containerfile in appropriate directory
2. Add build logic to main script
3. Configure networking and ports
4. Set up volumes if needed
5. Document credentials and access
6. Add to README.md
7. Test thoroughly

### Example Container Addition

```bash
# 1. Create Containerfile
cat > PodmanProjects/new-container/Containerfile << 'EOF'
FROM ubuntu:latest
RUN apt-get update && apt-get install -y newtool
USER newuser
CMD ["/bin/bash"]
EOF

# 2. Add to build script
# (add build and run commands)

# 3. Test
podman build -t new-container PodmanProjects/new-container
podman run -it new-container
```

## Library Files

### Modular Components

The `lib/` directory contains reusable functions:
- Platform detection
- Podman installation
- Container building
- Network configuration
- Error handling

### Adding Library Functions

1. Create or update file in `lib/`
2. Source in main script
3. Document parameters and return values
4. Add error handling
5. Test independently

## Testing Guidelines

### Unit Testing

Test individual functions:
- Platform detection
- Package installation
- Container building
- Network setup
- Volume mounting

### Integration Testing

Test complete workflows:
- Fresh installation
- Upgrade scenarios
- Teardown and cleanup
- Error recovery
- Resource constraints

### Performance Testing

Verify efficiency:
- Build time optimization
- Parallel build scaling
- Resource utilization
- Startup time
- Network performance

## Pull Request Process

1. Ensure all tests pass on supported platforms
2. Update CHANGELOG.md with changes
3. Update documentation
4. Test with both standard and light modes
5. Verify teardown works correctly
6. Submit PR with clear description
7. Include test results
8. Reference any related issues

## Version Management

### Versioning

Use semantic versioning in VERSION file:
- MAJOR: Breaking changes
- MINOR: New features
- PATCH: Bug fixes

### Release Process

1. Update VERSION file
2. Update CHANGELOG.md
3. Test on all supported platforms
4. Create git tag
5. Update documentation

## Container Profiles

### Profile Categories

- **dev**: Development environments
- **net**: Network tools
- **security**: Security utilities
- **monitoring**: Monitoring stack

### Adding New Profiles

1. Define profile in script
2. Add container definitions
3. Configure dependencies
4. Document usage
5. Test isolation

## Network Configuration

### Port Allocation

- Document port mappings
- Avoid conflicts
- Use standard ports when possible
- Document in README.md

### Network Isolation

- Configure bridges appropriately
- Document security implications
- Test inter-container communication

## Security Considerations

### Development vs Production

- Document default credentials clearly
- Warn against production use
- Provide hardening guidelines
- Follow security best practices

### Container Security

- Use minimal base images
- Update regularly
- Follow least privilege principle
- Document security considerations

## Platform-Specific Considerations

### macOS

- Test on both Intel and Apple Silicon
- Verify podman-mac-helper integration
- Test machine resource allocation
- Check native networking

### Linux

- Test on multiple distributions
- Verify rootful/rootless modes
- Check SELinux/AppArmor compatibility
- Test systemd integration

## Troubleshooting Contributions

### Debug Information

Include in bug reports:
- Platform and version
- Podman version
- Script output
- Error messages
- Resource allocation

### Reproducibility

Provide:
- Exact commands run
- Environment variables set
- Configuration used
- Steps to reproduce

## Questions?

Feel free to open an issue for questions or discussions.

---
Author: Kris Armstrong
