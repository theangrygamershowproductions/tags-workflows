# tags-workflows TODO

Last Updated: 2026-03-10
Execution Owner: TAGS Infrastructure Team

## Authority & Scope

**Binding Sources**: Root TAGS CORE-6 (PLAN.md, DEPLOYMENT.md) + DEC-014  
**Classification**: Derived execution document (public lane task tracking)  
**Allowed Changes**: Task status updates, priority adjustments, execution sequencing  
**NOT Allowed Without Root ADR**: Lane scope, runner trust boundary redefinition  
**Note**: Root TAGS CORE-6 defines binding architecture. This document tracks execution tasks for **public/untrusted** CI lane (GitHub-hosted runners only).

## Legend

- `[ ]` not started
- `[~]` in progress
- `[x]` completed

## Phase 0 - CORE-6 Baseline

- [x] Create PLAN.md
- [x] Create TODO.md
- [x] Create ROADMAP.md
- [x] Create PROGRESS.md
- [x] Create DEPLOYMENT.md
- [x] Create CHANGELOG.md
- [ ] Populate strategic objectives in PLAN.md
- [ ] Define version milestones in ROADMAP.md
- [ ] Document deployment procedures in DEPLOYMENT.md

## Phase 1 - Public/Untrusted CI Contract Hardening

Target Window: 2026-03-10 to 2026-03-20

- [~] Define contract fields for public/untrusted reusable workflows (inputs, outputs, permissions)
- [~] Define shared-pattern boundaries and repo-specific exception rules in reusable contracts
- [ ] Verify action/source policies are enforced for all canonical reusable workflows

## Phase 2 - Public/Untrusted CI Repo-by-Repo Matrix Build

Target Window: 2026-03-10 to 2026-03-22

- [~] Create public/untrusted CI consumer matrix rows with required fields
- [ ] Assign wave and owner for each consumer
- [ ] Add per-repo acceptance criteria and rollback owner

## Phase 3 - Public/Untrusted CI Migration Execution

Target Window: 2026-03-21 to 2026-04-15

- [ ] Execute Wave 1 shared CI migrations and capture validation evidence
- [ ] Execute Wave 2 shared CI migrations and capture validation evidence
- [ ] Execute Wave 3 shared CI migrations and prepare deprecation list

## Phase 4 - Public/Untrusted Cutover and Deprecation

Target Window: 2026-04-16 to 2026-04-30

- [ ] Run final cutover gate for public/untrusted CI consumers
- [ ] Remove transitional aliases after compatibility window
- [ ] Record completion in PROGRESS.md and CHANGELOG.md

## Backlog

- Add automated check that enforces shared-pattern conformance and blocks mutable reusable refs.

## References

- [PLAN.md](PLAN.md) - Strategic direction
- [ROADMAP.md](ROADMAP.md) - Version timeline
- [PROGRESS.md](PROGRESS.md) - Execution status
