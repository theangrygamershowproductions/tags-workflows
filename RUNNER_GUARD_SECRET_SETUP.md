# Runner Guard Secret Setup

**Status**: Required for `runner-version-guard.yml` workflow to function

---

## ⚠️ GitHub Free Plan Limitation

**CRITICAL CONSTRAINT**: Organization-level Actions secrets **cannot be used by private repositories** on GitHub Free plan. ([Docs](https://docs.github.com/actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-an-organization))

**What this means**:
- If `tags-workflows` or other repos needing secrets are **private**, you MUST use **repo-level secrets** (not org-level)
- Org-level secrets are only accessible to **public repositories** on free plan
- To use org-level secrets with private repos, you must **upgrade to GitHub Team or Enterprise**

**Product separation**: GitHub secrets are scoped by product:
- **Actions** secrets: Used by GitHub Actions workflows (this doc)
- **Codespaces** secrets: Used inside Codespaces environments (separate)
- **Dependabot** secrets: Used by Dependabot updates (separate)
- **Private registries**: Security tooling registry access (separate)

These scopes do NOT cross over. Actions secrets are NOT available to Codespaces/Dependabot.

---

## Architectural Decision: Where Does Runner Guard Run?

**CRITICAL**: The secret storage approach depends on your execution model.

### Policy Option A: Self-Hosted-Only (Zero GitHub Secrets)

**Stance**: "Runner Guard is internal fleet control; if self-hosted runners are down, the audit doesn't run."

**Execution model**:
- Workflow forced to run on `self-hosted` + `host-tagsdev` labels
- Secrets stored in Bitwarden, retrieved via TAGS MCP stack
- GitHub-hosted runners CANNOT run this workflow (no bootstrap credential)

**Tradeoffs**:
- ✅ Zero GitHub secrets (entire auth stack in Bitwarden)
- ✅ Consistent with "internal control plane" philosophy
- ✅ **Unaffected by GitHub Free plan limitation** (no GitHub secrets used)
- ❌ When self-hosted fleet is down, audit can't run (no enforcement)
- ❌ Fails closed if fleet unavailable (expected behavior)

**Implementation**: See [Option A Configuration](#option-a-self-hosted-only-bitwarden)

---

### Policy Option B: Backup-Capable (Minimal GitHub Bootstrap)

**Stance**: "Runner Guard must work even when self-hosted runners are unavailable (notification/audit continuity)."

**Execution model**:
- Workflow can run on `ubuntu-latest` (GitHub-hosted) as fallback
- Minimal bootstrap secret (`BW_ACCESS_TOKEN`) stored in GitHub
- App credentials fetched from Bitwarden at runtime via `bitwarden/sm-action@v2`

**Tradeoffs**:
- ✅ Audit continues even when self-hosted fleet is down
- ✅ Secrets centralized in Bitwarden (GitHub only has bootstrap token)
- ❌ One GitHub secret required (`BW_ACCESS_TOKEN`)
- ⚠️ **GitHub Free constraint**: If repo is private, must use **repo-level secret** (not org-level)
- ❌ Requires Bitwarden Secrets Manager API access from GitHub-hosted runners

**Implementation**: See [Option B Configuration](#option-b-backup-capable-bitwarden-bootstrap)

---

### Decision Matrix

| Where Workflow Runs | Can Use TAGS MCP + Bitwarden-Only? | Requirements |
|----------------------|-----------------------------------|--------------|
| **Self-hosted runners (primary)** | ✅ Yes | No GitHub secrets required. Runner host authenticates to Bitwarden directly. |
| **GitHub-hosted runners (backup)** | ❌ No | Must store `BW_ACCESS_TOKEN` in GitHub secrets to bootstrap Bitwarden access. |
| **Public repos (fork PRs)** | ❌ No | Same as GitHub-hosted, plus fork/PR secret restrictions apply. |

**Physics constraint**: GitHub-hosted runners cannot access Bitwarden without a credential. This is not a policy choice—it's a bootstrap requirement.

**Governance callout**: If you configure GitHub-hosted as backup but DON'T provide bootstrap credentials, the workflow will:
- **Fail open** (unacceptable - no enforcement), or
- **Fail closed** (blocks pipelines unexpectedly when self-hosted is down)

Choose failure mode explicitly.

---

## Problem

The `runner-version-guard.yml` workflow calls GitHub's org runners API:
```
GET /orgs/{org}/actions/runners
```

**GitHub API requirement**: This endpoint requires **admin access to the organization**.

The default `GITHUB_TOKEN` provided to workflows **does NOT** have this permission, even with `permissions: actions: read`.

---

## Bootstrap Credential Architecture

**Two separate token worlds** (commonly confused):

1. **Bitwarden Secrets Manager (BWS) access token**
   - Purpose: Authenticate to Bitwarden to fetch secrets
   - Scoped by: Bitwarden machine account permissions
   - Used by: `bitwarden/sm-action@v2` or TAGS `tags-bitwarden` MCP server

2. **GitHub API auth token** (GitHub App installation token or PAT)
   - Purpose: Authenticate to GitHub org runner API
   - Scoped by: GitHub App permissions or PAT scopes
   - Used by: `gh` CLI or GitHub API calls

**Key insight**: A BWS token lets you *retrieve* GitHub App credentials from Bitwarden. You still need to *mint* an installation token from those credentials to call GitHub APIs.

### Where to Store Bootstrap Credentials

**If using Option B (backup-capable) with Bitwarden bootstrap**:

**GitHub Free plan**: Org-level secrets work for **public repos only**. For private repos, use repo-level secrets:

```bash
# PUBLIC repos: Org-level secret (centralized, preferred if available)
gh secret set BW_ACCESS_TOKEN \
  --org theangrygamershowproductions \
  --repos tags-workflows,tags-mcp-servers \
  --body "<BWS_ACCESS_TOKEN_VALUE>"

# PRIVATE repos on free plan: Repo-level secret (required workaround)
gh secret set BW_ACCESS_TOKEN \
  --repo theangrygamershowproductions/tags-workflows \
  --body "<BWS_ACCESS_TOKEN_VALUE>"

# Repeat for each private repo that needs the secret
gh secret set BW_ACCESS_TOKEN \
  --repo theangrygamershowproductions/tags-mcp-servers \
  --body "<BWS_ACCESS_TOKEN_VALUE>"
```

**Why org-level with repo restrictions** (public repos or paid plan) ([Docs](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-an-organization)):
- Centralized management (one secret, not per-repo duplication)
- Least privilege (restrict access to only repos that need it)
- Audit trail (org-level secret access logs)

**Why repo-level** (private repos on free plan):
- GitHub Free limitation: Org-level secrets cannot be used by private repos
- Per-repo secret management (manual duplication required)
- Same audit trail, but per-repo instead of org-level

**Alternative for private repos**: Upgrade to GitHub Team ($4/user/month) or Enterprise to enable org-level secrets for private repos. ([Pricing](https://github.com/pricing))

---

## Solution: GitHub App Authentication

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

---

## Option A: Self-Hosted-Only (Bitwarden)

**For Policy Option A: Zero GitHub secrets, self-hosted execution only**

### Prerequisites

- TAGS MCP stack operational on runner hosts
- `tags-bitwarden` server configured with Secrets Manager access
- App credentials stored in Bitwarden (not GitHub secrets)

### 1. Store App Credentials in Bitwarden

Using Bitwarden Secrets Manager, create secrets:

```bash
# Create Bitwarden secrets for Runner Guard
bw create item --organizationid <ORG_ID> --collectionid <COLLECTION_ID> \
  --name "ORG_RUNNER_APP_ID" \
  --notes "<APP_ID_VALUE>"

bw create item --organizationid <ORG_ID> --collectionid <COLLECTION_ID> \
  --name "ORG_RUNNER_APP_INSTALLATION_ID" \
  --notes "<INSTALLATION_ID_VALUE>"

bw create item --organizationid <ORG_ID> --collectionid <COLLECTION_ID> \
  --name "ORG_RUNNER_APP_PRIVATE_KEY" \
  --notes "<PRIVATE_KEY_PEM_CONTENTS>"
```

### 2. Configure Workflow for Self-Hosted-Only

Update `runner-version-guard.yml`:

```yaml
name: Runner Version Guard

on:
  schedule:
    - cron: '0 6 * * *'  # Daily 6 AM UTC
  workflow_dispatch:

jobs:
  audit-runners:
    runs-on: [self-hosted, host-tagsdev]  # Force self-hosted execution
    steps:
      - name: Fetch App credentials from Bitwarden
        id: bw-creds
        run: |
          # Use tags-bitwarden MCP server to fetch secrets
          APP_ID=$(tags-bitwarden get "ORG_RUNNER_APP_ID")
          INSTALLATION_ID=$(tags-bitwarden get "ORG_RUNNER_APP_INSTALLATION_ID")
          PRIVATE_KEY=$(tags-bitwarden get "ORG_RUNNER_APP_PRIVATE_KEY")
          
          echo "app-id=$APP_ID" >> $GITHUB_OUTPUT
          echo "installation-id=$INSTALLATION_ID" >> $GITHUB_OUTPUT
          # Private key written to temp file for JWT generation
          echo "$PRIVATE_KEY" > /tmp/runner-guard-key.pem
      
      - name: Generate installation token
        id: app-token
        run: |
          # Mint installation token using fetched credentials
          # (Implementation depends on TAGS auth stack)
          TOKEN=$(tags-authentication mint-github-token \
            --app-id "${{ steps.bw-creds.outputs.app-id }}" \
            --installation-id "${{ steps.bw-creds.outputs.installation-id }}" \
            --private-key /tmp/runner-guard-key.pem)
          
          echo "token=$TOKEN" >> $GITHUB_OUTPUT
          rm /tmp/runner-guard-key.pem  # Clean up private key
      
      - name: Fetch org runners
        env:
          GH_TOKEN: ${{ steps.app-token.outputs.token }}
        run: |
          gh api orgs/theangrygamershowproductions/actions/runners
```

### 3. Validate Self-Hosted Enforcement

Verify workflow CANNOT run on GitHub-hosted:

```bash
# Attempt to force GitHub-hosted runner (should fail with "No runner matching labels")
gh workflow run runner-version-guard.yml --repo tags-workflows \
  -f runs-on=ubuntu-latest
```

Expected: Workflow queues but never starts (no matching runner).

---

## Option B: Backup-Capable (Bitwarden Bootstrap)

**For Policy Option B: Minimal GitHub secret for backup execution**

### Prerequisites

- Bitwarden Secrets Manager access token with read access to Runner Guard secrets
- GitHub App credentials stored in Bitwarden (not GitHub directly)

### 1. Create Bitwarden Access Token

1. Navigate: Bitwarden Secrets Manager → Access Tokens
2. Create token with access to collection containing Runner Guard secrets
3. Copy token value (starts with `0.`)

### 2. Store Bootstrap Token in GitHub

**If tags-workflows is PUBLIC** or you have GitHub Team/Enterprise:

Navigate: `https://github.com/organizations/theangrygamershowproductions/settings/secrets/actions/new`

- **Name**: `BW_ACCESS_TOKEN`
- **Value**: Bitwarden access token from step 1
- **Repository access**: Select `tags-workflows` (and any other repos that need it)

```bash
# Org-level secret (public repos or paid plan)
gh secret set BW_ACCESS_TOKEN \
  --org theangrygamershowproductions \
  --repos tags-workflows \
  --body "0.YOUR_BWS_TOKEN_HERE"
```

**If tags-workflows is PRIVATE and you have GitHub Free**:

Navigate: `https://github.com/theangrygamershowproductions/tags-workflows/settings/secrets/actions/new`

- **Name**: `BW_ACCESS_TOKEN`
- **Value**: Bitwarden access token from step 1

```bash
# Repo-level secret (required for private repos on free plan)
gh secret set BW_ACCESS_TOKEN \
  --repo theangrygamershowproductions/tags-workflows \
  --body "0.YOUR_BWS_TOKEN_HERE"
```

**Note**: If you need this secret in multiple private repos on free plan, you must add it to each repo individually (no centralized org-level option).

### 3. Configure Workflow for Backup Execution

Update `runner-version-guard.yml`:

```yaml
name: Runner Version Guard

on:
  schedule:
    - cron: '0 6 * * *'
  workflow_dispatch:

jobs:
  audit-runners:
    runs-on: ubuntu-latest  # Can use GitHub-hosted OR self-hosted
    steps:
      - name: Fetch secrets from Bitwarden
        uses: bitwarden/sm-action@v2
        with:
          access_token: ${{ secrets.BW_ACCESS_TOKEN }}
          secrets: |
            ORG_RUNNER_APP_ID
            ORG_RUNNER_APP_INSTALLATION_ID
            ORG_RUNNER_APP_PRIVATE_KEY
      
      - name: Generate GitHub App installation token
        id: app-token
        uses: actions/create-github-app-token@31c86eb3b33c9b601a1f60f98dcbfd1d70f379b4  # v1.10.3
        with:
          app-id: ${{ env.ORG_RUNNER_APP_ID }}
          private-key: ${{ env.ORG_RUNNER_APP_PRIVATE_KEY }}
          owner: theangrygamershowproductions
      
      - name: Fetch org runners
        env:
          GH_TOKEN: ${{ steps.app-token.outputs.token }}
        run: |
          gh api orgs/theangrygamershowproductions/actions/runners
```

### 4. Validate Backup Capability

Test workflow on GitHub-hosted runner:

```bash
# Force GitHub-hosted execution
gh workflow run runner-version-guard.yml --repo tags-workflows

# Verify it completes successfully using Bitwarden bootstrap
```

**Security note**: `BW_ACCESS_TOKEN` is the only secret in GitHub. All other credentials (App ID, Installation ID, Private Key) remain in Bitwarden.

---

## Option C: OIDC Trust Bridge (Advanced)

**For zero static secrets in GitHub with GitHub-hosted runner support**

### Architecture

Use GitHub's OIDC identity provider to authenticate to TAGS infrastructure and fetch secrets dynamically:

```
GitHub-hosted runner → OIDC token → tags-authentication service → BWS access → GitHub App credentials
```

**Benefits**:
- Zero static secrets in GitHub (not even bootstrap token)
- Short-lived OIDC tokens (automatic rotation)
- Audit trail via OIDC claims + TAGS auth logs

**Tradeoffs**:
- Requires TAGS `tags-authentication` service exposed with OIDC trust
- Additional infrastructure (Cloudflare Tunnel or similar)
- More complex trust chain to debug

### Prerequisites

- `tags-authentication` server exposed over HTTPS with OIDC endpoint
- Trust policy configured: GitHub org → TAGS auth service
- BWS access delegation: TAGS auth can fetch secrets on behalf of OIDC identity

### 1. Configure GitHub OIDC Trust

Add to `runner-version-guard.yml`:

```yaml
jobs:
  audit-runners:
    runs-on: ubuntu-latest
    permissions:
      id-token: write  # Required for OIDC token request
      contents: read
    
    steps:
      - name: Authenticate to TAGS via OIDC
        id: tags-auth
        run: |
          # Request OIDC token from GitHub
          OIDC_TOKEN=$(curl -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
            "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=tags-authentication" | jq -r .value)
          
          # Exchange OIDC token for TAGS session
          TAGS_SESSION=$(curl -X POST https://auth.tags.internal/oidc/github \
            -H "Authorization: Bearer $OIDC_TOKEN" \
            -H "Content-Type: application/json" | jq -r .session_token)
          
          echo "session-token=$TAGS_SESSION" >> $GITHUB_OUTPUT
      
      - name: Fetch GitHub App credentials via TAGS
        id: fetch-creds
        env:
          TAGS_SESSION: ${{ steps.tags-auth.outputs.session-token }}
        run: |
          # Use TAGS session to fetch secrets from Bitwarden
          APP_ID=$(curl -H "Authorization: Bearer $TAGS_SESSION" \
            https://auth.tags.internal/secrets/ORG_RUNNER_APP_ID | jq -r .value)
          
          # ... fetch INSTALLATION_ID and PRIVATE_KEY similarly
          
          echo "app-id=$APP_ID" >> $GITHUB_OUTPUT
      
      - name: Generate GitHub App installation token
        id: app-token
        uses: actions/create-github-app-token@31c86eb3b33c9b601a1f60f98dcbfd1d70f379b4
        with:
          app-id: ${{ steps.fetch-creds.outputs.app-id }}
          private-key: ${{ steps.fetch-creds.outputs.private-key }}
          owner: theangrygamershowproductions
```

### 2. Configure TAGS Authentication OIDC Trust

In `tags-authentication` service configuration:

```yaml
oidc:
  providers:
    - name: github-actions
      issuer: https://token.actions.githubusercontent.com
      audience: tags-authentication
      trust_policy:
        - claim: repository_owner
          value: theangrygamershowproductions
        - claim: repository
          value: theangrygamershowproductions/tags-workflows
      permissions:
        - read_secret: ORG_RUNNER_APP_*
```

### 3. Verify OIDC Flow

Test OIDC authentication from workflow:

```bash
gh workflow run runner-version-guard.yml --repo tags-workflows

# Check logs for OIDC token exchange and secret fetch
```

**Security note**: OIDC tokens are short-lived (15 min default) and contain GitHub workflow context (repo, ref, actor). Trust policy validates these claims before granting access.

**Implementation status**: This option requires additional TAGS infrastructure deployment. Document here for future reference.

---

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

**Option A (Self-Hosted-Only)**:
- Zero GitHub secrets (entire auth stack in Bitwarden)
- Runner host must have TAGS MCP stack access
- Failure mode: Audit doesn't run when self-hosted fleet is down (expected)
- Audit trail: Bitwarden access logs + GitHub workflow logs
- **Bootstrap**: TAGS MCP stack on runner host (no GitHub credential)

**Option B (Backup-Capable with Bitwarden Bootstrap)**:
- One GitHub org secret: `BW_ACCESS_TOKEN` (Bitwarden bootstrap only)
- Org secret restricted to selected repos: `--repos tags-workflows,tags-mcp-servers`
- All sensitive credentials (App ID, Installation ID, Private Key) remain in Bitwarden
- Failure mode: Audit runs on GitHub-hosted when self-hosted unavailable (backup)
- Audit trail: GitHub secret access + Bitwarden API logs + workflow logs
- **Bootstrap**: Bitwarden access token stored as GitHub org secret

**Option C (OIDC Trust Bridge)**:
- Zero static secrets in GitHub (OIDC tokens are short-lived, 15 min)
- Requires TAGS `tags-authentication` service exposed with OIDC endpoint
- Trust policy validates GitHub workflow context (repo, ref, actor)
- Failure mode: Depends on TAGS auth service availability
- Audit trail: OIDC token claims + TAGS auth logs + Bitwarden API logs + workflow logs
- **Bootstrap**: GitHub OIDC identity + TAGS trust policy (no static secret)

**GitHub App model** (all options):
- Read-only access to runner list
- Installation tokens auto-expire (1h), no long-lived credentials in workflow
- Scoped to org, no user dependency

**PAT model** (Option 2 break-glass):
- Broader `admin:org` scope (can read more than just runners)
- Long-lived credential tied to user account
- User departure = token invalidation = workflow breakage

**Rotation policy**:
- GitHub App: Private key rotation on personnel change or compromise
- Classic PAT: Annual rotation or on personnel change
- Bitwarden bootstrap (`BW_ACCESS_TOKEN`): Rotate when access patterns change

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

---

## Decision Summary

**Choose your execution model explicitly** (don't let it be implicit):

| Option | GitHub Secrets | Supports GitHub-Hosted? | Additional Infra? | GitHub Free Constraint | Recommended For |
|--------|---------------|------------------------|------------------|----------------------|----------------|
| **A: Self-Hosted-Only** | Zero | ❌ No | TAGS MCP stack on runner hosts | ✅ Unaffected | Internal control plane; acceptable for audit to not run when fleet is down |
| **B: Bitwarden Bootstrap** | 1 secret (`BW_ACCESS_TOKEN`) | ✅ Yes | Bitwarden Secrets Manager | ⚠️ **Repo-level only** for private repos | Audit continuity when fleet is down; requires per-repo secret on free plan |
| **C: OIDC Bridge** | Zero | ✅ Yes | TAGS auth service exposed + OIDC trust | ✅ Unaffected | Advanced use case; zero static secrets; requires OIDC infrastructure |

**GitHub Free plan limitation**: If repo is **private**, org-level Actions secrets cannot be used. Options:
- Use **repo-level secrets** (Option B: manual duplication per repo)
- Use **Option A or C** (no GitHub secrets required)
- Upgrade to **GitHub Team** ($4/user/month) to enable org-level secrets for private repos

**TAGS recommendation**: 
1. **Start with Option A** (self-hosted-only, zero GitHub secrets) - unaffected by plan constraints
2. **Upgrade to Option B** if audit continuity during fleet outages required - accepts repo-level secret duplication on free plan
3. **Consider Option C** for long-term architecture when OIDC trust infrastructure is deployed - zero static secrets

**The physics constraint**: If you want GitHub-hosted runners to execute the workflow, **something** must bootstrap authentication (Bitwarden access token via GitHub secret, or OIDC identity via trust policy). Self-hosted-only is the only model that requires zero GitHub credentials.

---

## References

- [GitHub REST API: Self-hosted runners](https://docs.github.com/en/rest/actions/self-hosted-runners)
- [GitHub Apps: Installation access tokens](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-an-installation-access-token-for-a-github-app)
- [Using secrets in workflows](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Bitwarden GitHub Actions integration](https://bitwarden.com/help/github-actions-integration/)
