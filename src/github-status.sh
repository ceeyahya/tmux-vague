#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/../lib/coreutils-compat.sh"
source "$CURRENT_DIR/themes.sh"

cd "$1" || exit 1

RESET="#[fg=${THEME_foreground},bg=${THEME_background},nobold,noitalics,nounderscore,nodim]"

# Cache settings
CACHE_DIR="${HOME}/.cache/gruvbox-tmux"
CACHE_DURATION=300 # 5 minutes in seconds

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    exit 0
fi

# Get the remote origin URL
REMOTE_URL=$(git remote get-url origin 2>/dev/null)
if [[ -z "$REMOTE_URL" ]]; then
    exit 0
fi

# Extract owner and repo from various GitHub URL formats
if [[ $REMOTE_URL =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
    REPO="${REPO%.git}" # Remove .git extension if present
else
    exit 0
fi

# Set up cache
mkdir -p "$CACHE_DIR"
CACHE_FILE="${CACHE_DIR}/${OWNER}_${REPO}_github_status"

# Check if cache exists and is still valid
if [[ -f "$CACHE_FILE" ]]; then
    CACHE_AGE=$(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
    if [[ $CACHE_AGE -lt $CACHE_DURATION ]]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Function to make GitHub API request
github_api_request() {
    local endpoint="$1"
    local api_path="/repos/${OWNER}/${REPO}${endpoint}"
    local url="https://api.github.com${api_path}"

    # Check if GitHub CLI is available and authenticated
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        gh api "$api_path" --hostname github.com 2>/dev/null
    else
        # Fallback to curl without authentication (rate limited)
        curl -s -H "Accept: application/vnd.github.v3+json" "$url" 2>/dev/null
    fi
}

# Get repository information including open issues and pull requests count
REPO_INFO=$(github_api_request "")
if [[ -n "$REPO_INFO" && ! "$REPO_INFO" =~ "API rate limit exceeded" ]]; then
    # Extract counts from repository info
    ISSUE_COUNT=$(echo "$REPO_INFO" | grep -o '"open_issues_count":[0-9]*' | grep -o '[0-9]*' | head -1)

    # Get pull request count separately
    PR_COUNT_RESPONSE=$(github_api_request "/pulls?state=open&per_page=100")
    if [[ -n "$PR_COUNT_RESPONSE" && ! "$PR_COUNT_RESPONSE" =~ "API rate limit exceeded" ]]; then
        PR_COUNT=$(echo "$PR_COUNT_RESPONSE" | grep -o '"number":' | wc -l | tr -d ' ')
    else
        PR_COUNT=0
    fi

    # Calculate actual issue count (open_issues_count includes PRs)
    if [[ -n "$ISSUE_COUNT" && "$ISSUE_COUNT" =~ ^[0-9]+$ ]]; then
        ISSUE_COUNT=$((ISSUE_COUNT - PR_COUNT))
        if [[ $ISSUE_COUNT -lt 0 ]]; then
            ISSUE_COUNT=0
        fi
    else
        ISSUE_COUNT=0
    fi
else
    PR_COUNT=0
    ISSUE_COUNT=0
fi

# Format output with GitHub-themed colors and icons
PR_ICON="󰘬"
ISSUE_ICON="󰌶"
GITHUB_STATUS=""

if [[ $PR_COUNT -gt 0 ]]; then
    GITHUB_STATUS="${GITHUB_STATUS}${RESET}#[fg=${THEME_ghmagenta},bg=${THEME_background},bold]▒ ${PR_ICON} ${PR_COUNT} "
fi

if [[ $ISSUE_COUNT -gt 0 ]]; then
    GITHUB_STATUS="${GITHUB_STATUS}${RESET}#[fg=${THEME_ghred},bg=${THEME_background},bold]▒ ${ISSUE_ICON} ${ISSUE_COUNT} "
fi

# Only output if we have something to show
if [[ -n "$GITHUB_STATUS" ]]; then
    echo "$GITHUB_STATUS"
    # Cache the result
    echo "$GITHUB_STATUS" >"$CACHE_FILE"
else
    # Cache empty result too
    echo "" >"$CACHE_FILE"
fi
