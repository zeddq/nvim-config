# Linear Integration – Security Audit & Setup Guide

## Summary

A security audit of this repository was performed to identify what may be
blocking [Linear](https://linear.app) from accessing `zeddq/nvim-config`.

---

## Findings

### 1. Linear GitHub App is not installed (primary blocker)

The Linear GitHub App must be explicitly installed and granted access to each
repository it should monitor. Without this, Linear has no way to read or write
to the repository, regardless of any other settings.

**How to fix:**

1. Go to <https://github.com/apps/linear> (or
   <https://github.com/marketplace/linear>) and click **Install**.
2. Select the `zeddq` account.
3. Under *Repository access*, choose **Only select repositories** and add
   `nvim-config`.
4. Click **Save**.

If the app was previously installed but lost access, navigate to
**GitHub → Settings → Applications → Installed GitHub Apps → Linear → Configure**
and re-add the repository.

---

### 2. Branch protection rules are enabled on all branches

All five branches (`main`, `copilot/check-security-settings`,
`coderabbitai/utg/e8f349e`, `cezary/jj-neovim-fixer`, `mid-fixes-and-qol`)
have branch protection enabled. If the *"Restrict pushes that create matching
branches"* or *"Require signed commits"* settings are active, Linear's bot
will be unable to:

- Create feature branches from Linear issues.
- Push commits to protected branches.

**How to fix for `main`:**

1. Go to **Repository → Settings → Branches → Edit rule for `main`**.
2. Under *"Restrict pushes"*, add the **Linear** GitHub App to the allowed list
   (or switch to the *"Allow specified actors to bypass required pull requests"*
   bypass list).
3. If *"Require signed commits"* is checked, uncheck it — GitHub Apps cannot
   sign commits with GPG.

---

### 3. Code scanning and secret scanning

The code scanning and secret scanning APIs returned `403 Resource not
accessible by integration`, which means these features are either:

- Not enabled (most likely for a personal Neovim config repo), or
- Enabled but the integration lacks the `security_events` scope.

This does **not** block Linear's core functionality (issue sync, branch
linking). No action is required here unless you want to enable these features.

---

## Required GitHub-side Actions (checklist for the repo owner)

- [ ] Install the Linear GitHub App and grant it access to `nvim-config`
      (<https://github.com/apps/linear>)
- [ ] If you use the *"Create branch from Linear issue"* feature, add the
      Linear app to the branch-protection bypass list for `main`
- [ ] If *"Require signed commits"* is enabled on `main`, disable it so that
      Linear's bot can create commits

---

## Repository-level changes made in this PR

- Created this `.github/LINEAR_INTEGRATION.md` security-audit document.
- No code or configuration was changed — all required fixes are
  GitHub account/settings UI actions listed above.
