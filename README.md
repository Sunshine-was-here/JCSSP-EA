# Jamf Connect Extension Attribute (JCSSP EA)

A Jamf Pro Extension Attribute script that detects and classifies Jamf Connect Menu Bar (JCMB) and Jamf Connect Login Window (JCLW) components on macOS.

[![ShellCheck](https://img.shields.io/badge/shellcheck-passing-brightgreen)](https://www.shellcheck.net/)
[![Tests](https://img.shields.io/badge/tests-26%2F26%20passing-brightgreen)](#testing)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Overview

This Extension Attribute helps Jamf administrators identify:
- Which Jamf Connect components are installed (JCMB and/or JCLW)
- The deployment type (SSP, Stand-alone, or Classic)
- The version of each component
- Scenarios where multiple versions coexist

## Features

- ✅ **Accurate Detection**: Distinguishes between modern SSP-delivered and legacy standalone installations
- ✅ **Version-Aware**: Correctly classifies components based on the 2.45.1 architectural split
- ✅ **Multi-Version Handling**: Reports the active installation when multiple versions are present
- ✅ **Independent Components**: Separately evaluates JCMB and JCLW
- ✅ **Clean Output**: Easy-to-read multi-line format in Jamf Pro inventory
- ✅ **Thoroughly Tested**: 26 comprehensive test scenarios validated

## Component Types

### JCMB (Jamf Connect Menu Bar)
- **SSP**: Modern menu bar delivered via Self Service+ (version > 2.45.1)
- **Classic**: Legacy standalone Jamf Connect app (version ≤ 2.45.1)

### JCLW (Jamf Connect Login Window)
- **Stand-alone**: Modern separate login bundle (version > 2.45.1)
- **Classic**: Legacy bundled in Jamf Connect app (version ≤ 2.45.1)

## Output Format

```
JCMB SSP 3.11.0
JCLW Stand-alone 3.5.0
```

or

```
JCMB Classic 2.40.0
JCLW Classic 2.40.0
```

or

```
JCMB None NotInstalled
JCLW Stand-alone 3.5.0
```

## Installation

### Via Jamf Pro Console

1. Navigate to **Settings** → **Computer Management** → **Extension Attributes**
2. Click **New**
3. Configure:
   - **Display Name**: `Jamf Connect Components`
   - **Data Type**: `String`
   - **Input Type**: `Script`
4. Copy and paste the contents of `JCSSP_EA.sh`
5. Click **Save**
6. Scope to appropriate computers
7. Run inventory collection

### Manual Testing

```bash
# Download the script
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/JCSSP-EA/main/JCSSP_EA.sh

# Make executable
chmod +x JCSSP_EA.sh

# Run locally (requires sudo for proper paths)
sudo ./JCSSP_EA.sh
```

## Configuration

### MODE Setting (Line 42)

Control which components are evaluated:

```bash
MODE="both"   # Default: Detect both JCMB and JCLW
MODE="jcmb"   # Detect Menu Bar only
MODE="jclw"   # Detect Login Window only
```

### Version Threshold (Line 48)

```bash
THRESHOLD="2.45.1"  # Architectural split point
```

**⚠️ Important**: This should rarely/never change. It represents the historical split between bundled and separate architectures.

## Logic Overview

### Path Priority

**JCMB** (checked in order):
1. `/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/` (SSP)
2. `/Applications/Jamf Connect.app/` (Legacy)

**JCLW** (checked in order):
1. `/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/` (Modern)
2. `/Applications/Jamf Connect.app/` (Legacy)

### Classification Rules

1. **If found at modern path** → Type determined by path (SSP for JCMB)
2. **If found at legacy path** → Type determined by version vs THRESHOLD
3. **Modern path takes precedence** when multiple installations exist

### Version Comparison

- `version ≤ 2.45.1` → Classic (bundled architecture)
- `version > 2.45.1` → Modern (split architecture: SSP + Stand-alone)

## Multi-Version Scenarios

When multiple versions exist, the script prioritizes modern deployment paths:

| Scenario | Result | Explanation |
|----------|--------|-------------|
| JCMB at SSP + Legacy | SSP version reported | Modern path wins |
| JCLW at Bundle + Legacy | Bundle version reported | Modern path wins |
| SSP 3.11.0 + Legacy 2.45.1 | `JCMB SSP 3.11.0` | Correct modern deployment |
| Bundle 3.5.0 + Legacy 2.44.1 | `JCLW Stand-alone 3.5.0` | Correct modern deployment |

## Testing

The script includes comprehensive test coverage:

### Test Categories
- **Basic Scenarios** (5 tests): Standard installations
- **Multi-Version** (6 tests): Multiple installations coexisting
- **Version Boundaries** (4 tests): Threshold edge cases
- **Partial Installations** (4 tests): Single component scenarios
- **Edge Cases** (3 tests): Unusual configurations
- **Real-World Upgrades** (3 tests): Migration scenarios

### Running Tests

```bash
# Run the test suite
chmod +x test_extended.sh
sudo ./test_extended.sh
```

Expected output:
```
==========================================
TEST SUMMARY
==========================================
Total Tests:  26
Passed:       26
Failed:       0

✓ ALL TESTS PASSED!
```

## Use Cases

### Smart Groups

Create Smart Groups based on EA output:

**Modern SSP Deployment**
- Criteria: `Jamf Connect Components` `contains` `JCMB SSP`

**Missing JCLW**
- Criteria: `Jamf Connect Components` `contains` `JCLW None`

**Classic Installation**
- Criteria: `Jamf Connect Components` `contains` `Classic`

**Needs Upgrade**
- Criteria: `Jamf Connect Components` `does not contain` `SSP`
- AND: `Jamf Connect Components` `does not contain` `None`

### Advanced Reporting

Search inventory for specific patterns:
```
JCMB SSP*JCLW Stand-alone*    # Modern deployment
JCMB Classic*JCLW Classic*     # Legacy deployment
*None NotInstalled*            # Partial or missing
```

## Version History

**v1.9** (2025-11-19)
- Removed unused variables for ShellCheck compliance
- Comprehensive testing with 26 scenarios
- Production-ready release

**v1.8** (Previous)
- Multi-component detection
- Version-based classification

## Architecture Background

### Pre-2.45.1 (Classic)
- Single `Jamf Connect.app` containing both JCMB and JCLW
- Components share the same version number
- Located at `/Applications/Jamf Connect.app/`

### 3.0.0+ (Modern Split)
- **JCMB**: Delivered via Self Service+ (SSP)
  - Path: `/Applications/Self Service+.app/Contents/MacOS/Jamf Connect.app/`
  - Independent version (e.g., 3.11.0)
- **JCLW**: Separate security plugin
  - Path: `/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle/`
  - Independent version (e.g., 3.5.0)

### Current Versions (Example)
- SSP: 2.13.0
- JCMB within SSP: 3.11.0
- JCLW standalone: 3.5.0

## Troubleshooting

### No Output in Jamf Pro
- Verify the script runs without errors locally
- Check inventory collection has completed
- Ensure computers are in scope

### Unexpected Classifications
- Verify actual file paths on affected machines
- Check version numbers in Info.plist files
- Run test suite to validate logic

### Multiple Versions Detected
- This is normal during upgrades
- Modern path (SSP/Bundle) takes precedence
- Consider cleanup of legacy installations

## Requirements

- macOS 10.13+
- Jamf Pro 10.0+
- Bash/sh shell (standard on macOS)
- Root privileges (when run via Jamf Pro)

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) file for details

## Author

**Ellie Romero**

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review test suite for expected behaviors

## Acknowledgments

- Jamf Community for feedback and testing
- ShellCheck for static analysis
- Test scenarios based on real-world deployments

---

**Note**: This script is provided as-is for use with Jamf Pro. Always test in a non-production environment before deployment.
