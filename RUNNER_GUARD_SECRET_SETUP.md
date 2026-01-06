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

**Auth model**: Store long-lived app credentials (App ID, Installation ID, Private Key) → mint short-lived installation tokens (1-hour expiry) at runtime.

#### What Runner Guard Needs

* **Token type**: Installation access token ([Docs](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-an-installation-access-token-for-a-github-app))
* **API surface**: List org self-hosted runners (read)
* **Permissions**: Organization → Self-hosted runners: **Read-only**

**We do NOT use**: OAuth, user authorization, device flow, webhooks, event subscriptions (scheduled audit, not event-driven).

#### 1. Create GitHub App (Org-Level)

**CRITICAL**: Create the app **under the organization's Developer Settings**, not your personal account. Personal apps set to "Only on this account" cannot install on the org.

Navigate: `https://github.com/organizations/theangrygamershowproductions/settings/apps/new`

**Required fields**:
- **GitHub App name**: `TAGS Runner Guard` (or `TAGS Runner Audit`)
- **Description**: `Audits org self-hosted runners and enforces fleet compliance labels.`
- **Homepage URL**: `https://github.com/theangrygamershowproductions/tags-workflows` (or org URL)

**Skip/disable these** (not needed for Runner Guard):
- **Callback URL**: Leave blank (no OAuth)
- **Expire user authorization tokens**: OFF
- **Request user authorization (OAuth) during installation**: OFF
- **Enable Device Flow**: OFF
- **Webhook → Active**: OFF (uncheck)
- **Webhook URL**: empty
- **Subscribe to events**: Select none

**Permissions** (only section that matters):
- **Organization permissions**:
  - **Self-hosted runners**: **Read-only** ✅
- All other permissions: **No access**

**Where can this GitHub App be installed?**:
- **Only on this account** (makes it a private org app)

Click **Create GitHub App**.

#### 2. Post-Creation Setup

After app creation:

1. **Generate Private Key**:
   - On app settings page → "Private keys" section → Generate a private key
   - Download `.pem` file → Save securely

2. **Install App on Organization**:
   - App settings page → Install App → Select `theangrygamershowproductions`
   - Confirm installation → Note the **Installation ID** from URL:
     ```
     https://github.com/organizations/theangrygamershowproductions/settings/installations/12345678
                                                                                    ^^^^^^^^ Installation ID
     ```

3. **Note App ID**:
   - App settings page → About section → **App ID** (e.g., 123456)

#### 3. Store App Credentials as Secrets

**CRITICAL**: Store app credentials (long-lived), NOT installation tokens (1h expiry).

Navigate: `https://github.com/organizations/theangrygamershowproductions/settings/secrets/actions/new`

Add 3 organization secrets:

- **Name**: `ORG_RUNNER_APP_ID`
  - **Value**: App ID from step 2.3 (e.g., `123456`)
  - **Repository access**: Public repositories (tags-workflows is public)

- **Name**: `ORG_RUNNER_APP_INSTALLATION_ID`
  - **Value**: Installation ID from step 2.2 (e.g., `12345678`)
  - **Repository access**: Public repositories

- **Name**: `ORG_RUNNER_APP_PRIVATE_KEY`
  - **Value**: Contents of `.pem` file from step 2.1 (starts with `-----BEGIN RSA PRIVATE KEY-----`)
  - **Repository access**: Public repositories

#### 4. Mint Token in Workflow

Update `runner-version-guard.yml` to mint installation token at runtime:

```yaml
jobs:
  audit-runners:
    runs-on: ubuntu-latest
    steps:
      - name: Generate GitHub App installation token
        id: app-token
        uses: actions/create-github-app-token@31c86eb3b33c9b601a1f60f98dcbfd1d70f379b4  # v1.10.3 (SHA-pinned)
        with:
          app-id: ${{ secrets.ORG_RUNNER_APP_ID }}
          private-key: ${{ secrets.ORG_RUNNER_APP_PRIVATE_KEY }}
          owner: theangrygamershowproductions
      
      - name: Fetch org runners
        env:
          GH_TOKEN: ${{ steps.app-token.outputs.token }}  # Use minted token (1h expiry)
        run: |
          gh api orgs/theangrygamershowproductions/actions/runners
```

**Auth flow summary** (automated by `actions/create-github-app-token`):
1. Generate JWT for app ([Docs](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app))
2. Exchange JWT for installation token via `POST /app/installations/{installation_id}/access_tokens` ([Docs](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-an-installation-access-token-for-a-github-app))
3. Use installation token (1h expiry, auto-refreshes on each workflow run)

#### Optional: Use App for Host Label Script

If you want `refresh_runner_labels.sh` to authenticate via GitHub App instead of PAT:

