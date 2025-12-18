# Changelog

All notable changes to shard_i18n are documented here.

This project adheres to [Semantic Versioning](https://semver.org/).

## [0.3.0] - 2025-12-18

### Added

- **`extract` command** - Scan source code for i18n usage and compare with JSON files
  - Detects `context.t()`, `context.tn()`, `'key'.tx`, `'key'.t()`, `'key'.tn()` patterns
  - Three output formats: `text` (human-readable), `json` (machine-readable), `diff` (git-style)
  - `--fix` flag to auto-generate missing entries
  - `--prune` flag to remove orphaned keys from JSON
  - `--strict` flag for CI/CD integration (exit code 1 on discrepancies)
  - Placeholder mismatch detection
  - Plural form validation
  - Verbose mode with per-file breakdown

- **Documentation site** - Comprehensive Docsify-based documentation
  - Getting started guides
  - Core concepts explanation
  - Complete API reference
  - CLI tool documentation
  - Migration guides
  - Advanced topics

### Changed

- CLI version bumped to 0.3.0

## [0.2.2] - 2025-12-17

### Changed

- Updated `llms.txt` with complete feature documentation

## [0.2.1] - 2025-12-16

### Added

- String extensions for context-free translations
  - `'key'.tx` getter for simple translations
  - `'key'.t({...})` method for translations with parameters
  - `'key'.tn(count: n)` method for plural translations

## [0.2.0] - 2025-12-15

### Changed

- **Flutter 3.38+ compatibility** - Migrated to new AssetManifest API
- Updated dependencies to latest versions
- Applied dart format to all files

### Fixed

- Pubspec YAML warning about SDK constraints

## [0.1.0] - Initial Release

### Added

- Core `ShardI18n` class with singleton pattern
- BuildContext extensions (`context.t()`, `context.tn()`)
- Sharded JSON file organization
- Msgid-based translation approach
- CLDR plural rules for 25+ languages
- Interpolation with `{placeholder}` syntax
- Locale switching with ChangeNotifier
- Fallback chain (translation → msgid)
- CLI tools:
  - `verify` command for cross-locale consistency
  - `fill` command for AI-powered translation (OpenAI, DeepL)
- Migrator tool for gen_l10n/easy_localization migration

---

## Migration Notes

### From 0.2.x to 0.3.0

No breaking changes. The `extract` command is additive.

Recommended: Run `extract --strict` in your CI pipeline.

### From gen_l10n

See [Migration Guide](guides/migration-guide.md) for step-by-step instructions.

---

## Links

- [GitHub Repository](https://github.com/moinsen-dev/shard_i18n)
- [pub.dev Package](https://pub.dev/packages/shard_i18n)
- [Issue Tracker](https://github.com/moinsen-dev/shard_i18n/issues)
