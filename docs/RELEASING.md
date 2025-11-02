# Release Process

## Daily Development (No More Rebasing!)

Semantic-release now only runs on tagged releases, so you can commit and push normally:

```bash
git add .
git commit -m "feat: add new feature"
git push origin main
```

No more rebase conflicts! 🎉

## Creating a Release

When you're ready to release a new version:

### 1. Check what's changed since last release

```bash
# See commits since last tag
git log $(git describe --tags --abbrev=0)..HEAD --oneline

# Or use GitHub CLI
gh release list --limit 1
```

### 2. Determine version bump

Based on conventional commits since last release:
- **Patch** (1.0.4 → 1.0.5): `fix:`, `docs:`, `chore:`, `refactor:`
- **Minor** (1.0.5 → 1.1.0): `feat:`
- **Major** (1.0.5 → 2.0.0): `BREAKING CHANGE:` in commit body

### 3. Create and push the tag

```bash
# Example: releasing v1.1.0
git tag v1.1.0
git push origin v1.1.0
```

### 4. Semantic-release will automatically:
- Calculate the version from commits
- Update VERSION file
- Update CHANGELOG.md
- Create GitHub release with notes
- Publish the release

### 5. Pull the changes back

```bash
git pull origin main
```

## Conventional Commit Format

Use these prefixes for proper version bumping:

```bash
# Patch release (bug fixes)
git commit -m "fix: resolve container startup issue"
git commit -m "docs: update README examples"
git commit -m "chore: update dependencies"

# Minor release (new features)
git commit -m "feat: add rust-dev container"
git commit -m "feat: implement LAN networking"

# Major release (breaking changes)
git commit -m "feat: redesign profile system

BREAKING CHANGE: Profile names have changed.
Use 'dev' instead of 'development'."
```

## Quick Reference

| Commit Type | Version Bump | Example |
|-------------|--------------|---------|
| `fix:` | Patch (0.0.1) | Bug fixes, small corrections |
| `feat:` | Minor (0.1.0) | New features, enhancements |
| `BREAKING CHANGE:` | Major (1.0.0) | Incompatible API changes |
| `docs:`, `chore:`, `refactor:` | Patch | No breaking changes |
| `test:`, `ci:`, `style:` | None | Development only |

## Example Release Workflow

```bash
# 1. Make changes and commit
git add .
git commit -m "feat: add cpp-dev container"
git commit -m "feat: implement Python version selection"
git commit -m "fix: resolve network-capture permissions"
git push origin main

# 2. When ready to release (say we're at v1.0.4)
# We have 2 feat commits = minor bump
# New version should be v1.1.0

git tag v1.1.0
git push origin v1.1.0

# 3. Watch the release workflow
gh run watch

# 4. Pull the automated changes
git pull origin main

# Done! Check the release
gh release view v1.1.0
```

## Checking Release Status

```bash
# View latest release
gh release view

# List recent releases
gh release list --limit 5

# Watch release workflow
gh run watch

# View workflow logs
gh run view --log
```
