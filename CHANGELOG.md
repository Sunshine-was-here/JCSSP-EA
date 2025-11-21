# Changelog

All notable changes to the Jamf Connect Extension Attribute (JCSSP EA) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.9.0] - 2025-11-19

### Changed
- Removed unused variables for ShellCheck compliance
- Simplified JCMB evaluation logic by removing dead code
- Made JCLW classification more consistent with JCMB approach
- Removed unused helper functions (`version_ge`, `get_id`)
- Removed unused SSP verification block (lines 136-149 in v1.8)

### Added
- Comprehensive test suite with 26 test scenarios
- Extended test coverage for multi-version scenarios
- Test validation for real-world upgrade scenarios
- Documentation for GitHub release
- MIT License

### Fixed
- Corrected logic flow in `evaluate_jcmb()` function
- Fixed edge case handling for modern versions at legacy paths
- Improved version-based classification consistency

### Testing
- ✅ All 26 tests passing
- ✅ Zero ShellCheck warnings
- ✅ Multi-version scenarios validated
- ✅ Edge cases thoroughly tested

## [1.8.0] - 2024

### Added
- Initial implementation of dual-component detection
- JCMB (Menu Bar) detection
- JCLW (Login Window) detection
- MODE toggle for flexible component selection
- Version threshold logic (2.45.1)
- Path-based detection for SSP vs legacy installations

### Features
- Multi-line output format for Jamf Pro
- Independent component evaluation
- Version comparison using `version_gt()`
- Support for both modern and classic architectures

---

## Version History Context

### v1.9.0 - Production Ready
- ShellCheck clean (0 warnings)
- Comprehensive testing (26/26 passing)
- Dead code removed
- GitHub release ready

### v1.8.0 - Initial Dual-Component Release
- First version with JCMB + JCLW detection
- Introduced THRESHOLD concept
- Path-based + version-based classification

---

## Upgrade Notes

### From v1.8.0 to v1.9.0
- **No Breaking Changes**: Output format unchanged
- **Behavior**: Identical functionality with cleaner code
- **Testing**: More comprehensive validation
- **Performance**: Negligible (removed dead code that never executed)

**Recommended Action**: Safe to upgrade in-place. No inventory changes expected.

---

## Future Considerations

### Potential Changes (Not Currently Planned)
- Support for additional Jamf Connect components
- Custom output formats
- Integration with other Jamf EAs

### Will NOT Change
- THRESHOLD value (2.45.1 is historically fixed)
- Output format structure
- Component classification logic
- Path detection order

---

_For detailed release notes, see the [Releases](https://github.com/YOUR_USERNAME/JCSSP-EA/releases) page._
