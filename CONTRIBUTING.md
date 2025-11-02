# Contributing to Podman Lab Bootstrap

First off, thanks for taking the time to contribute! 🎉

The following is a set of guidelines for contributing to this project. These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Workflow](#development-workflow)
- [Coding Guidelines](#coding-guidelines)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior through GitHub issues.

## Getting Started

### Prerequisites

- Podman installed (or let the script install it for you)
- macOS or Linux operating system
- Basic knowledge of Bash scripting
- Familiarity with containers (Podman/Docker)

### Setting Up Your Development Environment

1. **Fork the repository** on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR-USERNAME/setup-podman-lab.git
   cd setup-podman-lab
   ```

3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/krisarmstrong/setup-podman-lab.git
   ```

4. **Create a test environment**:
   ```bash
   export PODMAN_LAB_ROOT="$PWD/lab-tmp"
   ./setup-podman-lab.sh light
   ```

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected vs actual behavior**
- **Environment details** (OS, Podman version)
- **Log output** from `~/logs/setup-podman-lab-*.log`

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.yml) when creating issues.

### Suggesting Features

Feature requests are welcome! Before suggesting a feature:

- Check if it aligns with the project goals (dev/network/security lab tooling)
- Search existing issues to avoid duplicates
- Provide clear use cases and examples

Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.yml).

### Contributing Code

We love code contributions! Here are some areas where help is appreciated:

- **New containers**: Add development tools, security tools, or network utilities
- **Performance improvements**: Optimize build times or resource usage
- **Bug fixes**: Fix reported issues
- **Documentation**: Improve README, add examples, fix typos
- **Testing**: Improve test coverage, add smoke tests
- **Platform support**: Better Linux distro support

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions or changes
- `chore/` - Maintenance tasks

### 2. Make Your Changes

