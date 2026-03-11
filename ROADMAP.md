# tags-workflows Roadmap

Last Updated: 2026-03-10

## Authority & Scope

**Binding Sources**: Root TAGS CORE-6 (PLAN.md, DEPLOYMENT.md) + DEC-014  
**Classification**: Derived execution document (public lane version planning)  
**Allowed Changes**: Version timeline adjustments, feature scope clarifications, milestone dates  
**NOT Allowed Without Root ADR**: Lane architecture changes, public/untrusted boundary redefinition  
**Note**: Root TAGS CORE-6 authoritative. This document plans versions for **public/untrusted** CI lane implementation.

## Version Timeline

| Phase   | Version Target | Window                   | Outcome                                            |
| ------- | -------------- | ------------------------ | -------------------------------------------------- |
| Phase 0 | v0.1-alpha     | 2026-03-09               | CORE-6 baseline and documentation                  |
| Phase 1 | v1.0-beta      | 2026-03-10 to 2026-03-22 | Public/untrusted CI hardening + matrix baseline    |
| Phase 2 | v1.0-stable    | 2026-03-23 to 2026-04-15 | Public lane migration waves executed and validated |
| Phase 3 | v2.0           | 2026-04-16 to 2026-04-30 | Public lane cutover + deprecation run              |

Dates are planning targets and may adjust based on project needs.

## v0.1-alpha (Current)

State:

- CORE-6 documentation structure in place.
- Strategic direction being defined.

Known Gaps:

- Detailed task breakdown needed.
- Deployment procedures to be documented.

## v1.0-beta (Next)

Goal:

- Establish stable public/untrusted reusable workflow contracts and complete matrix-based migration planning.

Must Have:

1. Shared workflow contract behavior defined for standard and exception paths.
2. Public/untrusted CI consumer matrix completed with owner and wave assignments.

Nice to Have:

- Automated summary of migration matrix status by wave.

## v1.0-stable (Target)

Goal:

- Complete public-lane CI consumer migrations with policy conformance validation.

Must Have:

1. All consumer refs pinned to immutable SHA for reusable workflow calls.
2. All wave cutover gates pass policy and runtime checks.

## v2.0 (Future)

Vision:

- Continuous public-lane workflow platform operations with enforceable governance.

Dependencies:

- Root TAGS-META matrix remains authoritative and synchronized.

## References

- [PLAN.md](PLAN.md) - Strategic objectives
- [TODO.md](TODO.md) - Phase execution
- [DEPLOYMENT.md](DEPLOYMENT.md) - Architecture evolution
