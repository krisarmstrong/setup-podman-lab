# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2](https://github.com/krisarmstrong/setup-podman-lab/compare/v1.0.1...v1.0.2) (2025-11-02)


### Bug Fixes

* exclude zsh and fish completions from shellcheck ([7b24b4a](https://github.com/krisarmstrong/setup-podman-lab/commit/7b24b4ad788f26a341bbff73aa92cad767b029f0))

## [1.0.1](https://github.com/krisarmstrong/setup-podman-lab/compare/v1.0.0...v1.0.1) (2025-11-02)


### Bug Fixes

* disable problematic pre-commit hooks ([979fa1d](https://github.com/krisarmstrong/setup-podman-lab/commit/979fa1dc8509713a6687c61a692cc40586bd248b))

## 1.0.0 (2025-11-02)


### Bug Fixes

* resolve pre-commit issues ([3ac27b3](https://github.com/krisarmstrong/setup-podman-lab/commit/3ac27b348090ce7c0d82712652eb24e9b3e97bf7))

## [0.6.2] - 2024-10-31

### Added
- Registry mirror support via `LAB_REGISTRY_MIRROR` environment variable
- Offline mode checks and `LAB_OFFLINE_MODE` flag
- Shell completions for bash, zsh, and fish
- Automatic rewriting of hostless images to use registry mirrors

### Changed
- Improved Docker Hub login warnings and registry checks

## [0.6.1] - 2024-10-30

### Added
- Rebuild and rerun command support
- Registry login check to warn users about Docker Hub rate limits

### Changed
- Refined profile behavior and warning messages for Docker Hub authentication

## [0.6.0] - 2024-10-30

### Added
- Component filtering with `--components` flag
- Parallel build support via `LAB_BUILD_CONCURRENCY`
- Quiet build controls with `--quiet` and `--verbose` flags
- Profile-based deployment (dev, net, sec, monitor)
- Build-only and run-only modes (`--build-only`, `--run-only`)

### Changed
- Refactored lab bootstrap into modular helper functions
- Added comprehensive logging with timestamped log files
- Version detection and tracking

### Fixed
- GVM container switched to accessible GHCR image

## Earlier Versions

Previous versions did not maintain a structured changelog. See git history for details.

---

**Note**: Starting from this point forward, releases will be automatically managed by semantic-release, and this changelog will be automatically updated based on conventional commit messages.

### Commit Message Format

To trigger automatic releases and changelog generation, use conventional commit format:

- `feat: description` - New feature (minor version bump)
- `fix: description` - Bug fix (patch version bump)
- `perf: description` - Performance improvement (patch version bump)
- `refactor: description` - Code refactoring (patch version bump)
- `docs: description` - Documentation changes (patch version bump)
- `chore: description` - Maintenance tasks (no version bump)
- `test: description` - Test changes (no version bump)

Add `BREAKING CHANGE:` in the commit body for major version bumps.

Example:
```
feat: add support for custom container profiles

This allows users to define their own container sets
beyond the predefined dev/net/sec/monitor profiles.

BREAKING CHANGE: The --profile flag now requires explicit
profile names instead of accepting arbitrary values.
```
