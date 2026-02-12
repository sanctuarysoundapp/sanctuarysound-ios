#!/bin/bash
# ============================================================================
# capture-screenshots.sh
# SanctuarySound — App Store Screenshot Automation
# ============================================================================
# Runs UI screenshot tests on multiple iPhone simulators and renders Watch/Widget
# screenshots via ImageRenderer unit tests. Extracts PNGs from xcresult bundles.
#
# Usage:
#   ./scripts/capture-screenshots.sh              # Full run (all devices + watch)
#   ./scripts/capture-screenshots.sh --iphone-only # iPhone screenshots only
#   ./scripts/capture-screenshots.sh --watch-only  # Watch/Widget screenshots only
#   ./scripts/capture-screenshots.sh --device "iPhone 17 Pro Max"  # Single device
#
# Output: metadata/app-store/screenshots/{size}/*.png
# ============================================================================

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="SanctuarySound"
BUILD_DIR="$PROJECT_DIR/build"
SCREENSHOT_DIR="$PROJECT_DIR/metadata/app-store/screenshots"

# ── Device Map: "Simulator Name|Output Directory" ──
IPHONE_DEVICES=(
    "iPhone 17 Pro Max|6.9-inch"
    "iPhone 17 Pro|6.3-inch"
    "iPhone 16e|6.1-inch"
)

# ── Watch screenshot output directories ──
WATCH_DIRS=(
    "watch-ultra-3"
    "watch-series-11"
    "watch-complications"
)

