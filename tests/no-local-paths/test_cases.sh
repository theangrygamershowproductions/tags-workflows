#!/bin/bash
# Test Runner: Guard - No Local Paths
#
# Tests the validate_no_local_paths.sh guard against fixture files.
# Exit code 0 if all tests pass, non-zero if any fail.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD_SCRIPT="${SCRIPT_DIR}/../../scripts/validate_no_local_paths.sh"
FIXTURES_DIR="${SCRIPT_DIR}/fixtures"

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

test_case() {
  local name="$1"
  local fixture="$2"
  local should_pass="$3"
  
  TEST_COUNT=$((TEST_COUNT + 1))
  
  echo -e "\n${BLUE}Test $TEST_COUNT: $name${NC}"
  echo "  Fixture: $fixture"
  echo "  Expected: $([ "$should_pass" == "true" ] && echo "PASS" || echo "FAIL")"
  
  # Create temporary git repo with the fixture file
  local temp_dir
  temp_dir=$(mktemp -d)
  cd "$temp_dir"
  
  git init > /dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name "Test User"
  
  # Copy fixture and stage it
  cp "$fixture" test_file.md
  git add test_file.md
  
  # Run guard in staged mode
  local exit_code=0
  "$GUARD_SCRIPT" --staged --verbose > output.log 2>&1 || exit_code=$?
  
  # Check result
  if [[ "$should_pass" == "true" ]] && [[ $exit_code -eq 0 ]]; then
    echo -e "  Result: ${GREEN}✓ PASS${NC}"
    PASS_COUNT=$((PASS_COUNT + 1))
  elif [[ "$should_pass" == "false" ]] && [[ $exit_code -ne 0 ]]; then
    echo -e "  Result: ${GREEN}✓ PASS${NC} (correctly caught violation)"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "  Result: ${RED}✗ FAIL${NC}"
    echo "  Guard output:"
    sed 's/^/    /' output.log || true
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
  
  # Cleanup
  cd ..
  rm -rf "$temp_dir"
}

# Run tests
echo "===== Guard Test Suite: No Local Paths ====="
echo "Guard Script: $GUARD_SCRIPT"
echo "Fixtures Dir: $FIXTURES_DIR"

if [[ ! -x "$GUARD_SCRIPT" ]]; then
  echo -e "${RED}ERROR: Guard script not found or not executable${NC}"
  exit 1
fi

if [[ ! -d "$FIXTURES_DIR" ]]; then
  echo -e "${RED}ERROR: Fixtures directory not found${NC}"
  exit 1
fi

# Test 1: Valid file (no local paths) should PASS
if [[ -f "$FIXTURES_DIR/valid-no-paths.md" ]]; then
  test_case "Valid file with no local paths" "$FIXTURES_DIR/valid-no-paths.md" "true"
fi

# Test 2: Invalid file (with local paths) should FAIL
if [[ -f "$FIXTURES_DIR/invalid-with-paths.md" ]]; then
  test_case "Invalid file with local paths" "$FIXTURES_DIR/invalid-with-paths.md" "false"
fi

# Summary
echo ""
echo "===== Test Summary ====="
echo "Total: $TEST_COUNT"
echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
echo -e "Failed: ${RED}$FAIL_COUNT${NC}"
echo ""

if [[ $FAIL_COUNT -eq 0 ]]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
