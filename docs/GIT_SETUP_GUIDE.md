# Git Best Practices Setup Guide

This guide explains the git best practices that have been implemented and how to use them.

## What Was Added

### 📁 Directory Structure

```
.
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml          # Bug report template
│   │   ├── config.yml              # Issue template config
│   │   └── feature_request.yml     # Feature request template
│   ├── workflows/
│   │   ├── ci.yml                  # Continuous Integration
│   │   ├── pre-commit.yml          # Pre-commit checks
│   │   └── release.yml             # Automated releases
│   └── PULL_REQUEST_TEMPLATE.md    # PR template
├── docs/
│   ├── BRANCH_PROTECTION.md        # Branch protection guide
│   └── GIT_SETUP_GUIDE.md          # This file
├── .editorconfig                   # Editor configuration
├── .gitattributes                  # Git attributes
├── .markdownlint.json              # Markdown linting rules
├── .pre-commit-config.yaml         # Pre-commit hooks config
├── .releaserc.json                 # Semantic release config
├── CHANGELOG.md                    # Auto-generated changelog
├── CODE_OF_CONDUCT.md              # Community guidelines
├── CONTRIBUTING.md                 # Contribution guide
└── SECURITY.md                     # Security policy
```

## 🚀 Quick Start

### 1. Install Pre-commit Hooks (Recommended)

```bash
# Install pre-commit
pip install pre-commit

# Install the hooks
pre-commit install
pre-commit install --hook-type commit-msg

# Test it works
pre-commit run --all-files
```

Now every commit will be automatically checked for:
- ShellCheck issues
- Trailing whitespace
- YAML/JSON syntax
- Conventional commit format
- And more!

### 2. Configure Branch Protection

Follow the guide in [docs/BRANCH_PROTECTION.md](BRANCH_PROTECTION.md) to set up branch protection rules on GitHub.

### 3. Start Using Conventional Commits

From now on, use this format for commits:

```bash
# Features (bumps minor version)
git commit -m "feat: add support for custom registry mirrors"

# Bug fixes (bumps patch version)
git commit -m "fix: correct VNC port binding for Kali container"

# Documentation (bumps patch version)
git commit -m "docs: update installation instructions"

# Other types (no version bump)
git commit -m "chore: update dependencies"
git commit -m "test: add smoke tests for LibreNMS"
git commit -m "refactor: simplify build function"
```

## 🤖 Automated Versioning & Changelog

### How It Works

1. **You push to main** (via merged PR)
2. **GitHub Actions runs** the release workflow
3. **semantic-release analyzes** your commits
4. **Version is bumped** based on commit types:
   - `feat:` → Minor version (0.6.0 → 0.7.0)
   - `fix:`, `perf:`, `refactor:`, `docs:` → Patch (0.6.0 → 0.6.1)
   - `BREAKING CHANGE:` in body → Major (0.6.0 → 1.0.0)
5. **CHANGELOG.md is updated** automatically
6. **VERSION file is updated**
7. **Git tag is created** (v0.7.0)
8. **GitHub release is published**
9. **Changes are committed** back to main

### Example Workflow

```bash
# On your feature branch
git checkout -b feat/add-rust-dev-container

# Make changes
# ... edit setup-podman-lab.sh ...

# Commit with conventional format
git commit -am "feat: add Rust development container

This adds a new container with Rust toolchain, cargo,
and common development tools.

Closes #123"

# Push and create PR
git push origin feat/add-rust-dev-container

# Create PR on GitHub, get it reviewed and merged

# After merge to main, GitHub Actions will:
# - Bump version to 0.7.0 (new feature)
# - Update CHANGELOG.md
# - Create tag v0.7.0
# - Create GitHub release
```

### Breaking Changes

For breaking changes, add `BREAKING CHANGE:` in the commit body:

```bash
git commit -m "feat: restructure profile system

BREAKING CHANGE: Profile names have changed.
Old: --profile basic
New: --profile dev

Update your scripts to use the new profile names."

# This will bump from 0.6.0 → 1.0.0
```

## 📝 Contributing Workflow

### For Contributors

