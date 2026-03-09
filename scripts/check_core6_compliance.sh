#!/usr/bin/env bash
# check_core6_compliance.sh - Validate CORE-6 Standard compliance
# Authority: TAGS_KB/30_CORE6_STANDARD.md

set -euo pipefail

readonly REQUIRED_FILES=(PLAN.md TODO.md ROADMAP.md PROGRESS.md DEPLOYMENT.md CHANGELOG.md)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

exit_code=0

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        printf "${RED}❌${NC} CORE-6 violation: Missing %s\n" "$file"
        exit_code=1
    else
        printf "${GREEN}✅${NC} Found %s\n" "$file"
    fi
done

if [[ $exit_code -eq 0 ]]; then
    printf "\n${GREEN}✅ CORE-6 Standard: COMPLIANT${NC}\n"
else
    printf "\n${RED}❌ CORE-6 Standard: NON-COMPLIANT${NC}\n"
    printf "Run: ~/TAGS/scripts/bootstrap_core6.sh\n"
fi

exit $exit_code
