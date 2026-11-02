# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed (BREAKING)
- `absmartly_treatment`, `absmartly_peek`, `absmartly_variable`, `absmartly_peek_variable` and `absmartly_custom_field` no longer return a fallback when the context is not yet ready. They call the SDK, which raises "ABsmartly Context is not yet ready.", and that error is raised from the filter in every mode. The `{% absmartly_treatment %}` tag and the Drop read methods (`treatment`, `peek`, `variable`, `peek_variable`, `custom_field`) behave the same way (matching the JavaScript SDK). Wait for the context to be ready before rendering these filters.

### Security
- Fixed XSS vulnerabilities in example templates by using proper JSON escaping
- Removed API key exposure from client-side example templates
- Added security documentation for safe template usage

### Fixed
- Filters prefer the Drop-injected context over the thread-unsafe global `current_context` to prevent cross-user data contamination (the global accessor remains as a deprecated fallback)
- Added comprehensive exception handling throughout SDK to prevent page crashes
- Added `ready?` checks consistently across all tags and filters
- Fixed regex patterns to support experiment names with hyphens and dots
- Fixed Drop methods to return results from track operations
- Added input validation for all Drop methods
- Fixed null reference errors in example templates

### Added
- Comprehensive logging throughout SDK with configurable logger
- Strict mode option for fail-fast behavior in development/staging
- Better error messages for syntax errors in tags
- Warnings when context is missing
- Warnings when tracking events are dropped
- `ABsmartly::Liquid::ContextUnavailableError` for missing contexts in strict mode (subclass of `RuntimeError`, same message as before)

### Changed
- Jekyll is no longer listed as supported: Jekyll 4 depends on Liquid 4, while this gem requires Liquid 5
- `absmartly_track` filter and tag no longer drop events when the context is not ready; the underlying SDK queues them (matches JS `track()`, which only rejects finalized contexts)
- Improved property parsing in TrackTag to handle more complex values
- Changed Drop to use `attr_reader` for cleaner code
- Simplified filter implementations using `with_ready_context` helper

### Removed
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
