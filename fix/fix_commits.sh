#!/bin/bash
# Auto-generated commit fix script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEARCH_DIR="$SCRIPT_DIR"
COLOR_UTILS=""

while [[ "$SEARCH_DIR" != "/" ]]; do
	if [[ -f "$SEARCH_DIR/shared/scripts/color_utils.sh" ]]; then
		COLOR_UTILS="$SEARCH_DIR/shared/scripts/color_utils.sh"
		break
	fi
	SEARCH_DIR="$(dirname "$SEARCH_DIR")"
done

if [[ -n "$COLOR_UTILS" ]]; then
	# shellcheck disable=SC1090
	source "$COLOR_UTILS"
fi

# Centralized logging setup
SCRIPT_NAME="fix_commits.sh"
LOG_DIR="../logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/${SCRIPT_NAME%.*}_$TIMESTAMP.log"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Redirect all output to both console and log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting commit fixes at $(date)"

# Fix: FEAT(workflows): establish public reusable workflows for TAGS ecosystem → feat(workflows): establish public reusable workflows for TAGS ecosystem
git checkout e9790dc
git commit --amend -m "feat(workflows): establish public reusable workflows for TAGS ecosystem"

# Return to main branch
git checkout main
