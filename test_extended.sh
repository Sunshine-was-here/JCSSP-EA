#!/bin/bash
# Extended Test Suite for JCSSP EA Script
# Includes additional edge cases and multi-version scenarios

SCRIPT="/home/claude/JCSSP_EA_v1.9_clean.sh"
TEST_DIR="/tmp/jcssp_test"
PASSED=0
FAILED=0
TOTAL=0

# Setup mock defaults command
mkdir -p /usr/bin.mock
cat > /usr/bin.mock/defaults << 'MOCKEOF'
#!/bin/bash
if [[ "$1" != "read" ]]; then exit 1; fi
PLIST_PATH="$2"
KEY="$3"
if [[ ! -f "$PLIST_PATH" ]]; then exit 1; fi
VALUE=$(grep -A 1 "<key>$KEY</key>" "$PLIST_PATH" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
if [[ -z "$VALUE" ]]; then exit 1; fi
echo "$VALUE"
MOCKEOF
chmod +x /usr/bin.mock/defaults

create_plist() {
    local path="$1"
    local version="$2"
    mkdir -p "$(dirname "$path")"
    cat > "$path" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleShortVersionString</key>
    <string>${version}</string>
</dict>
</plist>
EOF
}

run_test() {
    local name="$1"
    local expected="$2"
    ((TOTAL++))
    
    # Create modified script
    sed "s|/Applications|${TEST_DIR}/Applications|g; s|/Library|${TEST_DIR}/Library|g; s|/usr/bin/defaults|/usr/bin.mock/defaults|g" "$SCRIPT" > "$TEST_DIR/test.sh"
    
    # Run and capture
    local output=$(bash "$TEST_DIR/test.sh" 2>&1 | grep -v "^$" | sed 's/<[^>]*>//g')
    
    echo "TEST #${TOTAL}: $name"
    if [[ "$output" == "$expected" ]]; then
        echo "  ✓ PASS"
        ((PASSED++))
    else
        echo "  ✗ FAIL"
        echo "  Expected: $expected"
        echo "  Got:      $output"
        ((FAILED++))
    fi
    echo ""
}

setup() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents"
    mkdir -p "$TEST_DIR/Applications/Jamf Connect.app/Contents"
    mkdir -p "$TEST_DIR/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/Contents"
}

echo "=========================================="
echo "JCSSP EA Extended Test Suite"
echo "=========================================="
echo ""

# ============================================
# SECTION 1: Basic Scenarios (from original)
# ============================================
echo "SECTION 1: Basic Scenarios"
echo "-------------------------------------------"

# Test 1: Nothing installed
setup
run_test "Nothing installed" $'JCMB None NotInstalled\nJCLW None NotInstalled'

# Test 2: Modern SSP deployment
setup
create_plist "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist" "3.11.0"
create_plist "$TEST_DIR/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/Contents/Info.plist" "3.5.0"
run_test "Modern SSP (JCMB 3.11.0 + JCLW 3.5.0)" $'JCMB SSP 3.11.0\nJCLW Stand-alone 3.5.0'

# Test 3: Classic deployment
setup
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "2.40.0"
run_test "Classic (2.40.0)" $'JCMB Classic 2.40.0\nJCLW Classic 2.40.0'

# Test 4: Threshold boundary
setup
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "2.45.1"
run_test "Threshold (2.45.1)" $'JCMB Classic 2.45.1\nJCLW Classic 2.45.1'

# Test 5: First split version
setup
create_plist "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist" "3.0.0"
create_plist "$TEST_DIR/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/Contents/Info.plist" "3.0.0"
run_test "First split (3.0.0)" $'JCMB SSP 3.0.0\nJCLW Stand-alone 3.0.0'

# ============================================
# SECTION 2: Multi-Version Scenarios (CRITICAL)
# ============================================
echo "SECTION 2: Multi-Version Scenarios"
echo "-------------------------------------------"

# Test 6: JCMB at BOTH locations - SSP should win
setup
create_plist "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist" "3.11.0"
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "2.45.1"
run_test "JCMB: SSP 3.11.0 + Legacy 2.45.1 (SSP wins)" $'JCMB SSP 3.11.0\nJCLW Classic 2.45.1'

# Test 7: JCMB at BOTH locations - different modern versions
setup
create_plist "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist" "3.11.0"
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "3.5.0"
run_test "JCMB: SSP 3.11.0 + Legacy 3.5.0 (SSP wins)" $'JCMB SSP 3.11.0\nJCLW Stand-alone 3.5.0'

# Test 8: JCLW at BOTH locations - Bundle should win
setup
create_plist "$TEST_DIR/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/Contents/Info.plist" "3.5.0"
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "2.44.1"
run_test "JCLW: Bundle 3.5.0 + Legacy 2.44.1 (Bundle wins)" $'JCMB Classic 2.44.1\nJCLW Stand-alone 3.5.0'

# Test 9: ALL components at BOTH locations
setup
create_plist "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist" "3.11.0"
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "2.45.1"
create_plist "$TEST_DIR/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/Contents/Info.plist" "3.5.0"
run_test "All at both locations (modern paths win)" $'JCMB SSP 3.11.0\nJCLW Stand-alone 3.5.0'

# Test 10: Mismatched architectures - old JCMB with new JCLW
setup
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "2.40.0"
create_plist "$TEST_DIR/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/Contents/Info.plist" "3.5.0"
run_test "Mismatched: Classic JCMB 2.40.0 + Modern JCLW 3.5.0" $'JCMB Classic 2.40.0\nJCLW Stand-alone 3.5.0'

