# tags-workflows - Deployment Guide

## Authority & Scope

**Binding Sources**: Root TAGS CORE-6 + DEC-014
**Classification**: Derived execution document (public lane deployment)
**Allowed Changes**: Deployment procedures, workflow contract details, local validation
**NOT Allowed Without Root ADR**: Lane scope (public/GitHub-hosted), trust boundary, runner model
**Note**: Root TAGS-META defines lane architecture. This guide executes the public/untrusted CI lane per DEC-014. 

## Complete walkthrough for deploying tags-workflows

**Estimated Time**: 2-4 hours per migration wave | **Complexity**: Intermediate | **Authority**: Root TAGS-META CORE-6 + DEC-014 + local validation scripts

---

## Overview

This guide covers deploying tags-workflows (public/untrusted CI lane, GitHub-hosted runners). You'll:

- harden public/untrusted reusable workflow contracts
- migrate public consumers by matrix wave
- validate contract behavior and cut over with rollback controls

**What you'll have when done**: a validated public shared workflow platform with matrix-tracked migrations and immutable SHA references.

---

## Current vs Target Architecture

### ⚙️ CURRENT STATE (Phase 0)

CORE-6 structure exists and reusable workflow baseline is present, but public/untrusted CI consumer matrix execution and migration evidence are incomplete.

**Known Gaps**:

- matrix rows for public/untrusted CI consumers are not fully populated with wave and status
- shared contract conformance checks are not yet tied to every migration task

**This is what you're implementing in this guide.**

### 🎯 TARGET STATE (Phase 1+)

This repository operates as the canonical public/untrusted reusable workflow source, with all mapped consumers migrated through validated waves and immutable SHA references.

**Remediation Required**:

- complete public/untrusted CI matrix and execute Waves 1-3
- pass contract and cutover gates by roadmap milestone windows

---

## Prerequisites

### Required Tools

- GitHub CLI (`gh`) latest stable
- Bash with standard GNU tooling (`jq`, `grep`, `sed`)

### Required Access

- Access to consumer repositories in public/untrusted CI migration scope
- Permission to run and validate reusable workflows in public/untrusted CI lanes

### Required Knowledge

- TAGS two-tier runner policy and action pinning policy
- Shared reusable workflow routing and exception handling semantics

---

## Deployment Steps

### Step 1: Confirm matrix assignment

Confirm the consumer repository row in the root matrix has owner, wave, target reusable workflow, and rollback owner assigned.

**Validation**:

```bash
# Validate local CORE-6 and workflow structure
./scripts/check_core6_compliance.sh
```

Expected output:

```text
- All reported checks show PASS for each required CORE-6 document or file.
- The script finishes with a final summary line reporting COMPLIANT.
```

### Step 2: Apply migration in target consumer repository

Replace authoritative local workflow logic with pinned reusable calls from `tags-workflows`. Use wrapper workflows only when trigger customization is required.

**Validation**:

```bash
# Validate immutable workflow refs in changed workflow files
grep -R "uses: theangrygamershowproductions/tags-workflows/.github/workflows/" .github/workflows | cat
```

---

## Post-Deployment Validation

### Health Checks

```bash
# Check 1: local CORE-6 continuity
./scripts/check_core6_compliance.sh

# Check 2: verify latest workflow runs
gh run list --limit 5
```

### Expected State

- consumer repo uses pinned reusable workflow refs from this repository
- matrix row updated to Validated or Cutover Complete

---

## Troubleshooting

### Issue: Contract behavior mismatch after migration

**Symptoms**:

- workflow path selection diverges from shared contract behavior
- repo-specific exception flow conflicts with shared reusable interface

**Solution**:

```bash
# inspect workflow triggers and shared contract conditions in target repo
grep -R "pull_request\|pull_request_target\|workflow_call" .github/workflows | cat
```

## Source Of Truth

- Root TAGS CORE-6 remains authoritative for ecosystem matrix and governance gates.
- This repository CORE-6 is a derived execution layer for public/untrusted CI implementation details.

---

## References

- [PLAN.md](PLAN.md) - Architecture decisions
- [TODO.md](TODO.md) - Deployment task breakdown
- [ROADMAP.md](ROADMAP.md) - Target version timeline
- [PROGRESS.md](PROGRESS.md) - Known deployment gaps
- [TAGS Root DEPLOYMENT.md](https://github.com/theangrygamershowproductions/TAGS-META/blob/main/DEPLOYMENT.md) - Root control-plane runbook
