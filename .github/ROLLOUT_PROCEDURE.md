# Markdownlint-cli2 v0.21.0 Rollout Procedure

**Version**: 1.0  
**Created**: 2025-03-05  
**Status**: Active  
**Context**: Ecosystem-wide standardization on markdownlint-cli2 v0.21.0

## Rollout Overview

This procedure documents the phased rollout of markdownlint-cli2 v0.21.0 and DevOnboarder's strict configuration (16 rules) across the TAGS ecosystem.

## Phase 1: Centralized Workflow + Core Repos (Current)

**Goal**: Establish version-pinned baseline in centralized workflow and update core development repos

### Step 1.1: Update Centralized Workflow ✅

**File**: `.github/workflows/docs-governance.yml`

**Change**:
```yaml
# Before
npm install -g markdownlint-cli2

# After
npm install -g markdownlint-cli2@0.21.0
```

**Policy Compliance**: Version pinning per ACTIONS_POLICY.md (compliant)  
**Status**: COMPLETE

### Step 1.2-1.3: Documentation ✅

**Files**:
- `.github/WORKFLOW_CONSUMPTION_SOP.md`
- `.github/ROLLOUT_PROCEDURE.md` (this file)

**Status**: COMPLETE

### Step 1.4: TAGS Root package.json

**File**: `/home/chad/TAGS/package.json`

**Change**:
```json
{
  "devDependencies": {
    "markdownlint-cli2": "0.21.0"  // Changed from 0.20.0
  }
}
```

**Commands**:
```bash
cd /home/chad/TAGS
# Edit package.json
npm install  # Update package-lock.json
git add package.json package-lock.json
```

**Note**: Local dev only; CI uses centralized workflow

### Step 1.5: core-instructions Migration

**File**: `/home/chad/TAGS/ecosystem/core-instructions/package.json`

**Changes**:
```json
{
  "devDependencies": {
    "markdownlint-cli2": "0.21.0"  // Changed from markdownlint-cli@0.37.0
  },
  "scripts": {
    "lint:md": "markdownlint-cli2 **/*.md",  // Changed from markdownlint
    "lint:md:fix": "markdownlint-cli2 **/*.md --fix"
  }
}
```

**Commands**:
```bash
cd /home/chad/TAGS/ecosystem/core-instructions
# Edit package.json
npm install  # Update package-lock.json
git add package.json package-lock.json
```

**Significance**: Migrates from old CLI to new CLI2 (tool compatibility fix)

### Step 1.6: TAGS Root Config Explicitness

**File**: `/home/chad/TAGS/.markdownlint-cli2.yaml`

**Change**: Add config reference
```yaml
# Add at top of file
config: ".markdownlint.json"

# Existing ignores remain unchanged
gitignore: true
ignores:
  - "**/node_modules/**"
  # ... etc
```

**Why**: Makes config inheritance explicit (currently implicit via cli2 defaults)

### Step 1.7: DevOnboarder Duplicate Cleanup

**File**: `/home/chad/TAGS/ecosystem/DevOnboarder/.markdownlint-ignore`

**Action**: Delete (duplicate of `.markdownlintignore`)

**Commands**:
```bash
cd /home/chad/TAGS/ecosystem/DevOnboarder
rm .markdownlint-ignore  # Keep .markdownlintignore
git add .markdownlint-ignore
```

**Verification**:
```bash
# Should only find one ignore file
ls -la | grep markdownlint
# Expected: .markdownlintignore only
```

## Phase 2: Config Distribution to 8 Repos

**Goal**: Extend DevOnboarder's strict config (16 rules) to repos currently lacking markdownlint setup

### Repos Requiring Config Distribution

1. **AI-CI-Toolkit** - `/home/chad/TAGS/ecosystem/AI-CI-Toolkit`
2. **tags-mcp-servers** - `/home/chad/TAGS/ecosystem/tags-mcp-servers`
3. **tags-qa-framework** - `/home/chad/TAGS/ecosystem/tags-qa-framework`
4. **website** - `/home/chad/TAGS/website/theangrygamershowproductions.com`
5. **onpoint-amenities** - `/home/chad/TAGS/clients/onpoint-amenities`
6. **beaumont-labs** - `/home/chad/TAGS/clients/beaumont-labs`
7. **learning/*** - Multiple repos under learning category
8. **infrastructure/*** - Multiple repos under infrastructure category

### Distribution Template

**For each repo, copy these files from DevOnboarder**:

```bash
REPO_PATH="/home/chad/TAGS/ecosystem/<REPO_NAME>"  # Replace with actual path
DEVONBOARDER="/home/chad/TAGS/ecosystem/DevOnboarder"

# 1. Copy strict config (16 rules)
cp "$DEVONBOARDER/.markdownlint.json" "$REPO_PATH/"

# 2. Copy CLI2 yaml config
cp "$DEVONBOARDER/.markdownlint-cli2.yaml" "$REPO_PATH/"

# Optional: Copy ignore file if repo has special ignore needs
# cp "$DEVONBOARDER/.markdownlintignore" "$REPO_PATH/"

# 3. Update package.json (if exists)
cd "$REPO_PATH"
npm install --save-dev markdownlint-cli2@0.21.0

# 4. Add npm scripts (if package.json exists)
# Add these manually:
# "lint:md": "markdownlint-cli2 **/*.md"
# "lint:md:fix": "markdownlint-cli2 **/*.md --fix"

