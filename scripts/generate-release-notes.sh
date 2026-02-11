#!/bin/bash
# ============================================================================
# generate-release-notes.sh
# SanctuarySound — Release Notes Generator
# ============================================================================
# Parses git log between tags and groups commits by conventional type.
#
# Usage:
#   ./scripts/generate-release-notes.sh           # from latest tag to HEAD
#   ./scripts/generate-release-notes.sh v0.2.0    # from v0.2.0 to HEAD
# ============================================================================

set -euo pipefail

FROM_TAG="${1:-$(git describe --tags --abbrev=0 2>/dev/null || echo '')}"

if [[ -z "$FROM_TAG" ]]; then
    RANGE="HEAD"
    echo "# Release Notes (all commits)"
else
    RANGE="${FROM_TAG}..HEAD"
    echo "# Release Notes (since $FROM_TAG)"
fi

echo ""

print_section() {
    local type="$1"
    local heading="$2"
    local commits
    commits=$(git log "$RANGE" --oneline --grep="^${type}:" --format="- %s" 2>/dev/null | sed "s/^- ${type}: /- /" || true)
    if [[ -n "$commits" ]]; then
        echo "## $heading"
        echo "$commits"
        echo ""
    fi
}

print_section "feat"     "Added"
print_section "fix"      "Fixed"
print_section "refactor" "Changed"
print_section "perf"     "Performance"
print_section "docs"     "Documentation"
print_section "test"     "Tests"
print_section "ci"       "CI/CD"
print_section "chore"    "Maintenance"

# Catch any commits that don't follow conventional format
OTHER=$(git log "$RANGE" --oneline --format="- %s" 2>/dev/null | grep -v -E "^- (feat|fix|refactor|perf|docs|test|ci|chore):" || true)
if [[ -n "$OTHER" ]]; then
    echo "## Other"
    echo "$OTHER"
    echo ""
fi
