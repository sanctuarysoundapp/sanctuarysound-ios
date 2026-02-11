#!/bin/bash
# ============================================================================
# capture-screenshots.sh
# SanctuarySound — App Store Screenshot Automation
# ============================================================================
# Runs the UI screenshot tests, extracts attachments from the .xcresult
# bundle, and copies them to the metadata directory for App Store upload.
#
# Usage: ./scripts/capture-screenshots.sh
# Output: metadata/app-store/screenshots/6.9-inch/01_Services.png ... 09_Settings.png
# ============================================================================

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="SanctuarySound"
DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro Max"
RESULT_BUNDLE="$PROJECT_DIR/build/Screenshots.xcresult"
OUTPUT_DIR="$PROJECT_DIR/metadata/app-store/screenshots/6.9-inch"

echo "=== SanctuarySound Screenshot Capture ==="
echo "Project: $PROJECT_DIR"
echo "Output:  $OUTPUT_DIR"
echo ""

# Clean previous result bundle and output
rm -rf "$RESULT_BUNDLE"
mkdir -p "$OUTPUT_DIR"

# Build and run UI tests
echo ">>> Building and running screenshot tests..."
xcodebuild test \
    -project "$PROJECT_DIR/SanctuarySound.xcodeproj" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -only-testing:SanctuarySoundUITests \
    -resultBundlePath "$RESULT_BUNDLE" \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    2>&1 | tail -20

echo ""
echo ">>> Extracting screenshots from xcresult bundle..."

# Step 1: Get the testsRef from the top-level action result
TESTS_REF=$(xcrun xcresulttool get --legacy --path "$RESULT_BUNDLE" --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
actions = data.get('actions', {}).get('_values', [])
for action in actions:
    ref = action.get('actionResult', {}).get('testsRef', {}).get('id', {}).get('_value', '')
    if ref:
        print(ref)
        break
" 2>/dev/null)

if [ -z "$TESTS_REF" ]; then
    echo "ERROR: Could not find testsRef in xcresult bundle."
    echo "Open the bundle manually: open $RESULT_BUNDLE"
    exit 1
fi

# Step 2: Get all test case summary references
SUMMARY_REFS=$(xcrun xcresulttool get --legacy --path "$RESULT_BUNDLE" --id "$TESTS_REF" --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
def find_refs(obj):
    if isinstance(obj, dict):
        if obj.get('_type', {}).get('_name', '') == 'ActionTestMetadata':
            ref = obj.get('summaryRef', {}).get('id', {}).get('_value', '')
            if ref:
                print(ref)
        for v in obj.values():
            find_refs(v)
    elif isinstance(obj, list):
        for v in obj:
            find_refs(v)
find_refs(data)
" 2>/dev/null)

if [ -z "$SUMMARY_REFS" ]; then
    echo "ERROR: No test summaries found."
    exit 1
fi

# Step 3: For each test summary, extract the screenshot attachment
EXTRACTED=0
while IFS= read -r SUMMARY_ID; do
    RESULT=$(xcrun xcresulttool get --legacy --path "$RESULT_BUNDLE" --id "$SUMMARY_ID" --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
def find_att(obj):
    if isinstance(obj, dict):
        if obj.get('_type', {}).get('_name', '') == 'ActionTestAttachment':
            name = obj.get('name', {}).get('_value', '')
            ref = obj.get('payloadRef', {}).get('id', {}).get('_value', '')
            if ref and name:
                print(f'{name}|{ref}')
                return True
        for v in obj.values():
            if find_att(v):
                return True
    elif isinstance(obj, list):
        for v in obj:
            if find_att(v):
                return True
    return False
find_att(data)
" 2>/dev/null)

    if [ -n "$RESULT" ]; then
        NAME=$(echo "$RESULT" | cut -d'|' -f1)
        PAYLOAD_REF=$(echo "$RESULT" | cut -d'|' -f2)
        xcrun xcresulttool export --legacy --path "$RESULT_BUNDLE" \
            --output-path "$OUTPUT_DIR/${NAME}.png" \
            --id "$PAYLOAD_REF" --type file 2>/dev/null
        EXTRACTED=$((EXTRACTED + 1))
        echo "  Extracted: ${NAME}.png"
    fi
done <<< "$SUMMARY_REFS"

echo ""
echo "=== Screenshot Capture Complete ==="
echo "Extracted $EXTRACTED screenshots to: $OUTPUT_DIR"
echo ""
ls -la "$OUTPUT_DIR"/*.png 2>/dev/null || echo "No PNG files found."
