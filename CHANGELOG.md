# Changelog - tags-workflows

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Authority & Scope

**Binding Sources**: Root TAGS CORE-6 (PLAN.md, DEPLOYMENT.md) + DEC-014  
**Classification**: Derived execution document (public lane change history)  
**Allowed Changes**: Documenting release notes, version tags, security/performance updates  
**NOT Allowed Without Root ADR**: Redefining lane architecture in context of changes  
**Note**: Change history is recorded for **public/untrusted** CI lane (GitHub-hosted runners). Lane scope itself is governed by root TAGS CORE-6 and DEC-014.

## [Unreleased]

### Added (Initial Release)

- Initial repository structure
- Basic documentation
- Contributing guidelines
- Public/untrusted CI migration program definition tied to TAGS-META control plane
- Matrix-driven migration phases and cutover gates for public/untrusted CI consumers

### Changed

- Replaced placeholder CORE-6 content with implementation-ready public-lane CI migration objectives, phases, and validation flow

### Deprecated

- N/A

### Removed

- N/A

### Fixed

- N/A

### Security

- N/A

## [0.1.0] - 2025-10-10

### Added

- Initial release
- Repository setup complete
