# Workflow Consumption SOP

**Version**: 1.0  
**Created**: 2025-03-05  
**Status**: Active

## Overview

This document defines the Standard Operating Procedure for consuming reusable workflows from the `tags-workflows` repository across the TAGS ecosystem.

## Architecture Principle

**Single Source of Truth**: All shared workflows live ONLY in `tags-workflows`. Consuming repositories reference workflows via SHA-pinned calls, never duplicate workflow files.

## Consumption Pattern

### SHA-Pinned Reference (Required)

```yaml
# In consuming repository's .github/workflows/docs.yml
name: Documentation Quality

on:
  pull_request:
    paths:
      - '**.md'
  push:
    branches:
      - main
    paths:
      - '**.md'

jobs:
  docs-governance:
    uses: theangrygamershowproductions/tags-workflows/.github/workflows/docs-governance.yml@<COMMIT-SHA>
    with:
      markdownlint_config: ".markdownlint.json"
      vale_config: ".vale.ini"
      check_links: true
      skip_vale: false
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Finding the Correct SHA

```bash
# Get latest commit SHA from tags-workflows main branch
cd ~/TAGS/ecosystem/tags-workflows
git fetch origin main
git log origin/main -n 1 --pretty=format:"%H"

# Or use GitHub CLI
gh api repos/theangrygamershowproductions/tags-workflows/commits/main --jq .sha
```

### Version Pinning Policy

**Per ACTIONS_POLICY.md**:
- Workflow references MUST use full commit SHA (not branch name or tag)
- NPM package installations MUST use version pinning (e.g., `@0.21.0`)
- Future enhancement: lockfile approach for stronger reproducibility

## Consuming Repositories

**Current consumers of `docs-governance.yml`**:

1. **DevOnboarder** - Full-stack app documentation
2. **TAGS-META** - Ecosystem-wide docs
3. **core-instructions** - Pattern library and templates
4. **tags-mcp-servers** - MCP server documentation
5. **AI-CI-Toolkit** - CI/CD integration docs
6. **website** - Business presence docs

**Planned consumers** (as markdownlint configs are distributed):
- onpoint-amenities
- beaumont-labs
- learning/* (educational repos)
- infrastructure/*

## Workflow Configuration

### Available Inputs

| Input                 | Type    | Required | Default              | Description                 |
| --------------------- | ------- | -------- | -------------------- | --------------------------- |
| `vale_config`         | string  | No       | `.vale.ini`          | Path to Vale configuration  |
| `markdownlint_config` | string  | No       | `.markdownlint.json` | Path to markdownlint config |
| `check_links`         | boolean | No       | `true`               | Enable markdown-link-check  |
| `skip_vale`           | boolean | No       | `false`              | Skip Vale prose linting     |

### Required Secrets

| Secret     | Purpose                                |
| ---------- | -------------------------------------- |
| `GH_TOKEN` | GitHub token for API access (optional) |

## Update Procedure

When `tags-workflows` is updated:

1. **Review Changes**: Check commit history and release notes
   ```bash
   cd ~/TAGS/ecosystem/tags-workflows
   git log --oneline origin/main -n 10
   ```

2. **Test Locally**: Verify workflow changes don't break consuming repos
   ```bash
   # Run workflow validation
   gh workflow view docs-governance.yml
   ```

3. **Update Consumer References**: Create PRs in each consuming repo to update SHA
   ```yaml
   # Old
   uses: theangrygamershowproductions/tags-workflows/.github/workflows/docs-governance.yml@abc123def

   # New
   uses: theangrygamershowproductions/tags-workflows/.github/workflows/docs-governance.yml@xyz789fed
   ```

4. **Coordinate Rollout**: See `ROLLOUT_PROCEDURE.md` for migration strategy

## Benefits of Centralized Workflows

✅ **No Drift**: Single source of truth eliminates configuration divergence  
✅ **DRY Principle**: Update once, consumed everywhere  
✅ **Consistent Tooling**: All repos use same markdownlint version and rules  
✅ **Simplified Maintenance**: Fewer files to track, easier auditing  
✅ **Policy Enforcement**: Centralized location for SHA pinning compliance

## Troubleshooting

### Workflow Not Found

**Symptom**: `Error: Unable to resolve action theangrygamershowproductions/tags-workflows/.github/workflows/docs-governance.yml@<SHA>`

**Causes**:
1. SHA doesn't exist (check: `git log origin/main | grep <SHA>`)
2. Workflow file renamed or moved
3. Repository permissions issue

**Solution**: Verify SHA exists and update reference

### Version Mismatch

**Symptom**: Local `markdownlint-cli2` version differs from CI

**Cause**: Consumer repo has different version in `package.json`

**Solution**: Local dev versions are independent; CI uses centralized workflow version (`0.21.0`)

### Configuration Not Found

**Symptom**: `markdownlint-cli2` can't find `.markdownlint.json`

**Cause**: Missing config file in consuming repo

**Solution**: Copy DevOnboarder's `.markdownlint.json` to consuming repo (see `ROLLOUT_PROCEDURE.md`)

## References

- **ACTIONS_POLICY.md**: `/home/chad/TAGS/ACTIONS_POLICY.md` - SHA pinning requirements
- **Rollout Procedure**: `.github/ROLLOUT_PROCEDURE.md` - Migration strategy
- **Workflow Source**: `.github/workflows/docs-governance.yml` - Current implementation
- **DevOnboarder Config**: `/home/chad/TAGS/ecosystem/DevOnboarder/.markdownlint.json` - Golden standard (16 rules)

## Revision History

| Date       | Version | Changes              |
| ---------- | ------- | -------------------- |
| 2025-03-05 | 1.0     | Initial SOP creation |

