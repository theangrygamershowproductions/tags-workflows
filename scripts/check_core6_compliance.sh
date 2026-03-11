#!/usr/bin/env bash
# check_core6_compliance.sh - Validate CORE-6 Standard compliance
# Authority: TAGS_KB/30_CORE6_STANDARD.md

set -euo pipefail

readonly REQUIRED_FILES=(PLAN.md TODO.md ROADMAP.md PROGRESS.md DEPLOYMENT.md CHANGELOG.md)
readonly CHECK_FILES=(PLAN.md TODO.md ROADMAP.md PROGRESS.md DEPLOYMENT.md CHANGELOG.md README.md)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m'
readonly FORBIDDEN_TERMS='internal CI platform|externalized|public subset|mirror of tags-workflows'
readonly MUTABLE_TAGS_OWNED_REFS='theangrygamershowproductions/(tags-workflows|tags-workflows-private)/[^@[:space:]]+@(main|v1|shared-ci-v1|v[0-9]+\.[0-9]+(\.[0-9]+)?)'
readonly WORKSTATION_PATH_PATTERN='(/home/potato/TAGS|~/TAGS)'
readonly ABS_WORKSTATION_PATH_PATTERN='/home/potato/TAGS'
readonly HELPER_SURFACES=(
    utility/check_instruction_quality.sh
    fix/fix_commits.sh
    scripts/check_core6_compliance.sh
)

exit_code=0

for file in "${CHECK_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        printf "${RED}FAIL${NC} CORE-6 violation: Missing %s\n" "$file"
        exit_code=1
    else
        printf "${GREEN}PASS${NC} Found %s\n" "$file"
        if [[ " ${REQUIRED_FILES[*]} " == *" $file "* ]] && ! grep -q '^## Authority & Scope' "$file"; then
            printf "${RED}FAIL${NC} Missing '## Authority & Scope' in %s\n" "$file"
            exit_code=1
        fi
        if grep -E -n "$FORBIDDEN_TERMS" "$file" >/dev/null; then
            printf "${RED}FAIL${NC} Forbidden terminology found in %s\n" "$file"
            grep -E -n "$FORBIDDEN_TERMS" "$file" | sed 's/^/  -> /'
            exit_code=1
        fi
        if grep -E -n "$MUTABLE_TAGS_OWNED_REFS" "$file" >/dev/null; then
            printf "${RED}FAIL${NC} Mutable TAGS-owned workflow ref found in %s\n" "$file"
            grep -E -n "$MUTABLE_TAGS_OWNED_REFS" "$file" | sed 's/^/  -> /'
            exit_code=1
        fi
        if grep -n "$ABS_WORKSTATION_PATH_PATTERN" "$file" >/dev/null; then
            printf "${RED}FAIL${NC} Workstation-specific path found in %s\n" "$file"
            grep -n "$ABS_WORKSTATION_PATH_PATTERN" "$file" | sed 's/^/  -> /'
            exit_code=1
        fi
    fi
done

for file in "${HELPER_SURFACES[@]}"; do
    if [[ ! -f "$file" ]]; then
        continue
    fi
    if grep -E -n "$WORKSTATION_PATH_PATTERN" "$file" | grep -v 'WORKSTATION_PATH_PATTERN' >/dev/null; then
        printf "${RED}FAIL${NC} Workstation-specific path found in helper surface %s\n" "$file"
        grep -E -n "$WORKSTATION_PATH_PATTERN" "$file" | grep -v 'WORKSTATION_PATH_PATTERN' | sed 's/^/  -> /'
        exit_code=1
    fi
done

if [[ $exit_code -eq 0 ]]; then
    printf "\n${GREEN}PASS${NC} CORE-6 and local governance checks: COMPLIANT\n"
else
    printf "\n${RED}FAIL${NC} CORE-6 and local governance checks: NON-COMPLIANT\n"
    printf "Fix reported violations and rerun ./scripts/check_core6_compliance.sh\n"
fi

exit $exit_code
