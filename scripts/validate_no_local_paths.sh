#!/bin/bash
# Guard: Validate No Local Paths in Tracked Files
# 
# This script prevents hardcoded local filesystem paths from being committed.
# Used as a pre-commit hook and in CI workflows.
#
# PATTERNS BLOCKED:
#   - file:// URIs (file:///path/to/file)
#   - Absolute Unix paths (/home/user/...)
#   - VS Code server paths (.vscode-server, .vscode-server-insiders)
#   - Windows user paths (C:\Users\...)
#   - Browser cache (workspaceStorage)
#
# MODES:
#   --staged   : Check only staged files (pre-commit mode, default)
#   --all      : Check all tracked files (CI mode)
#   --verbose  : Show detailed output
#   --help     : Show this message

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find git repo root (supports running from any directory)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
MODE="staged"  # default mode
VERBOSE=false
EXIT_CODE=0
VIOLATION_COUNT=0

# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# Pattern definitions
declare -a PATTERNS=(
  "file://"                          # file:// URIs
  "/home/[^/]*/"                     # /home/username/ absolute paths
  "\.vscode-server"                  # VS Code server directories
  "\.vscode-server-insiders"         # VS Code server insiders
  "workspaceStorage"                 # Browser/app workspace cache
  "C:\\\\Users\\\\"                  # Windows user paths
)

print_help() {
  sed -n '/^# Guard:/,/^[^#]/p' "$0" | sed 's/^# *//'
}

print_error() {
  echo -e "${RED}ERROR: $1${NC}" >&2
}

print_warning() {
  echo -e "${YELLOW}WARNING: $1${NC}"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_info() {
  if [[ "$VERBOSE" == "true" ]]; then
    echo -e "${BLUE}ℹ${NC} $1"
  fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --staged)
      MODE="staged"
      shift
      ;;
    --all)
      MODE="all"
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help)
      print_help
      exit 0
      ;;
    *)
      print_error "Unknown argument: $1"
      print_help
      exit 1
      ;;
  esac
done

# Determine files to check
if [[ "$MODE" == "staged" ]]; then
  print_info "Checking staged files (pre-commit mode)"
  mapfile -t FILES < <(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
elif [[ "$MODE" == "all" ]]; then
  print_info "Checking all tracked files (CI mode)"
  mapfile -t FILES < <(git ls-files 2>/dev/null || true)
fi

# Skip binary files and common directories
SKIP_PATTERNS=(
  "node_modules/"
  ".git/"
  "__pycache__/"
  ".pytest_cache/"
  ".venv/"
  "venv/"
  ".env"
  "*.png"
  "*.jpg"
  "*.jpeg"
  "*.gif"
  "*.zip"
  "*.tar.gz"
  "*.db"
  ".DS_Store"
)

should_skip_file() {
  local file="$1"
  for pattern in "${SKIP_PATTERNS[@]}"; do
    if [[ "$file" == *"$pattern"* ]]; then
      return 0  # true - skip this file
    fi
  done
  return 1  # false - don't skip
}

# Check each file
for file in "${FILES[@]}"; do
  # Skip empty entries
  [[ -z "$file" ]] && continue
  
  # Skip files matching skip patterns
  if should_skip_file "$file"; then
    print_info "Skipping: $file"
    continue
  fi
  
  # Skip if file doesn't exist (deleted file in staging)
  if [[ ! -f "$REPO_ROOT/$file" ]]; then
    print_info "File not found (deleted): $file"
    continue
  fi
  
  # Check file against all patterns using grep
  # Build a grep pattern from our violation patterns
  grep_pattern=""
  for pattern in "${PATTERNS[@]}"; do
    if [[ -z "$grep_pattern" ]]; then
      grep_pattern="$pattern"
    else
      grep_pattern="$grep_pattern|$pattern"
    fi
  done
  
  # Run grep to find matching lines
  if grep -nE "$grep_pattern" "$REPO_ROOT/$file" > /tmp/guard_matches.tmp 2>/dev/null; then
    # Process grep results
    while IFS=':' read -r line_num line_content; do
      VIOLATION_FOUND=false
      MATCHED_PATTERN=""
      
      for pattern in "${PATTERNS[@]}"; do
        if [[ "$line_content" =~ $pattern ]]; then
          VIOLATION_FOUND=true
          MATCHED_PATTERN="$pattern"
          break
        fi
      done
      
      if [[ "$VIOLATION_FOUND" == "true" ]]; then
        if [[ $VIOLATION_COUNT -eq 0 ]]; then
          echo ""
          print_error "Found local paths in tracked files:"
          echo ""
        fi
        
        VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
        EXIT_CODE=1
        
        # Print violation details
        printf "  ${RED}✗${NC} %s:%d\n" "$file" "$line_num"
        printf "    Pattern: %s\n" "$MATCHED_PATTERN"
        printf "    Content: %s\n" "$(echo "$line_content" | sed 's/^[[:space:]]*//' | cut -c 1-80)"
        echo ""
      fi
    done < /tmp/guard_matches.tmp
  fi
done

# Cleanup
rm -f /tmp/guard_matches.tmp

# Report results
echo ""
if [[ $VIOLATION_COUNT -eq 0 ]]; then
  if [[ ${#FILES[@]} -gt 0 ]]; then
    print_success "No local paths found in tracked files (checked ${#FILES[@]} files)"
  else
    print_info "No files to check"
  fi
else
  print_error "Found $VIOLATION_COUNT violation(s) in tracked files"
  echo ""
  echo "LOCAL PATH PATTERNS BLOCKED:"
  for pattern in "${PATTERNS[@]}"; do
    echo "  • $pattern"
  done
  echo ""
  echo "REMEDIATION:"
  echo "  1. Replace local paths with environment variables (\$TAGS_ROOT, \$HOME, etc.)"
  echo "  2. Use relative paths instead of absolute paths"
  echo "  3. Remove hardcoded usernames and machine-specific references"
  echo ""
fi

exit $EXIT_CODE
