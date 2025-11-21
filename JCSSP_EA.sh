#!/bin/sh
# Extension Attribute: Jamf Connect Menu Bar + Login Window (Combined)
# Author: Ellie Romero
# Version: 1.9 (ShellCheck Clean)
#
# Brief Description:
#   This EA identifies which Jamf Connect components are installed:
#
#     • JCMB  = Jamf Connect Menu Bar
#     • JCLW  = Jamf Connect Login Window
#
#   MODE controls which components are evaluated:
#     MODE="both"   → Detect JCMB + JCLW
#     MODE="jcmb"   → Detect Menu Bar only
#     MODE="jclw"   → Detect Login Window only
#
#   JCMB classification:
#       Found in SSP path → JCMB SSP (Menu Bar bundled with Self Service+)
#       Found in legacy path AND version > 2.45.1 → JCMB SSP (edge case)
#       Found in legacy path AND version ≤ 2.45.1 → JCMB Classic
#
#   JCLW classification:
#       Version > 2.45.1 → JCLW Stand-alone (Modern separate component)
#       Version ≤ 2.45.1 → JCLW Classic (Bundled with JCMB)
#
#   Version History Context:
#     ≤ 2.45.1: JCMB and JCLW bundled in same app
#     ≥ 3.0.0:  Split into separate apps
#               - JCLW 3.0.0+ at /Library/Security/SecurityAgentPlugins/
#               - JCMB 3.0.0+ delivered via SSP 2.0.0+
#     Current:  JCLW 3.5.0, JCMB 3.11.0 in SSP 2.13.0
#
#   Output format (stacked, clean, readable):
#       JCMB SSP 3.11.0
#       JCLW Stand-alone 3.5.0
#
##############################################################################
# MODE TOGGLE
##############################################################################

MODE="both"   # both | jcmb | jclw

##############################################################################
# Shared constants
##############################################################################

# Classic vs modern cutoff – represents architectural split
THRESHOLD="2.45.1"

##############################################################################
# Paths – Menu Bar (JCMB)
##############################################################################

SSP_MB_PLIST="/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/Contents/Info.plist"
LEGACY_MB_PLIST="/Applications/Jamf Connect.app/Contents/Info.plist"

##############################################################################
# Paths – Login Window (JCLW)
##############################################################################

JCLW_BUNDLE_PLIST="/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/Contents/Info.plist"
LEGACY_JC_PLIST="/Applications/Jamf Connect.app/Contents/Info.plist"

##############################################################################
# Helper functions
##############################################################################

version_gt() {
  v1="$1"; v2="$2"
  [ -z "$v1" ] && return 1
  [ "$(printf '%s\n%s\n' "$v1" "$v2" | sort -V | head -n1)" != "$v1" ]
}

get_ver() {
  plist="$1"
  [ -f "$plist" ] && /usr/bin/defaults read "$plist" CFBundleShortVersionString 2>/dev/null
}

##############################################################################
# Version classifying functions
##############################################################################

# JCMB → SSP or Classic (based on version if path is ambiguous)
classify_jcmb() {
  v="$1"
  version_gt "$v" "$THRESHOLD" && echo "SSP" || echo "Classic"
}

# JCLW → Stand-alone or Classic (based on version)
classify_jclw() {
  v="$1"
  version_gt "$v" "$THRESHOLD" && echo "Stand-alone" || echo "Classic"
}

##############################################################################
# 1) Evaluate Menu Bar (JCMB)
##############################################################################

evaluate_jcmb() {
  jcmb_ver=""
  jcmb_type="None"

  # Check SSP location first (modern deployment)
  if mbv="$(get_ver "$SSP_MB_PLIST")"; then
    jcmb_ver="$mbv"
    jcmb_type="SSP"
  # Check legacy location (older deployment or classic)
  elif mbv="$(get_ver "$LEGACY_MB_PLIST")"; then
    jcmb_ver="$mbv"
    # Use version to determine if this is actually a modern version in legacy location
    # or a true classic version
    jcmb_type="$(classify_jcmb "$jcmb_ver")"
  fi

  # If we found a version but couldn't determine type, use version-based classification
  if [ -n "$jcmb_ver" ] && [ "$jcmb_type" = "None" ]; then
    jcmb_type="$(classify_jcmb "$jcmb_ver")"
  fi

  # Output result
  if [ -z "$jcmb_ver" ]; then
    echo "JCMB None NotInstalled"
  else
    echo "JCMB ${jcmb_type} ${jcmb_ver}"
  fi
}

##############################################################################
# 2) Evaluate Login Window (JCLW)
##############################################################################

evaluate_jclw() {
  jclw_ver=""
  jclw_type="None"

  # Check modern bundle location first (3.0.0+)
  if v="$(get_ver "$JCLW_BUNDLE_PLIST")"; then
    jclw_ver="$v"
    # Version-based classification (should always be Stand-alone for this path)
    jclw_type="$(classify_jclw "$jclw_ver")"
  # Check legacy location (≤2.45.1 or edge cases)
  elif v="$(get_ver "$LEGACY_JC_PLIST")"; then
    jclw_ver="$v"
    # Use version to determine if this is modern or classic
    jclw_type="$(classify_jclw "$jclw_ver")"
  fi

  # Fallback classification if needed
  if [ -n "$jclw_ver" ] && [ "$jclw_type" = "None" ]; then
    jclw_type="$(classify_jclw "$jclw_ver")"
  fi

  # Output result
  if [ -z "$jclw_ver" ]; then
    echo "JCLW None NotInstalled"
  else
    echo "JCLW ${jclw_type} ${jclw_ver}"
  fi
}

##############################################################################
# 3) MODE-based behavior + stacked output
##############################################################################

case "$MODE" in
  both)
    jcmb_fragment="$(evaluate_jcmb)"
    jclw_fragment="$(evaluate_jclw)"
    echo "<result>${jcmb_fragment}
${jclw_fragment}</result>"
    ;;
  jcmb)
    echo "<result>$(evaluate_jcmb)</result>"
    ;;
  jclw)
    echo "<result>$(evaluate_jclw)</result>"
    ;;
  *)
    echo "<result>Not configured</result>"
    ;;
esac