Follow the [coding guidelines](#coding-guidelines) below.

### 3. Test Your Changes

```bash
# Run ShellCheck
shellcheck setup-podman-lab.sh

# Test light build
export PODMAN_LAB_ROOT="$PWD/lab-tmp"
./setup-podman-lab.sh light --build-only

# Test full build (if changes affect all containers)
./setup-podman-lab.sh --build-only

# Test specific components
./setup-podman-lab.sh --components your-component --build-only

# Run smoke tests
scripts/verify-lab.sh

# Clean up
./setup-podman-lab.sh teardown
```

### 4. Commit Your Changes

Follow the [commit message guidelines](#commit-message-guidelines).

```bash
git add .
git commit -m "feat: add support for custom profiles"
```

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub using the [PR template](.github/PULL_REQUEST_TEMPLATE.md).

## Coding Guidelines

### Project Structure

- **Main script**: `setup-podman-lab.sh` - Primary orchestrator
- **Helper scripts**: `scripts/` - Verification and utility scripts
- **Completions**: `completions/` - Shell completion files
- **Runtime output**: `~/PodmanProjects/` - Generated Containerfiles (not in repo)
- **Persistent data**: `~/PodmanData/` - Volume mounts (not in repo)

### Bash Style Guide

#### Formatting
- **Indentation**: 2 spaces (no tabs)
- **Line length**: Aim for 80-100 characters
- **Functions**: Use `lower_snake_case` naming
- **Variables**: Use `UPPERCASE` for exported config, `lowercase` for local vars

#### Best Practices
```bash
# Good: POSIX-friendly, set -e compatible
if command -v podman >/dev/null 2>&1; then
  echo "Podman found"
fi

# Good: Use quotes around variables
local container_name="$1"
podman run "$container_name"

# Good: Explicit error handling
if ! podman build -t myimage .; then
  echo "Build failed" >&2
  return 1
fi

# Good: Use shellcheck suppressions sparingly, with comments
# shellcheck disable=SC2312
local result=$(complex_command)
```

#### ShellCheck
- Run `shellcheck setup-podman-lab.sh` before committing
- Fix all warnings or justify suppressions with inline comments
- Suppress warnings only when necessary

### Containerfile Guidelines

When adding new containers:

1. **Use explicit base images**:
   ```dockerfile
   FROM docker.io/ubuntu:22.04
   ```

2. **Document package installations**:
   ```dockerfile
   # Install development tools
   RUN apt-get update && apt-get install -y \
       build-essential \
       git \
       vim \
     && rm -rf /var/lib/apt/lists/*
   ```

3. **Create non-root users** (when appropriate):
   ```bash
   create_user_cmd() {
     echo "RUN useradd -m -s /bin/bash dev && echo 'dev:dev' | chpasswd"
   }
   ```

4. **Add comments** for atypical choices

### Adding New Components

When adding a new container component:

1. **Add to profile definitions** in `setup-podman-lab.sh`:
   ```bash
   case "$LAB_PROFILE" in
     dev)
       components="...,your-new-component"
       ;;
   esac
   ```

2. **Create build function**:
   ```bash
   build_your_component() {
     local project_dir="$1"
     # Implementation
   }
   ```

3. **Add to README.md**:
   - List in Features section
   - Add to Access Points (if applicable)
   - Document credentials (if any)
   - Update Common Commands

4. **Add to completions** (if it's a profile or commonly used component)

## Commit Message Guidelines

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automated versioning and changelog generation.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature (minor version bump)
- `fix`: Bug fix (patch version bump)
- `perf`: Performance improvement (patch version bump)
- `refactor`: Code refactoring (patch version bump)
- `docs`: Documentation changes (patch version bump)
- `style`: Code style changes (no version bump)
- `test`: Test changes (no version bump)
- `chore`: Maintenance tasks (no version bump)

### Scope (Optional)

Examples: `kali`, `librenms`, `ci`, `build`, `docs`

### Subject

- Use imperative mood ("Add feature" not "Added feature")
- Don't capitalize first letter
- No period at the end
- Limit to 50 characters

### Body (Optional)

- Explain what and why, not how
- Wrap at 72 characters

### Footer (Optional)

- Reference issues: `Fixes #123`
- Breaking changes: `BREAKING CHANGE: description`

### Examples

```bash
# Simple feature
feat: add Alpine Linux development container

# Bug fix with issue reference
fix: correct Kali VNC port binding

Fixes #42

# Breaking change
feat: restructure profile configuration

BREAKING CHANGE: --profile flag now requires explicit profile
names. The old behavior of accepting arbitrary values has been
removed. Use --components for custom container sets.

# Documentation update
docs: update macOS setup instructions

Add notes about podman-mac-helper installation and native
networking configuration for macOS users.
```

## Pull Request Process

### Before Submitting

- [ ] Code follows the style guidelines
- [ ] ShellCheck passes without warnings
- [ ] Tested locally (`light` or full build)
- [ ] Documentation updated (README, CONTRIBUTING.md if needed)
- [ ] Conventional commit format used
- [ ] PR template filled out completely

### PR Template

Use the provided [PR template](.github/PULL_REQUEST_TEMPLATE.md) and fill out:

- Description of changes
- Type of change
- Affected components
- Testing performed
- Test environment details
- Documentation updates

### Review Process

1. **Automated checks** will run (CI workflow)
2. **Maintainer review** - may request changes
3. **Approval** - once approved, changes can be merged
4. **Merge** - maintainer will merge when ready

### After Merge

- Your changes will be included in the next release
- Changelog will be automatically updated
- Version will be bumped based on commit type
- GitHub release will be created automatically

## Testing Guidelines

### Manual Testing Checklist

Before submitting a PR, test:

```bash
# 1. ShellCheck
shellcheck setup-podman-lab.sh scripts/*.sh

# 2. Light build (quick validation)
export PODMAN_LAB_ROOT="$PWD/lab-tmp"
./setup-podman-lab.sh light --build-only --verbose

# 3. Verify generated structure
ls -la $PODMAN_LAB_ROOT/PodmanProjects

# 4. Test specific component (if applicable)
podman build "$PODMAN_LAB_ROOT/PodmanProjects/your-component"

# 5. Test runtime (optional for small changes)
./setup-podman-lab.sh light --run-only

# 6. Verify container starts
podman ps | grep your-component

# 7. Smoke tests
scripts/verify-lab.sh

# 8. Cleanup
./setup-podman-lab.sh teardown
rm -rf $PODMAN_LAB_ROOT
```

### CI Checks

GitHub Actions will automatically run:
- ShellCheck validation
- Bash syntax check
- Light build test
- Profile validation
- Completions check
- Version consistency check

## Additional Resources

- [Project README](README.md)
- [Security Policy](SECURITY.md)
- [Changelog](CHANGELOG.md)
- [Podman Documentation](https://docs.podman.io/)

## Questions?

- Open a [GitHub Discussion](https://github.com/krisarmstrong/setup-podman-lab/discussions)
- Create an [issue](https://github.com/krisarmstrong/setup-podman-lab/issues)
- Check existing documentation

## Recognition

Contributors will be recognized in:
- CHANGELOG.md for their contributions
- GitHub contributors page
- Release notes (for significant contributions)

Thank you for contributing! 🚀
