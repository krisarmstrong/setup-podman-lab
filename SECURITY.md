# Security Policy

## Intended Use

**Important**: This lab environment is designed for **local development, learning, testing, and security research only**. It is **not hardened for production use** and should **never be directly exposed to the internet** unless you are conducting authorized penetration testing and fully understand the risks.

The containers in this lab include:
- Security testing tools (Kali, OpenVAS/GVM, Nmap)
- Network analysis tools (Wireshark, packet capture)
- Development environments with permissive configurations
- Intentionally simplified credentials for ease of use

## Supported Versions

We release security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.6.x   | :white_check_mark: |
| < 0.6   | :x:                |

Security updates are applied to the latest release. We recommend always using the most recent version.

## Known Security Considerations

### Default Credentials
The lab uses simple, well-known default credentials for ease of use:
- Dev containers: `dev:dev`
- Kali desktop: `kali:kali`
- LibreNMS: `librenms:librenmspass`

**Action Required**: If you expose any of these services beyond localhost, **change these credentials immediately**.

### Network Exposure
By default, services bind to `localhost` only. This is intentional for security.

**Never expose these ports to public networks without:**
1. Changing all default credentials
2. Implementing proper authentication
3. Adding TLS/SSL encryption
4. Applying network segmentation
5. Understanding the full attack surface

### Container Privileges
Some containers (particularly networking and packet capture tools) may require elevated privileges or host network access to function properly. This is necessary for their operation but increases the attack surface.

### Security Tools
This lab includes offensive security tools (Kali, Nmap, vulnerability scanners). These tools should only be used:
- On networks you own or have explicit permission to test
- In isolated lab environments
- For educational purposes
- In compliance with all applicable laws and regulations

**You are responsible for the ethical and legal use of these tools.**

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in this project, please report it responsibly.

### Where to Report

**For security vulnerabilities**, please use GitHub's Security Advisories:

1. Go to the [Security Advisories page](https://github.com/krisarmstrong/setup-podman-lab/security/advisories)
2. Click "Report a vulnerability"
3. Fill out the form with details about the vulnerability

**Do not open public issues for security vulnerabilities.**

### What to Include

When reporting a vulnerability, please include:

1. **Description**: Clear description of the vulnerability
2. **Impact**: What an attacker could achieve
3. **Affected versions**: Which versions are affected
4. **Reproduction steps**: Step-by-step instructions to reproduce
5. **Proof of concept**: Code or commands demonstrating the issue (if applicable)
6. **Suggested fix**: If you have ideas for a fix (optional)
7. **Your environment**: OS, Podman version, etc.

### Response Timeline

- **Initial response**: Within 48 hours
- **Severity assessment**: Within 7 days
- **Fix timeline**: Depends on severity
  - Critical: 1-7 days
  - High: 7-14 days
  - Medium: 14-30 days
  - Low: 30-90 days

### Disclosure Policy

We follow **coordinated disclosure**:

1. You report the vulnerability privately
2. We confirm and assess severity
3. We develop and test a fix
4. We release the fix
5. We publish a security advisory
6. After 90 days (or when fix is released), details can be made public

### Bug Bounty

This is an open-source project maintained by volunteers. We do not currently offer a bug bounty program, but we will:

- Acknowledge your contribution in the security advisory (if you wish)
- Credit you in the CHANGELOG
- Thank you publicly (unless you prefer to remain anonymous)

## Security Best Practices for Users

### 1. Isolation
- Run the lab in an isolated environment (VM, separate network segment)
- Do not run on production systems
- Consider using a dedicated machine or cloud instance

### 2. Credentials
- Change default credentials if exposing services beyond localhost
- Use strong, unique passwords
- Consider using a password manager

### 3. Updates
- Keep Podman updated to the latest version
- Regularly rebuild containers to get base image updates
- Pull the latest version of this repository

### 4. Network Security
- Use firewall rules to restrict access
- Only expose necessary ports
- Consider VPN access for remote usage
- Monitor network traffic

### 5. Container Security
```bash
# Check for vulnerable base images
podman images

# Rebuild containers regularly
./setup-podman-lab.sh --build-only

# Review running containers
podman ps -a
```

### 6. Logging and Monitoring
- Review logs regularly: `~/logs/setup-podman-lab-*.log`
- Monitor container behavior: `podman logs <container>`
- Check for unexpected network connections

### 7. Cleanup
When finished testing:
```bash
./setup-podman-lab.sh teardown
```

This removes all containers, images, and data.

## Additional Resources

- [Podman Security Documentation](https://docs.podman.io/en/latest/markdown/podman-run.1.html#security-options)
- [Container Security Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [NIST Container Security Guide](https://www.nist.gov/publications/application-container-security-guide)

## Contact

For security concerns, use GitHub Security Advisories (preferred) or contact:
- GitHub: [@krisarmstrong](https://github.com/krisarmstrong)
- LinkedIn: [Kris Armstrong](https://www.linkedin.com/in/kris-armstrong)

For general questions (non-security), please open a regular GitHub issue.

---

**Remember**: With great power comes great responsibility. Use these tools ethically and legally.