# 5. Create .github/workflows/docs.yml to consume centralized workflow
# See WORKFLOW_CONSUMPTION_SOP.md for template
```

### DevOnboarder Config Reference (Golden Standard)

**Rules Enabled** (16 total):
- MD001: heading-increment
- MD003: heading-style (atx)
- MD004: ul-style (dash)
- MD005: list-indent
- MD007: ul-indent (spaces: 2)
- MD009: no-trailing-spaces
- MD010: no-hard-tabs
- MD011: no-reversed-links
- MD012: no-multiple-blanks
- MD014: commands-show-output
- MD018: no-missing-space-atx
- MD019: no-multiple-space-atx
- MD022: blanks-around-headings
- MD023: heading-start-left
- MD024: no-duplicate-heading (siblings_only)
- MD031: blanks-around-fences

**Why These Rules**: Balance between strictness and practicality; catches common errors without being overly pedantic

## Phase 3: Lower-Priority Repos (Future)

**Repos**:
- Studio275
- Automation bots
- Learning projects (non-critical)
- Infrastructure experimental repos

**Strategy**: Apply same config distribution as Phase 2, but lower priority (after Core 4 Hardening complete)

## Phase 4: Validation & Lockfile Upgrade (Future Enhancement)

### Validation Checklist

**After Phase 1-3 rollout**:

✅ All repos using markdownlint-cli2 (v0.21.0)  
✅ No repos using old markdownlint-cli  
✅ CI workflows version-pinned consistently  
✅ DevOnboarder's 713 markdown errors resolved  
✅ No new errors introduced in other repos

### Lockfile Upgrade (Optional Enhancement)

**Goal**: Stronger reproducibility via package-lock.json integrity hashes

**Requires**: ACTIONS_POLICY.md update (deliberate policy change)

**Procedure**:
1. Create `/home/chad/TAGS/ecosystem/tags-workflows/.github/tooling/markdownlint/package.json`
2. Run `npm install markdownlint-cli2@0.21.0` (generates lock file)
3. Update workflow to `npm ci` instead of `npm install -g`
4. Update ACTIONS_POLICY.md replacement note
5. Test across consuming repos
6. Deploy via PR with policy update

**Status**: Not started (Phase 1 version pinning is policy-compliant)

## Testing Strategy

### Pre-Rollout Validation

**Before each phase**:

```bash
# 1. Verify markdownlint version
markdownlint-cli2 --version  # Should show 0.21.0

# 2. Test config on DevOnboarder (known 713 errors)
cd /home/chad/TAGS/ecosystem/DevOnboarder
markdownlint-cli2 "**/*.md" | wc -l
# Expected: 713 errors (baseline)

# 3. Test config on TAGS Root (should have fewer errors)
cd /home/chad/TAGS
markdownlint-cli2 "**/*.md" | wc -l
```

### Post-Rollout Validation

**After distribution to each repo**:

```bash
cd /home/chad/TAGS/ecosystem/<REPO>

# 1. Run linter locally
npm run lint:md
# Document error count (may be non-zero initially)

# 2. Verify CI picks up changes
git push origin feat/markdownlint-v0.21.0
# Check GitHub Actions for docs-governance workflow

# 3. Compare error counts
# Expected: DevOnboarder's strict rules may reveal new issues
# Action: Fix or document (don't weaken rules)
```

## Rollback Procedure

**If critical issues arise during rollout**:

### Immediate Rollback

```bash
cd /home/chad/TAGS/ecosystem/tags-workflows
git revert <COMMIT-SHA>  # Revert workflow change
git push origin main

# Consuming repos will continue using old SHA reference
# No immediate action needed in consuming repos
```

### Gradual Rollback

```bash
# For specific consuming repo having issues
cd /home/chad/TAGS/ecosystem/<REPO>

# Revert workflow reference to previous SHA
# Edit .github/workflows/docs.yml
# Change back to old SHA
```

## Communication Plan

**Stakeholders**: TAGS development team, consuming repo maintainers

**Rollout Announcement**:
1. Update TAGS-META project board with rollout status
2. Create tracking issue: "Markdownlint-cli2 v0.21.0 Ecosystem Rollout"
3. Document in CHANGELOG.md for tags-workflows
4. Update consuming repos via individual PRs with clear descriptions

**Issue Template**:
```markdown
Title: FEAT(docs): upgrade to markdownlint-cli2 v0.21.0 (Phase X)

Body:
Part of ecosystem-wide standardization (tags-workflows#<ISSUE>)

Changes:
- Update package.json to markdownlint-cli2@0.21.0
- Copy DevOnboarder's strict config (16 rules)
- Update npm scripts to use cli2
- Create/update docs workflow to use centralized workflow

Testing:
- [ ] Local lint runs successfully
- [ ] CI docs-governance workflow passes
- [ ] Error count documented (baseline for future fixes)

Related: tags-workflows#<ISSUE>
```

## Success Criteria

### Phase 1 Complete When:
✅ tags-workflows workflow version-pinned @0.21.0  
✅ TAGS Root package.json updated  
✅ core-instructions migrated to cli2  
✅ Duplicate configs cleaned up  
✅ Documentation complete

### Phase 2 Complete When:
✅ All 8 target repos have DevOnboarder config  
✅ All repos pass local lint without errors OR errors documented  
✅ CI workflows consuming centralized workflow

### Full Rollout Complete When:
✅ All repos using cli2 v0.21.0  
✅ All repos using consistent rule set  
✅ DevOnboarder's 713 errors resolved (or documented as tech debt)  
✅ No drift between repos

## Contacts

**Questions**: TAGS Infrastructure Team  
**Issues**: Create GitHub issue in tags-workflows with label `rollout`  
**Governance**: See ACTIONS_POLICY.md for pinning requirements

## Revision History

| Date       | Version | Changes                   |
| ---------- | ------- | ------------------------- |
| 2025-03-05 | 1.0     | Initial rollout procedure |