# Test 11: Mismatched architectures - new JCMB with old JCLW
setup
create_plist "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist" "3.11.0"
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "2.40.0"
run_test "Mismatched: SSP JCMB 3.11.0 + Classic JCLW 2.40.0" $'JCMB SSP 3.11.0\nJCLW Classic 2.40.0'

# ============================================
# SECTION 3: Version Boundary Testing
# ============================================
echo "SECTION 3: Version Boundary Testing"
echo "-------------------------------------------"

# Test 12: Versions around threshold
setup
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "2.45.0"
run_test "Version 2.45.0 (just below threshold)" $'JCMB Classic 2.45.0\nJCLW Classic 2.45.0'

# Test 13: Versions around threshold
setup
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "2.45.2"
run_test "Version 2.45.2 (just above threshold)" $'JCMB SSP 2.45.2\nJCLW Stand-alone 2.45.2'

# Test 14: Very old version
setup
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "2.0.0"
run_test "Very old version 2.0.0" $'JCMB Classic 2.0.0\nJCLW Classic 2.0.0'

# Test 15: Future version
setup
create_plist "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist" "4.0.0"
create_plist "$TEST_DIR/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/Contents/Info.plist" "4.0.0"
run_test "Future version 4.0.0" $'JCMB SSP 4.0.0\nJCLW Stand-alone 4.0.0'

# ============================================
# SECTION 4: Partial Installation Scenarios
# ============================================
echo "SECTION 4: Partial Installation Scenarios"
echo "-------------------------------------------"

# Test 16: JCMB only at SSP
setup
create_plist "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist" "3.10.0"
run_test "JCMB SSP only (no JCLW)" $'JCMB SSP 3.10.0\nJCLW None NotInstalled'

# Test 17: JCMB only at legacy
setup
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "2.30.0"
run_test "JCMB Classic only (no JCLW)" $'JCMB Classic 2.30.0\nJCLW Classic 2.30.0'

# Test 18: JCLW only at bundle
setup
create_plist "$TEST_DIR/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/Contents/Info.plist" "3.5.0"
run_test "JCLW bundle only (no JCMB)" $'JCMB None NotInstalled\nJCLW Stand-alone 3.5.0'

# Test 19: JCLW only at legacy
setup
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "2.30.0"
run_test "JCLW Classic only (no JCMB) - legacy" $'JCMB Classic 2.30.0\nJCLW Classic 2.30.0'

# ============================================
# SECTION 5: Edge Case Stress Tests
# ============================================
echo "SECTION 5: Edge Case Stress Tests"
echo "-------------------------------------------"

# Test 20: Modern JCMB at legacy with modern JCLW at bundle
setup
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "3.5.0"
create_plist "$TEST_DIR/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/Contents/Info.plist" "3.5.0"
run_test "Both modern at legacy+bundle paths" $'JCMB SSP 3.5.0\nJCLW Stand-alone 3.5.0'

# Test 21: Old version in SSP path (shouldn't happen but testing)
setup
create_plist "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist" "2.40.0"
run_test "Old version (2.40.0) in SSP path" $'JCMB SSP 2.40.0\nJCLW None NotInstalled'

# Test 22: Three-digit minor version
setup
create_plist "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist" "3.100.5"
create_plist "$TEST_DIR/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/Contents/Info.plist" "3.100.5"
run_test "Three-digit minor version (3.100.5)" $'JCMB SSP 3.100.5\nJCLW Stand-alone 3.100.5'

# Test 23: Version with build number
setup
create_plist "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist" "3.11.0.1234"
create_plist "$TEST_DIR/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/Contents/Info.plist" "3.5.0.5678"
run_test "Version with build numbers" $'JCMB SSP 3.11.0.1234\nJCLW Stand-alone 3.5.0.5678'

# ============================================
# SECTION 6: Real-World Upgrade Scenarios
# ============================================
echo "SECTION 6: Real-World Upgrade Scenarios"
echo "-------------------------------------------"

# Test 24: Upgrade in progress - SSP installed but legacy still present
setup
create_plist "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist" "3.11.0"
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "2.45.1"
create_plist "$TEST_DIR/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/Contents/Info.plist" "3.5.0"
run_test "Upgrade scenario: New SSP + old legacy still present" $'JCMB SSP 3.11.0\nJCLW Stand-alone 3.5.0'

# Test 25: Partial upgrade - only JCMB upgraded
setup
create_plist "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist" "3.11.0"
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "2.45.1"
run_test "Partial upgrade: JCMB to SSP, JCLW still classic" $'JCMB SSP 3.11.0\nJCLW Classic 2.45.1'

# Test 26: Rollback scenario - old and new both present, old path has newer version (unusual)
setup
create_plist "$TEST_DIR/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist" "3.10.0"
create_plist "$TEST_DIR/Applications/Jamf Connect.app/Contents/Info.plist" "3.11.0"
run_test "Unusual: Legacy has newer version than SSP" $'JCMB SSP 3.10.0\nJCLW Stand-alone 3.11.0'

# ============================================
# Summary
# ============================================
echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo "Total Tests:  $TOTAL"
echo "Passed:       $PASSED"
echo "Failed:       $FAILED"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo "✓ ALL TESTS PASSED!"
    echo ""
    echo "Key Validations:"
    echo "  ✓ Basic scenarios (5 tests)"
    echo "  ✓ Multi-version handling (6 tests)"
    echo "  ✓ Version boundaries (4 tests)"
    echo "  ✓ Partial installations (4 tests)"
    echo "  ✓ Edge cases (3 tests)"
    echo "  ✓ Real-world upgrades (3 tests)"
    rm -rf "$TEST_DIR"
    exit 0
else
    echo "✗ SOME TESTS FAILED"
    echo ""
    echo "Please review failed tests above."
    rm -rf "$TEST_DIR"
    exit 1
fi
