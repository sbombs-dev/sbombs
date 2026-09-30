# Setup Instructions for Version Control & Deployment

This document provides step-by-step instructions for maintainers to configure GitHub, PyPI, npm, and the repository for the SBOMBS canary deployment system.

## Prerequisites

- Repository owner/admin access on GitHub
- Admin access to PyPI organization (or use OIDC)
- Admin access to npm organization (`@sbombs`)
- Ability to create/manage GitHub teams

---

## Step 1: Create GitHub Team & Assign Members

**Purpose:** Define who can approve changes to anchor packages

### Steps:

1. Go to GitHub repository → **Settings** → **Collaborators and teams**
2. Click **New team** (or navigate to https://github.com/orgs/YOUR-ORG/teams)
3. Create team: `@sbombs/maintainers`
4. Add appropriate members (1-3 trusted maintainers recommended)
5. Assign team permission: **Maintain** (allows PR review and push)

**Verify:**
```bash
# Confirm CODEOWNERS references the correct team
grep "sbombs/maintainers" .github/CODEOWNERS
```

---

## Step 2: Configure Branch Protection Rules

**Purpose:** Enforce approval requirements for critical paths

### Steps:

1. Go to **Settings** → **Branches**
2. Click **Add rule** under "Branch protection rules"
3. Fill in settings:
   - **Branch name pattern:** `main`
   - **Require a pull request before merging:** ✅ Checked
   - **Require approvals:** ✅ Checked (set to 1)
   - **Require code owner approval:** ✅ Checked
   - **Dismiss stale pull request approvals when new commits are pushed:** ✅ Checked
   - **Allow force pushes:** ❌ Unchecked (for this branch)
   - **Allow deletions:** ❌ Unchecked

4. Scroll down and click **Create**

### Optional: Enforce status checks

After the first successful workflow run:

1. Return to branch protection settings
2. Enable **Require status checks to pass before merging**
3. Check the status checks from CI workflows (e.g., `publish-nightly`)

**Verify:**
```bash
# Push a test branch and try to commit directly to main (should fail)
git checkout -b test-push
git push origin test-push  # OK
git push origin test-push:main  # Should be rejected
```

---

## Step 3: Configure PyPI Trusted Publishing (OIDC)

**Purpose:** Enable secure, token-free publishing to PyPI

### For Existing Organization:

1. Go to PyPI → **Account settings** → **Publishing** (or https://pypi.org/manage/account/)
2. Scroll to **Trusted publishers**
3. Click **Add a new trusted publisher**
4. Select **GitHub**
5. Fill in fields:
   - **GitHub repository owner:** `YOUR-ORG` (or `YOUR-USERNAME` for personal)
   - **Repository name:** `sbombs.packages`
   - **Workflow filename:** `.github/workflows/daily.yml` (or `yearly.yml` for anchor)
   - **Environment name:** (leave blank for now)

6. Click **Add trusted publisher**
7. **Repeat for `yearly.yml` workflow** and each package name

### Verify PyPI Configuration:

```bash
# List trusted publishers (requires PyPI login)
# Go to https://pypi.org/manage/account/publishing and view the list
```

---

## Step 4: Configure npm Trusted Publishing (OIDC)

**Purpose:** Enable secure, token-free publishing to npm

### For npm Organization (@sbombs):

1. Go to npm → **Settings** → **Access tokens**
   - Or: https://www.npmjs.com/settings/YOUR-ORG/tokens

2. Depending on npm's current setup:

   **Option A: Using automation tokens (current standard)**
   - Create a new automation token: **Settings** → **Tokens** → **New token**
   - Type: `Automation`
   - Copy the token
   - Add to GitHub secrets: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**
   - Name: `NPM_TOKEN`
   - Value: (paste token)

   **Option B: Using npm OIDC (beta/newer)**
   - Enable OIDC: https://docs.npmjs.com/cli/v9/using-npm/security-best-practices#use-automation-tokens-for-automation
   - Configure workflow to use `npm config set --auth-type=legacy`

### Verify npm Configuration:

```bash
# Test locally (if you have npm access)
npm config set //registry.npmjs.org/:_authToken=$NPM_TOKEN
npm whoami  # Should show your npm user

# Then unset the token
npm config delete //registry.npmjs.org/:_authToken
```

---

## Step 5: Create GitHub Secrets (if not using OIDC)

**Purpose:** Store registry credentials for CI workflows

### Steps:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add secrets:
   - **Name:** `NPM_TOKEN` | **Value:** (npm automation token)
   - (Optional) **Name:** `PYPI_TOKEN` | **Value:** (PyPI API token, if not using OIDC)

**Important:** 
- Never commit these secrets
- Don't paste them into issues or logs
- Rotate regularly (at least annually)

---

## Step 6: Configure Workflow Permissions

**Purpose:** Allow workflows to create Git tags and GitHub releases

### Steps:

1. Go to **Settings** → **Actions** → **General**
2. Under "Workflow permissions":
   - **Default permissions:** `Read and write permissions` ✅
   - **Allow GitHub Actions to create and approve pull requests:** ✅ (optional, for advanced workflows)

3. Click **Save**

---

## Step 7: Set Up Environments (Optional, for Staged Deployments)

**Purpose:** Require manual approval before publishing (extra safety for anchor)

### Steps:

1. Go to **Settings** → **Environments**
2. Click **New environment**
3. Name: `production` (or `yearly` for anchor-specific)
4. Configure deployment branches:
   - **Deployment branches:** `main`
5. Under "Required reviewers": Add 2-3 maintainers
6. Click **Save protection rules**

### Update Workflow:

In `.github/workflows/yearly.yml`, add to the `publish-anchor` job:

```yaml
environment:
  name: yearly
  url: https://pypi.org/project/sbombs-yearly
```

This requires manual approval before anchor publishing.

---

## Step 8: Test Nightly Workflow (Dry Run)

**Purpose:** Verify workflow runs successfully before first production publish

### Option A: Manual trigger (recommended for first test)

1. Go to **Actions** → **Publish Canary Nightly**
2. Click **Run workflow** → **Run workflow** (button)
3. Watch the job output
4. Verify:
   - ✅ Python/Node packages build successfully
   - ✅ Version is computed correctly (today's UTC date)
   - ✅ Git tag is created and pushed
   - ✅ GitHub Release is created

### Option B: Local dry run with `act`

```bash
# Install act (GitHub Actions local runner)
brew install act  # or: https://github.com/nektos/act

# Run nightly workflow locally
act schedule -j publish-nightly

# Verify the output (won't actually publish, just runs steps)
```

### Verification:

After workflow completes:

1. Check GitHub **Releases** page for new release entry
2. Verify Git tag: `git tag -l "daily@*"`
3. Check PyPI: https://pypi.org/project/sbombs-daily/ (may take 5-10 min)
4. Check npm: https://www.npmjs.com/package/@sbombs/daily (may take 5-10 min)

---

## Step 9: Schedule Nightly Workflow

**Purpose:** Enable automatic daily publishing

### Steps:

The workflow is already configured in `.github/workflows/daily.yml`:

```yaml
on:
  schedule:
    - cron: '0 6 * * *'  # 06:00 UTC daily
```

This is active as soon as the file is merged to `main`. No additional setup needed.

### Verify Scheduling:

GitHub automatically enables cron schedules once the workflow is in the default branch.

1. Go to **Actions** → **Publish Canary Nightly**
2. Look for "scheduled" entries in the workflow run history

---

## Step 10: Test Anchor Workflow (Manual, One-Time)

**Purpose:** Verify anchor workflow before the one-time production publish

### Steps:

1. Create a test branch: `git checkout -b test/anchor-workflow`
2. (Optional) Update `.github/workflows/yearly.yml` to publish to **test registries** instead:
   - PyPI: https://test.pypi.org/
   - npm: Use Verdaccio or local registry

3. Trigger manually:
   - Go to **Actions** → **Publish Canary Anchor (Manual, One-Time)**
   - Click **Run workflow**
   - Input `confirm_anchor`: Type `yes`
   - Watch the job

4. Verify anchor was published to test registries:
   - PyPI: https://test.pypi.org/project/sbombs-yearly/
   - npm: Check Verdaccio console

5. **Do NOT merge this test branch to `main`**. Instead, **revert** the registry URLs back to production.

6. Create a **second** PR with the production URLs and merge it.

### Important:

- **After the first merge to main, do not run the anchor workflow again** (it's one-time only)
- The workflow explicitly prevents re-publishing (checks for existing `yearly@*` tags)

---

## Step 11: Document Deployment Runbook

**Purpose:** Provide a reference for future deployments

Create a `RUNBOOK.md` (or update this document) with:

- How to manually trigger workflows
- How to handle failed publishes
- How to verify packages in public registries
- How to investigate issues with specific versions
- Emergency rollback procedures (if any)

Example:

```markdown
## Emergency: Need to republish a version

**For daily (daily):**
- Cannot republish same version (each day has one version)
- Wait for next day or manually trigger with `workflow_dispatch`

**For yearly (one-time):**
- Do NOT republish
- If there's an issue with the published version, it's permanent
- Document the issue and plan a new major version for the next anchor
```

---

## Step 12: Enable Local Dev Setup

**Purpose:** Help contributors set up their local environment

Distribute these instructions:

```bash
# Clone the repository
git clone https://github.com/YOUR-ORG/sbombs.packages.git
cd sbombs.packages

# Set up dev environment (installs hooks, dependencies)
./setup-dev-env.sh

# Run tests
uv sync
uv run pytest

# Read the docs
cat VERSION_CONTROL.md
cat CONTRIBUTING.md
```

---

## Verification Checklist

Before going live, verify all components:

- [ ] GitHub team `@sbombs/maintainers` created and populated
- [ ] Branch protection rules enabled on `main`
- [ ] Code owner approval required for yearly paths
- [ ] PyPI OIDC trusted publishers configured (or token in secrets)
- [ ] npm automation token in GitHub secrets (or OIDC configured)
- [ ] Workflow permissions set to "Read and write"
- [ ] Nightly workflow tested successfully (manual trigger)
- [ ] Version computed correctly (UTC date format)
- [ ] Git tag created and pushed
- [ ] GitHub Release created
- [ ] Anchor workflow tested (on test branch or test registry)
- [ ] Anchor safety checks working (prevents re-run)
- [ ] Pre-commit hook installed locally (`./setup-dev-env.sh`)
- [ ] Documentation read and understood by team

---

## Common Issues & Fixes

### Issue: "PyPI authentication failed"

**Fix:**
1. Verify OIDC is correctly configured in PyPI settings
2. Check workflow has `id-token: write` permission
3. Verify GitHub repository name matches PyPI trusted publisher config

```yaml
permissions:
  id-token: write  # ← Required for OIDC
```

### Issue: "npm publish failed: Not Found"

**Fix:**
1. Verify `NPM_TOKEN` is set in GitHub secrets
2. Verify npm organization (`@sbombs`) exists and token has access
3. Verify `package.json` has correct `name`: `"@sbombs/daily"`

### Issue: "Git tag already exists"

**Fix:**
- For nightly: Just wait for next day; each day gets a new version
- For anchor: DO NOT re-run; one-time publish only
- To force delete a tag (use with extreme caution):
  ```bash
  git tag -d daily@YYYY.M.D
  git push origin :refs/tags/daily@YYYY.M.D
  ```

### Issue: "Workflow 'workflow_dispatch' not available"

**Fix:**
1. Ensure workflow file is in `.github/workflows/` directory
2. Ensure `on: workflow_dispatch:` is at the top level of the workflow
3. Merge changes to `main` branch
4. Wait ~5 minutes for GitHub to index the workflow
5. Refresh the Actions page

---

## Next Steps

1. **Review** this document with the team
2. **Execute** each step in order
3. **Test** nightly and anchor workflows
4. **Document** any deviations from this guide
5. **Schedule** first automatic nightly publish
6. **Plan** first anchor publish

---

## Support & Questions

- See [VERSION_CONTROL.md](./VERSION_CONTROL.md) for versioning details
- See [CONTRIBUTING.md](./CONTRIBUTING.md) for development guidelines
- See [agents.md](./agents.md) for project rules
- See [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) for technical overview

---

**Last updated:** September 29, 2026  
**Status:** Ready for implementation
