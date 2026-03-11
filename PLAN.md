# tags-workflows Plan

Last Updated: 2026-03-10
Status: Implementation In Progress

## Authority & Scope

**Binding Sources**: Root TAGS CORE-6 (PLAN.md, DEPLOYMENT.md) + DEC-014  
**Classification**: Derived execution document (public lane implementation tracking)  
**Allowed Changes**: Execution sequencing, workflow contracts, local procedure details  
**NOT Allowed Without Root ADR**: Lane scope (public/GitHub-hosted), trust boundary, runner model  
**Note**: Root TAGS-META CORE-6 defines lane architecture per DEC-014. This submodule CORE-6 mirrors execution details for the public/untrusted CI lane.

## Purpose

Define the strategic direction, risk posture, and decision gates for `tags-workflows`.

## Current Reality

This repository is the canonical home for **public/untrusted** shared reusable CI workflows (GitHub-hosted runners only, per DEC-014). Shared pattern migration mapping and rollout tracking are defined in root TAGS CORE-6 but execution is tracked here.

## Problem Statement

TAGS repositories need one canonical **public/untrusted** CI source for shared patterns to eliminate duplicated workflows and enforce consistent governance across externally-contributed and public contexts.

### Current (gap)

- No complete public/untrusted CI migration matrix with wave assignment and validation states.
- Mixed workflow ownership across consumer repositories creates drift risk.
- Shared pattern boundaries are not consistently tied to migration tasks.

### Target (required)

- All public/untrusted CI consumers call reusable workflows from `tags-workflows` using immutable SHA references.
- Shared-pattern ownership is explicit and enforced.
- Acceptance criteria:
  1. 100 percent of public/untrusted CI consumers are mapped and wave-assigned.
  2. 100 percent migrated refs are immutable SHA.
  3. Shared CI conformance checks pass at cutover.

## Strategic Objectives

1. Serve as the canonical source for public/untrusted reusable CI workflows.
2. Execute public/untrusted CI migration using matrix and wave governance.
3. Enforce immutable reference and shared-pattern governance policies across all migrated consumers.

## Decision Gates

### Gate 1: Shared CI Mapping Completeness

**Criteria**:

- Public/untrusted CI consumer matrix rows are complete with owners and waves.
- Wave assignments and validation criteria are approved.

**Status**: In Progress

### Gate 2: Contract Integrity

**Criteria**:

- Shared CI pattern boundaries are explicitly modeled in reusable workflow contracts.
- Immutable SHA and permission checks pass for migrated consumers.

**Status**: Not Started

### Gate 3: Public/Untrusted CI Cutover

**Criteria**:

- All public-lane wave migrations are validated against shared CI conformance controls.
- Legacy authoritative duplicates are removed or have approved sunset date.

**Status**: Not Started

## References

- [TODO.md](TODO.md) - Task execution tracking
- [ROADMAP.md](ROADMAP.md) - Version timeline
- [DEPLOYMENT.md](DEPLOYMENT.md) - Architecture decisions
- [CORE-6 Standard](../../TAGS_KB/30_CORE6_STANDARD.md)
- [TAGS Root PLAN.md](../../PLAN.md) - Authoritative ecosystem control plane
- Source-of-truth relationship: this repository is authoritative for shared CI execution patterns; TAGS root CORE-6 is authoritative for orchestration status and migration gates.
