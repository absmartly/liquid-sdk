# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security
- Fixed XSS vulnerabilities in example templates by using proper JSON escaping
- Removed API key exposure from client-side example templates
- Added security documentation for safe template usage

### Fixed
- Removed thread-unsafe global state (`current_context`) to prevent cross-user data contamination
- Added comprehensive exception handling throughout SDK to prevent page crashes
- Added `ready?` checks consistently across all tags and filters
- Fixed regex patterns to support experiment names with hyphens and dots
- Fixed track filter to check `ready?` consistently with other filters
- Fixed Drop methods to return results from track operations
- Added input validation for all Drop methods
- Fixed null reference errors in example templates

### Added
- Comprehensive logging throughout SDK with configurable logger
- Strict mode option for fail-fast behavior in development/staging
- Better error messages for syntax errors in tags
- Warnings when context is missing or not ready
- Warnings when tracking events are dropped

### Changed
- Removed global fallback in filters (now requires explicit Drop injection)
- Improved property parsing in TrackTag to handle more complex values
- Changed Drop to use `attr_reader` for cleaner code
- Simplified filter implementations using `with_ready_context` helper

### Removed
- Removed `ABsmartly::Liquid.current_context` global variable (thread-unsafe)
- Removed duplicate `liquid` dependency from Gemfile
- Removed unused `rack-test` dependency from Gemfile
- Removed `.DS_Store` files from repository

## [1.0.0] - Initial Release

### Added
- Initial release of ABsmartly Liquid SDK
- Support for Shopify Liquid templates
- Filters for treatment assignment and variable resolution
- Tags for treatment blocks and event tracking
- Drop object for template integration
- Example Shopify theme templates
