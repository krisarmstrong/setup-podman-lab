## Description

<!-- Provide a brief description of what this PR does -->

## Type of Change

<!-- Check all that apply -->

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement
- [ ] CI/CD improvement

## Motivation and Context

<!-- Why is this change required? What problem does it solve? -->
<!-- Link to related issue(s): Fixes #(issue) -->

## Changes Made

<!-- List the specific changes in this PR -->

-
-
-

## Affected Components

<!-- Check all components affected by this PR -->

- [ ] Main bootstrap script (`setup-podman-lab.sh`)
- [ ] Dev containers (ubuntu-dev, fedora-dev, etc.)
- [ ] Network tools (nmap, packet-analyzer, iperf, http-test)
- [ ] Security tools (kali-vnc, vulnerability-scanner)
- [ ] Monitoring stack (LibreNMS, MariaDB, SNMP)
- [ ] Build system / profiles
- [ ] Documentation
- [ ] CI/CD workflows
- [ ] Helper scripts

## Testing Performed

<!-- Describe the testing you've done -->

- [ ] Full build: `./setup-podman-lab.sh`
- [ ] Light build: `./setup-podman-lab.sh light`
- [ ] Profile-specific build: `./setup-podman-lab.sh --profile <name>`
- [ ] Component-specific build: `./setup-podman-lab.sh --components <list>`
- [ ] Teardown: `./setup-podman-lab.sh teardown`
- [ ] Smoke tests: `scripts/verify-lab.sh`
- [ ] ShellCheck: `shellcheck setup-podman-lab.sh`
- [ ] Manual verification of affected containers

## Test Environment

<!-- Provide details about your test environment -->

- **OS**: <!-- e.g., macOS 14.2, Ubuntu 22.04 -->
- **Podman Version**: <!-- output of `podman --version` -->
- **Platform**: <!-- macOS, Linux -->

## Console Output / Logs

<!-- If relevant, include console output or log snippets -->
<!-- Redact any sensitive credentials -->

```
# Paste relevant output here
```

## Documentation Updates

- [ ] README.md updated (if applicable)
- [ ] CONTRIBUTING.md updated (if guidelines changed)
- [ ] New access points documented (if services added)
- [ ] Default credentials documented (if changed/added)

## Security Considerations

<!-- Does this PR introduce any security implications? -->
<!-- Have you updated default credentials or network bindings? -->

- [ ] No security implications
- [ ] Security implications addressed (explain below)

<!-- If applicable, describe security changes -->

## Breaking Changes

<!-- Does this PR introduce any breaking changes? -->

- [ ] No breaking changes
- [ ] Breaking changes (describe migration path below)

<!-- If applicable, describe what users need to do to migrate -->

## Checklist

- [ ] My code follows the project's coding style (see CONTRIBUTING.md)
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have tested this on my local environment
- [ ] ShellCheck passes without warnings (or suppressions are justified)
- [ ] Generated Containerfiles are valid and build successfully
- [ ] Affected containers start and run as expected
- [ ] I have updated documentation as needed
- [ ] My changes generate no new warnings
- [ ] New and existing tests pass locally

## Additional Notes

<!-- Any additional information reviewers should know -->
