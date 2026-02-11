#!/bin/bash
# ============================================================================
# bump-version.sh
# SanctuarySound — Version Bump Script
# ============================================================================
# Updates MARKETING_VERSION and CURRENT_PROJECT_VERSION in project.pbxproj
# across all non-test build configurations.
#
# Usage:
#   ./scripts/bump-version.sh --version 1.0.0 --build 42
#   ./scripts/bump-version.sh --version 1.0.0  # build defaults to 1
# ============================================================================

set -euo pipefail

PBXPROJ="SanctuarySound.xcodeproj/project.pbxproj"
VERSION=""
BUILD="1"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            VERSION="$2"
            shift 2
            ;;
        --build)
            BUILD="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 --version <semver> [--build <number>]"
            exit 1
            ;;
    esac
done

# Validate version
if [[ -z "$VERSION" ]]; then
    echo "Error: --version is required"
    echo "Usage: $0 --version <semver> [--build <number>]"
    exit 1
fi

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in semver format (e.g., 1.0.0)"
    exit 1
fi

if ! [[ "$BUILD" =~ ^[0-9]+$ ]]; then
    echo "Error: Build must be a positive integer"
    exit 1
fi

# Verify pbxproj exists
if [[ ! -f "$PBXPROJ" ]]; then
    echo "Error: $PBXPROJ not found. Run from project root."
    exit 1
fi

echo "Bumping version to $VERSION (build $BUILD)..."

# Update MARKETING_VERSION for 3-segment versions only (skips test target 2-segment "1.0")
sed -i '' "s/MARKETING_VERSION = [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/MARKETING_VERSION = $VERSION/g" "$PBXPROJ"

# Update CURRENT_PROJECT_VERSION across all configs
sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*/CURRENT_PROJECT_VERSION = $BUILD/g" "$PBXPROJ"

# Count changes
MARKETING_COUNT=$(grep -c "MARKETING_VERSION = $VERSION" "$PBXPROJ" || true)
BUILD_COUNT=$(grep -c "CURRENT_PROJECT_VERSION = $BUILD" "$PBXPROJ" || true)

echo "Updated $MARKETING_COUNT MARKETING_VERSION entries to $VERSION"
echo "Updated $BUILD_COUNT CURRENT_PROJECT_VERSION entries to $BUILD"
echo "Done."