# ── Parse CLI Flags ──
RUN_IPHONE=true
RUN_WATCH=true
SINGLE_DEVICE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --iphone-only)
            RUN_WATCH=false
            shift
            ;;
        --watch-only)
            RUN_IPHONE=false
            shift
            ;;
        --device)
            if [[ $# -lt 2 ]]; then
                echo "Error: --device requires a simulator name argument"
                exit 1
            fi
            SINGLE_DEVICE="$2"
            shift 2
            ;;
        *)
            echo "Unknown flag: $1"
            echo "Usage: $0 [--iphone-only] [--watch-only] [--device \"Simulator Name\"]"
            exit 1
            ;;
    esac
done


# ============================================================================
# Extract Screenshots from xcresult Bundle
# ============================================================================
# Reusable function: parses xcresult JSON tree to find test attachments and
# exports them as PNG files to the specified output directory.
#
# Usage: extract_screenshots <result_bundle_path> <output_directory>
# ============================================================================
extract_screenshots() {
    local RESULT_BUNDLE="$1"
    local OUTPUT_DIR="$2"
    local EXTRACTED=0

    # Step 1: Get the testsRef from the top-level action result
    local TESTS_REF
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
        echo "  WARNING: Could not find testsRef in xcresult bundle."
        return 1
    fi

    # Step 2: Get all test case summary references
    local SUMMARY_REFS
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
        echo "  WARNING: No test summaries found."
        return 1
    fi

    # Step 3: For each test summary, extract the screenshot attachment
    while IFS= read -r SUMMARY_ID; do
        local RESULT
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
            local NAME PAYLOAD_REF
            NAME=$(echo "$RESULT" | cut -d'|' -f1)
            PAYLOAD_REF=$(echo "$RESULT" | cut -d'|' -f2)
            xcrun xcresulttool export --legacy --path "$RESULT_BUNDLE" \
                --output-path "$OUTPUT_DIR/${NAME}.png" \
                --id "$PAYLOAD_REF" --type file 2>/dev/null
            EXTRACTED=$((EXTRACTED + 1))
            echo "  Extracted: ${NAME}.png"
        fi
    done <<< "$SUMMARY_REFS"

    echo "  ($EXTRACTED screenshots extracted)"
    return 0
}


# ============================================================================
# Check Simulator Availability
# ============================================================================
check_simulator() {
    local SIM_NAME="$1"
    xcrun simctl list devices available 2>/dev/null | grep -q "$SIM_NAME"
}


# ============================================================================
# Main Execution
# ============================================================================

echo "=== SanctuarySound Screenshot Capture ==="
echo "Project: $PROJECT_DIR"
echo ""

TOTAL_EXTRACTED=0

# ── iPhone UI Screenshots ──
if [ "$RUN_IPHONE" = true ]; then
    echo "━━━ iPhone Screenshots ━━━"
    echo ""

    for DEVICE_ENTRY in "${IPHONE_DEVICES[@]}"; do
        IFS='|' read -r SIM_NAME SIZE_DIR <<< "$DEVICE_ENTRY"

        # If --device flag was used, skip non-matching devices
        if [ -n "$SINGLE_DEVICE" ] && [ "$SIM_NAME" != "$SINGLE_DEVICE" ]; then
            continue
        fi

        # Check simulator availability
        if ! check_simulator "$SIM_NAME"; then
            echo "⚠️  Simulator '$SIM_NAME' not available — skipping $SIZE_DIR"
            echo ""
            continue
        fi

        local_dest="platform=iOS Simulator,name=$SIM_NAME"
        local_bundle="$BUILD_DIR/Screenshots-${SIZE_DIR}.xcresult"
        local_output="$SCREENSHOT_DIR/$SIZE_DIR"

        echo ">>> $SIM_NAME ($SIZE_DIR)"

        # Clean previous result bundle
        rm -rf "$local_bundle"
        mkdir -p "$local_output"

        # Run UI tests
        if xcodebuild test \
            -project "$PROJECT_DIR/SanctuarySound.xcodeproj" \
            -scheme "$SCHEME" \
            -destination "$local_dest" \
            -only-testing:SanctuarySoundUITests \
            -resultBundlePath "$local_bundle" \
            -configuration Debug \
            CODE_SIGNING_ALLOWED=NO \
            2>&1 | tail -5; then

            echo "  Extracting screenshots..."
            extract_screenshots "$local_bundle" "$local_output"
        else
            echo "  ❌ UI tests failed for $SIM_NAME — skipping extraction"
        fi

        echo ""
    done
fi


# ── Watch & Widget Screenshots ──
if [ "$RUN_WATCH" = true ]; then
    echo "━━━ Watch & Widget Screenshots ━━━"
    echo ""

    # Use any available iPhone simulator (renders are device-independent)
    WATCH_SIM="iPhone 17 Pro Max"
    WATCH_BUNDLE="$BUILD_DIR/WatchScreenshots.xcresult"

    # Create output directories
    for DIR in "${WATCH_DIRS[@]}"; do
        mkdir -p "$SCREENSHOT_DIR/$DIR"
    done

    # Clean previous result bundle
    rm -rf "$WATCH_BUNDLE"

    echo ">>> Rendering Watch/Widget screenshots via ImageRenderer..."
    if xcodebuild test \
        -project "$PROJECT_DIR/SanctuarySound.xcodeproj" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$WATCH_SIM" \
        -only-testing:SanctuarySoundTests/WatchWidgetScreenshotTests \
        -resultBundlePath "$WATCH_BUNDLE" \
        -configuration Debug \
        CODE_SIGNING_ALLOWED=NO \
        2>&1 | tail -5; then

        echo "  Extracting watch/widget screenshots..."

        # Extract all attachments to a temp directory first, then sort into folders
        TEMP_DIR="$BUILD_DIR/watch_temp"
        rm -rf "$TEMP_DIR"
        mkdir -p "$TEMP_DIR"

        extract_screenshots "$WATCH_BUNDLE" "$TEMP_DIR"

        # Sort screenshots into appropriate directories based on filename prefix
        for PNG in "$TEMP_DIR"/*.png; do
            [ -f "$PNG" ] || continue
            BASENAME=$(basename "$PNG")
            case "$BASENAME" in
                watch_0[1-4]_*)
                    cp "$PNG" "$SCREENSHOT_DIR/watch-ultra-3/$BASENAME"
                    echo "  → watch-ultra-3/$BASENAME"
                    ;;
                watch_0[5-8]_*)
                    cp "$PNG" "$SCREENSHOT_DIR/watch-series-11/$BASENAME"
                    echo "  → watch-series-11/$BASENAME"
                    ;;
                complication_*)
                    cp "$PNG" "$SCREENSHOT_DIR/watch-complications/$BASENAME"
                    echo "  → watch-complications/$BASENAME"
                    ;;
            esac
        done

        # Clean temp
        rm -rf "$TEMP_DIR"
    else
        echo "  ❌ Watch screenshot tests failed"
    fi

    echo ""
fi


# ── Summary ──
echo "=== Screenshot Capture Complete ==="
echo ""

for DIR in "$SCREENSHOT_DIR"/*/; do
    [ -d "$DIR" ] || continue
    COUNT=$(find "$DIR" -name "*.png" -maxdepth 1 | wc -l | tr -d ' ')
    if [ "$COUNT" -gt 0 ]; then
        DIRNAME=$(basename "$DIR")
        echo "  $DIRNAME: $COUNT screenshots"
        TOTAL_EXTRACTED=$((TOTAL_EXTRACTED + COUNT))
    fi
done

echo ""
echo "  Total: $TOTAL_EXTRACTED screenshots"
echo ""
