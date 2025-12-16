#!/usr/bin/env bash
# AI Toolkit - GitHub PR Info
# Fetch details for a GitHub Pull Request

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_integration-common.sh"

# ============================================================================
# USAGE INFORMATION
# ============================================================================

show_usage() {
  cat << 'EOF'
Usage: github-pr-info.sh PR-NUMBER

Fetch details for a GitHub Pull Request.

Arguments:
  PR-NUMBER     Pull request number

Options:
  -h, --help    Show this help message

Output:
  JSON object with PR details including:
  - number: PR number
  - title: PR title
  - state: open/closed/merged
  - author: PR author
  - url: PR URL
  - branch: Source branch name
  - baseBranch: Target branch name
  - reviews: Review status summary
  - mergeable: Whether PR can be merged
  - draft: Whether PR is a draft

Examples:
  github-pr-info.sh 123
  github-pr-info.sh 456 | jq '.state'
  github-pr-info.sh 789 | jq '.reviews.approved'

Tips:
  - PR number is the numeric ID in the PR URL
  - Repository is configured in ~/.ai-toolkit-env
  - Use jq to extract specific fields

EOF
}

# ============================================================================
# MAIN FUNCTION
# ============================================================================

main() {
  # Check for help flag
  if check_help_flag "$@"; then
    show_usage
    exit 0
  fi

  # Check arguments
  if [[ $# -eq 0 ]]; then
    error_msg "Missing required argument: PR-NUMBER"
    echo "" >&2
    show_usage
    exit 1
  fi

  local pr_number="$1"

  # Validate PR number is numeric
  if ! is_number "$pr_number"; then
    error_msg "Invalid PR number: $pr_number (must be a number)"
    exit 1
  fi

  # Load configuration
  if ! load_config; then
    exit 1
  fi

  # Validate required environment variables
  require_env "GITHUB_TOKEN" || exit 1
  require_env "GITHUB_REPO_OWNER" || exit 1
  require_env "GITHUB_REPO_NAME" || exit 1

  # Build API URL
  local api_url
  api_url=$(github_api_url "repos/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/pulls/${pr_number}")

  debug "Fetching PR #$pr_number from $api_url"

  # Get auth header
  local auth_header
  if ! auth_header=$(github_auth_header); then
    exit 1
  fi

  # Fetch PR data
  local response
  if ! response=$(http_request "GET" "$api_url" "$auth_header"); then
    error_msg "Failed to fetch PR #$pr_number"
    info_msg "Verify the PR exists in ${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}"
    exit 1
  fi

  # Fetch review status
  local reviews_url
  reviews_url=$(github_api_url "repos/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/pulls/${pr_number}/reviews")

  debug "Fetching PR reviews from $reviews_url"

  local reviews
  if ! reviews=$(http_request "GET" "$reviews_url" "$auth_header"); then
    warn_msg "Failed to fetch PR reviews, continuing without review data"
    reviews="[]"
  fi

  # Parse and format response
  local output
  output=$(jq -n \
    --argjson pr "$response" \
    --argjson reviews "$reviews" \
    '{
      number: $pr.number,
      title: $pr.title,
      state: (if $pr.merged then "merged" else $pr.state end),
      author: $pr.user.login,
      url: $pr.html_url,
      branch: $pr.head.ref,
      baseBranch: $pr.base.ref,
      reviews: {
        approved: ([$reviews[] | select(.state == "APPROVED")] | length),
        changesRequested: ([$reviews[] | select(.state == "CHANGES_REQUESTED")] | length),
        commented: ([$reviews[] | select(.state == "COMMENTED")] | length),
        total: ($reviews | length)
      },
      mergeable: $pr.mergeable,
      draft: $pr.draft,
      createdAt: $pr.created_at,
      updatedAt: $pr.updated_at
    }')

  # Check if jq parsing was successful
  if [[ $? -ne 0 ]]; then
    error_msg "Failed to parse GitHub response"
    debug "Raw response: $response"
    exit 1
  fi

  # Output the formatted PR data
  echo "$output"

  # Print summary to stderr
  local state
  state=$(echo "$output" | jq -r '.state')

  debug "Successfully fetched PR #$pr_number (state: $state)"
}

# Run main function
main "$@"
