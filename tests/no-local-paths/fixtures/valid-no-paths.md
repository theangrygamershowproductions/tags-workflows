# Test Fixture: Valid Configuration (No Local Paths)

## Good Example: Environment Variables

```bash
export TAGS_ROOT="${HOME}/TAGS"
export PROJECT_DIR="$(pwd)"
export DATA_DIR="${TAGS_ROOT}/data"
```

## Good Example: Relative Paths

```
src/utils/helpers.ts
../../../shared/templates/base.md
./config/settings.json
```

## Good Example: Cloudlog Documentation Reference

See documentation at `~/TAGS/ecosystem/tags-mcp-servers/` for MCP server setup.

## Good Example: Generic Path Example

Documentation available at `<workspace-root>/docs/setup.md`
