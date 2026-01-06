# Runner Guard Secret Setup

**Status**: Required for `runner-version-guard.yml` workflow to function

## Problem

The `runner-version-guard.yml` workflow calls GitHub's org runners API:
```
GET /orgs/{org}/actions/runners
```

**GitHub API requirement**: This endpoint requires **admin access to the organization**.

The default `GITHUB_TOKEN` provided to workflows **does NOT** have this permission, even with `permissions: actions: read`.

## Solution: Create GitHub App or PAT

### Option 1: GitHub App (Recommended)

**Least privilege, auditable, no user dependency**

1. **Create GitHub App**:
   - Settings → Developer settings → GitHub Apps → New GitHub App
   - Name: `TAGS Runner Audit`
   - Organization permissions:
     - Self-hosted runners: **Read-only** ✅
   - Where can this GitHub App be installed? **Only on this account**
   - Install on: `theangrygamershowproductions`

2. **Generate Installation Token**:
   ```bash
   # Get app installation ID
   gh api /orgs/theangrygamershowproductions/installation
   
   # Generate token (expires in 1 hour, auto-refresh in workflow)
   gh api --method POST \
     -H "Accept: application/vnd.github+json" \
     /app/installations/{installation_id}/access_tokens
   ```

3. **Add Secret to Organization**:
   - Settings → Secrets and variables → Actions → New organization secret
   - Name: `ORG_RUNNER_READ_TOKEN`
   - Value: Installation token from step 2
   - Repository access: **Public repositories** (tags-workflows is public)

### Option 2: Personal Access Token (Classic)

**Simpler but tied to user account**

1. **Create Classic PAT**:
   - Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token
   - Note: `TAGS Runner Audit`
   - Expiration: **No expiration** (or 1 year with calendar reminder)
   - Scopes:
     - `admin:org` → `read:org` ✅
     - `repo` (if private repos need to use workflow)

2. **Add Secret to Organization**:
   - Settings → Secrets and variables → Actions → New organization secret
   - Name: `ORG_RUNNER_READ_TOKEN`
   - Value: PAT from step 1
   - Repository access: **Public repositories**

### Option 3: Fine-Grained PAT (Future-Ready)

**Not yet supported for org runners API** (as of 2026-01-06)

GitHub's REST API docs show fine-grained tokens don't yet support org-level runner management. Use Option 1 or 2 until GitHub adds support.

## Verification

After adding secret:

1. **Trigger workflow manually**:
   ```bash
   gh workflow run runner-version-guard.yml --repo tags-workflows
   ```

2. **Check run logs**:
   - Should see: `Fetched 5 runners` (or your actual count)
   - Should NOT see: HTTP 403 or "Resource not accessible by integration"

3. **Verify enforcement**:
   - Check job output for compliant/warning/blocking runners
   - Confirm exit code matches expected state (0=pass, 1=fail)

## Security Notes

**Why this is safe**:
- Read-only access to runner list (no create/delete/modify)
- No repo access (unless specifically granted)
- Scoped to organization only
- Audit trail via GitHub App installation logs

**Rotation policy**:
- GitHub App tokens: Auto-refresh (expire after 1 hour)
- Classic PAT: Rotate annually or on personnel change
- Fine-grained PAT: When GitHub adds support, migrate to this

## Troubleshooting

### "Resource not accessible by integration"

**Cause**: Workflow using `GITHUB_TOKEN` instead of `ORG_RUNNER_READ_TOKEN`

**Fix**: Verify workflow has:
```yaml
env:
  GH_TOKEN: ${{ secrets.ORG_RUNNER_READ_TOKEN }}
```

### "Bad credentials"

**Cause**: Secret expired or invalid

**Fix**: Regenerate token and update secret

### "Not Found" (HTTP 404)

**Cause**: Token doesn't have `read:org` permission or org name is wrong

**Fix**: Verify token scopes and org name in workflow

## References

- [GitHub REST API: Self-hosted runners](https://docs.github.com/en/rest/actions/self-hosted-runners)
- [GitHub Apps: Installation access tokens](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-an-installation-access-token-for-a-github-app)
- [Using secrets in workflows](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
