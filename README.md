# TAGS Public Reusable Workflows

This repository contains **generic, open-source reusable GitHub Actions workflows** for The Angry Gamer Show Productions ecosystem. These workflows provide standardized CI/CD patterns that can be used by any public repository in the organization.

## 🚀 Available Workflows

### Core CI Workflows

- **`ci-lite.yml`** - Lightweight CI with Node.js and Python support, linting, and testing
- **`docs-governance.yml`** - Documentation validation, link checking, and governance compliance
- **`project-health.yml`** - Project health metrics, dependency auditing, and quality gates

### Composite Actions

- **`setup-python-node`** - Unified Python and Node.js environment setup with caching

## 📖 Usage

Reference these workflows from your repository's `.github/workflows/*.yml` files:

```yaml
name: Pull Request Validation
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]

jobs:
  ci:
    uses: theangrygamershowproductions/tags-workflows/.github/workflows/ci-lite.yml@0123456789abcdef0123456789abcdef01234567
    with:
      node_version: "20"
      python_version: "3.12"
      fail_fast: "true"
    secrets: inherit
```

## 📋 Versioning

- **`@0123456789abcdef0123456789abcdef01234567`** - Immutable SHA pin (required)

## 🤝 Contributing

These workflows are maintained as part of the TAGS ecosystem. For issues or enhancements, please open an issue in this repository.

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

**The Angry Gamer Show Productions** - Professional development infrastructure for the gaming community.
TAGS Ecosystem Public Reusable Workflows - Generic CI/CD workflows for open source projects