1. **Fork the repo** on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR-USERNAME/setup-podman-lab.git
   cd setup-podman-lab
   ```

3. **Install pre-commit** (optional but recommended):
   ```bash
   pip install pre-commit
   pre-commit install
   pre-commit install --hook-type commit-msg
   ```

4. **Create a feature branch**:
   ```bash
   git checkout -b feat/your-feature
   ```

5. **Make your changes** and commit with conventional format:
   ```bash
   git commit -m "feat: your feature description"
   ```

6. **Test locally**:
   ```bash
   # Run ShellCheck
   shellcheck setup-podman-lab.sh

   # Test build
   export PODMAN_LAB_ROOT="$PWD/lab-tmp"
   ./setup-podman-lab.sh light --build-only

   # Cleanup
   ./setup-podman-lab.sh teardown
   ```

7. **Push and create PR**:
   ```bash
   git push origin feat/your-feature
   ```

8. **Fill out the PR template** on GitHub

9. **Wait for CI checks** to pass

10. **Address review feedback** if any

11. **Merge** (maintainer will do this)

### For Maintainers

1. **Review the PR** using the checklist in the PR template

2. **Check CI status** - all checks must pass:
   - ShellCheck
   - Syntax check
   - Light build test
   - Pre-commit checks

3. **Approve and merge** using squash or rebase

4. **Release happens automatically** via GitHub Actions

## 🔍 CI/CD Workflows

### CI Workflow (`ci.yml`)

Runs on every push and PR to `main`:

- **ShellCheck**: Lints all shell scripts
- **Syntax Check**: Validates bash syntax
- **Light Build Test**: Builds light profile in sandbox
- **Profile Validation**: Tests profile help output
- **Completions Check**: Validates completion files
- **Version Check**: Ensures VERSION file is valid

### Pre-commit Workflow (`pre-commit.yml`)

Runs pre-commit hooks on all files:
- File formatting checks
- Trailing whitespace
- YAML/JSON validation
- ShellCheck
- Markdown linting

### Release Workflow (`release.yml`)

Runs on push to `main`:
- Analyzes commits since last release
- Determines version bump
- Updates CHANGELOG.md
- Updates VERSION file
- Creates git tag
- Publishes GitHub release

## 📋 Issue & PR Templates

### Creating Issues

When you create an issue, you'll see options:
- **Bug Report**: Structured form for reporting bugs
- **Feature Request**: Structured form for suggesting features
- **Security Vulnerability**: Link to GitHub Security Advisories

### Creating Pull Requests

The PR template includes:
- Description section
- Type of change checkboxes
- Affected components
- Testing checklist
- Documentation checklist
- Security considerations

## 🛡️ Security

### Reporting Vulnerabilities

**Never open public issues for security vulnerabilities.**

Instead:
1. Go to **Security** → **Advisories**
2. Click "Report a vulnerability"
3. Fill out the private security advisory

### Security Features

- Secret scanning enabled (for public repos)
- Dependency alerts via Dependabot
- Security policy in SECURITY.md

## 🎨 Code Quality Tools

### EditorConfig

`.editorconfig` ensures consistent formatting across editors:
- 2-space indentation for shell scripts
- LF line endings
- UTF-8 encoding
- Trim trailing whitespace

Most modern editors automatically detect and use this.

### Git Attributes

`.gitattributes` ensures:
- Consistent line endings (LF) across platforms
- Proper diff strategies for different file types
- Correct language detection on GitHub

### Pre-commit Hooks

`.pre-commit-config.yaml` runs checks before commits:
- File formatting
- ShellCheck
- YAML/JSON syntax
- Conventional commit format
- Markdown linting

## 📊 Monitoring

### Check Workflow Status

```bash
# View recent workflow runs
gh run list

# View specific workflow
gh run view <run-id>

# Watch a running workflow
gh run watch
```

### View Releases

```bash
# List releases
gh release list

# View specific release
gh release view v0.7.0
```

### Check Branch Protection

GitHub → Settings → Branches → View rules for `main`

## 🔧 Troubleshooting

### Pre-commit Failing Locally

```bash
# See what failed
pre-commit run --all-files --verbose

# Skip pre-commit for emergency commits (not recommended)
git commit --no-verify -m "fix: emergency fix"
```

### CI Failing on PR

1. Check the Actions tab for detailed logs
2. Run the same checks locally:
   ```bash
   shellcheck setup-podman-lab.sh
   pre-commit run --all-files
   ```
3. Fix issues and push again

### Release Not Triggering

1. Ensure commits use conventional format
2. Check if `[skip ci]` is in commit message
3. Verify release.yml workflow exists
4. Check GitHub Actions logs

### Version Not Bumping

Common reasons:
- No conventional commits since last release
- Only `chore:`, `test:`, or `style:` commits (no version bump)
- Commits don't follow conventional format

## 📚 Additional Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [GitHub Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [Pre-commit Documentation](https://pre-commit.com/)
- [Semantic Release](https://semantic-release.gitbook.io/)

## 🎯 Summary

You now have:

- ✅ **Automated versioning** based on commit messages
- ✅ **Auto-generated changelog** from commits
- ✅ **CI/CD pipelines** for testing and releases
- ✅ **Issue and PR templates** for consistency
- ✅ **Pre-commit hooks** for code quality
- ✅ **Branch protection** guidelines
- ✅ **Security policy** for vulnerability reporting
- ✅ **Contributing guide** for new contributors
- ✅ **Code of conduct** for community standards
- ✅ **Editor configuration** for consistent formatting

**Next Steps**:
1. Install pre-commit hooks locally
2. Set up branch protection on GitHub
3. Start using conventional commits
4. Watch the automation work! 🎉
