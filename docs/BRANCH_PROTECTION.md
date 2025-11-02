# Branch Protection Rules

This document outlines the recommended branch protection rules for the `main` branch to maintain code quality and prevent accidental issues.

## Recommended Settings for `main` Branch

### How to Configure

1. Go to your repository on GitHub
2. Click **Settings** → **Branches**
3. Under "Branch protection rules", click **Add rule**
4. Set the branch name pattern to: `main`
5. Configure the following settings:

### Protection Rules

#### ✅ Require Pull Request Reviews Before Merging
- **Enable this rule**: ✅
- **Required approving reviews**: 1
- **Dismiss stale pull request approvals**: ✅
- **Require review from Code Owners**: ❌ (optional, enable if you add a CODEOWNERS file)
- **Restrict who can dismiss pull request reviews**: ❌ (for small teams)

**Rationale**: Ensures all changes are reviewed before merging, reducing bugs and maintaining code quality.

#### ✅ Require Status Checks to Pass Before Merging
- **Enable this rule**: ✅
- **Require branches to be up to date before merging**: ✅

**Required status checks** (select all that apply):
- `ShellCheck`
- `Bash Syntax Check`
- `Test Light Build`
- `Test Profile Validation`
- `Completions Check`
- `Version Consistency`
- `Pre-commit Checks`

**Rationale**: Prevents merging code that fails tests or quality checks.

#### ✅ Require Conversation Resolution Before Merging
- **Enable this rule**: ✅

**Rationale**: Ensures all review comments are addressed before merging.

#### ✅ Require Signed Commits
- **Enable this rule**: ❌ (Optional - recommended for security-conscious projects)

**Rationale**: Verifies commit authenticity. Enable if security is a top priority, but may add friction for contributors.

#### ✅ Require Linear History
- **Enable this rule**: ✅

**Rationale**: Keeps git history clean and easy to follow. Use squash or rebase merging.

#### ✅ Require Deployments to Succeed Before Merging
- **Enable this rule**: ❌ (Not applicable for this project)

#### ✅ Lock Branch (Make Read-only)
- **Enable this rule**: ❌

**Rationale**: Main should accept PRs. Only enable this if you want to freeze development.

#### ✅ Do Not Allow Bypassing the Above Settings
- **Enable this rule**: ✅ (Recommended)
- **Allow force pushes**: ❌
- **Allow deletions**: ❌

**Rationale**: Prevents accidentally pushing directly to main or force-pushing, even by administrators.

#### ⚙️ Rules Applied to Administrators
- **Include administrators**: ✅

**Rationale**: Ensures even maintainers follow the same quality standards.

### Merge Strategy

Configure preferred merge method in **Settings** → **General** → **Pull Requests**:

**Recommended settings**:
- **Allow squash merging**: ✅ (Preferred)
  - Default commit message: "Pull request title and description"
  - This keeps history clean
- **Allow merge commits**: ✅ (If you prefer)
- **Allow rebase merging**: ✅ (Alternative to squash)
- **Automatically delete head branches**: ✅

## Complete Configuration Example

```
Branch name pattern: main

☑️ Require a pull request before merging
   ☑️ Require approvals: 1
   ☑️ Dismiss stale pull request approvals when new commits are pushed
   ☐ Require review from Code Owners
   ☐ Restrict who can dismiss pull request reviews
   ☐ Allow specified actors to bypass required pull requests
   ☑️ Require approval of the most recent reviewable push

☑️ Require status checks to pass before merging
   ☑️ Require branches to be up to date before merging

   Status checks that are required:
   • ShellCheck
   • Bash Syntax Check
   • Test Light Build
   • Test Profile Validation
   • Completions Check
   • Version Consistency
   • Pre-commit Checks

☑️ Require conversation resolution before merging

☐ Require signed commits (Optional)

☑️ Require linear history

☐ Require deployments to succeed before merging

☑️ Do not allow bypassing the above settings
   ☐ Allow force pushes (Leave UNCHECKED)
      ☐ Everyone
      ☐ Specify who can force push
   ☐ Allow deletions (Leave UNCHECKED)

☑️ Rules applied to everyone including administrators
```

## Additional Recommendations

### 1. CODEOWNERS File (Optional)

Create `.github/CODEOWNERS` if you want specific people to automatically review certain files:

```
# Main script requires review from maintainer
/setup-podman-lab.sh @krisarmstrong

# Workflows require review
/.github/workflows/ @krisarmstrong

# Security files require review
/SECURITY.md @krisarmstrong
```

### 2. Tag Protection (Optional)

Protect version tags from deletion:

1. Go to **Settings** → **Tags** → **Add tag protection rule**
2. Tag pattern: `v*`
3. This prevents accidental deletion of release tags

### 3. Enable GitHub Advanced Security (For Public Repos)

Free for public repositories:

1. **Settings** → **Security & analysis**
2. Enable:
   - ✅ Dependency graph
   - ✅ Dependabot alerts
   - ✅ Dependabot security updates
   - ✅ Secret scanning

### 4. Rulesets (Modern Alternative)

GitHub now offers "Rulesets" as a more flexible alternative to branch protection rules:

1. Go to **Settings** → **Rules** → **Rulesets**
2. Click **New ruleset** → **New branch ruleset**
3. Configure similar rules as above with more granular control

**Advantages**:
- Can target multiple branches with patterns
- Better status check management
- More detailed bypass permissions

## Testing Branch Protection

After setting up, test the rules:

1. Try to push directly to `main`:
   ```bash
   git checkout main
   echo "test" >> README.md
   git commit -am "test: direct push"
   git push origin main
   ```
   **Expected**: Push should be rejected

2. Try to force push:
   ```bash
   git push --force origin main
   ```
   **Expected**: Force push should be rejected

3. Create a PR without passing checks:
   - Create a branch with failing ShellCheck
   - Open PR
   **Expected**: Merge button should be disabled

4. Create a PR with all checks passing:
   - Create a feature branch
   - Make valid changes
   - Open PR
   - Wait for CI to pass
   **Expected**: Merge button should be enabled after approval

## Troubleshooting

### "Merge button disabled even with passing checks"

**Possible causes**:
1. Branch is not up to date with main (rebase/merge main)
2. Not all required status checks have run
3. Approval requirement not met
4. Unresolved conversations

### "Can't push even though I'm an admin"

If "Include administrators" is enabled, even admins must follow the rules. To bypass temporarily:
1. Disable "Include administrators"
2. Make your push
3. Re-enable immediately

**Warning**: Only do this in emergencies. Always prefer following the standard PR process.

### "Status check never completes"

1. Check GitHub Actions tab for workflow failures
2. Verify workflow is configured to run on PR events
3. Ensure the status check name in settings matches the workflow job name exactly

## Monitoring

Regularly review:
- **Insights** → **Network**: Check for force pushes or unusual activity
- **Settings** → **Branches**: Verify rules are still in place
- **Actions** → **Workflows**: Monitor CI/CD success rate

## Summary

These branch protection rules ensure:
- ✅ All code is reviewed
- ✅ All tests pass before merge
- ✅ Clean git history
- ✅ No accidental direct pushes
- ✅ Consistent code quality

Set them up once, and they'll protect your main branch automatically!