1. **Increase app permission**: Organization → Self-hosted runners: **Read & write**
2. **Mint token in host script** using `gh` CLI:
   ```bash
   # Requires: APP_ID, INSTALLATION_ID, PRIVATE_KEY_FILE as env vars
   JWT=$(gh api --method POST -H "Accept: application/vnd.github+json" \
     /app/installations/$INSTALLATION_ID/access_tokens \
     --jq .token)
   
   GH_TOKEN=$JWT gh api orgs/theangrygamershowproductions/actions/runners
   ```

### Option 2: Personal Access Token (Break-Glass Fallback)

**Simpler setup, but broader permissions and tied to user account**

**Note**: PATs that can manage org runners are inherently less constrained than App-based auth. Use this only if GitHub App setup is blocked or in emergency scenarios.

1. **Create Classic PAT**:
   - Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token
   - Note: `TAGS Runner Audit (Emergency)`
   - Expiration: **1 year** (set calendar reminder for rotation)
   - Required scopes:
     - `admin:org` → `read:org` ✅ (org runner list access)
     - `repo` (only if private repos need this workflow)

2. **Add Secret to Organization**:
   - Settings → Secrets and variables → Actions → New organization secret
   - Name: `ORG_RUNNER_READ_TOKEN`
   - Value: PAT from step 1
   - Repository access: **Public repositories**

3. **Use Directly in Workflow** (no token minting):
   ```yaml
   - name: Fetch org runners
     env:
       GH_TOKEN: ${{ secrets.ORG_RUNNER_READ_TOKEN }}  # Static PAT
     run: |
       gh api orgs/theangrygamershowproductions/actions/runners
   ```

**Rotation policy**: Rotate annually or on personnel change. PAT is tied to user account—if user leaves org, token breaks.

### Option 3: Fine-Grained PAT (Future-Ready)

**Not yet supported for org runners API** (as of 2026-01-06)

GitHub's REST API docs show fine-grained tokens don't yet support org-level runner management. Use Option 1 or 2 until GitHub adds support.

## Verification

After configuring secrets (GitHub App or PAT):

1. **Trigger workflow manually**:
   ```bash
   gh workflow run runner-version-guard.yml --repo theangrygamershowproductions/tags-workflows
   ```

2. **Check run logs**:
   - Should see: `Fetched 5 runners` (or your actual count)
   - Should see: `Online FLEET: 5 / 5` (if all runners have host-tagsdev or host-* labels)
   - Should NOT see: HTTP 403, HTTP 401, or "Resource not accessible by integration"

3. **Verify enforcement**:
   - Check workflow summary for compliant/warning/blocking counts
   - Confirm exit code: `0` (pass), `1` (blocking issues found)

## Security Notes

**GitHub App model** (Option 1):
- Read-only access to runner list
- Installation tokens auto-expire (1h), no long-lived credentials in secrets
- Audit trail via GitHub App installation logs
- Scoped to org, no user dependency

**PAT model** (Option 2):
- Broader `admin:org` scope (can read more than just runners)
- Long-lived credential tied to user account
- User departure = token invalidation = workflow breakage

**Rotation policy**:
- GitHub App: Private key rotation on personnel change or compromise
- Classic PAT: Annual rotation or on personnel change

## Troubleshooting

### "Resource not accessible by integration"

**Cause**: Workflow using default `GITHUB_TOKEN` instead of org-scoped token.

**Fix**: 
- GitHub App: Verify token minting step (`actions/create-github-app-token`) is present and outputs `token`
- PAT: Verify `GH_TOKEN: ${{ secrets.ORG_RUNNER_READ_TOKEN }}` is set in workflow

### "Bad credentials" (HTTP 401)

**Cause**: Secret expired, invalid, or missing.

**Fix**:
- GitHub App: Verify all 3 secrets exist (APP_ID, INSTALLATION_ID, PRIVATE_KEY)
- PAT: Regenerate token and update secret

### "Not Found" (HTTP 404)

**Cause**: Token doesn't have `read:org` permission, or org name is wrong.

**Fix**: 
- Verify token has correct scope (admin:org → read:org for PAT, Self-hosted runners: Read for App)
- Confirm org name in workflow matches `theangrygamershowproductions`

### "App installation not found"

**Cause**: GitHub App not installed on org, or Installation ID is incorrect.

**Fix**: 
- Reinstall app on org: App settings → Install App → Select org
- Update `ORG_RUNNER_APP_INSTALLATION_ID` secret with correct ID from installation URL

## References

- [GitHub REST API: Self-hosted runners](https://docs.github.com/en/rest/actions/self-hosted-runners)
- [GitHub Apps: Installation access tokens](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-an-installation-access-token-for-a-github-app)
- [Using secrets in workflows](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
