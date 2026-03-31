# Changelog

All notable changes to shard_i18n will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-03-31

### Changed
- **BREAKING: Package split into workspace** — `shard_i18n` (runtime) and
  `shard_i18n_cli` (CLI + migrator) are now separate packages in a Dart workspace
- `debugLogMissingKeys` now defaults to `false`
- Unified CLI: migrator commands (`migrate`, `analyze`, `init`) merged into `shard_i18n_cli`
- Interpolation RegExp compiled once as static field (minor perf improvement)

### Added
- `resetForTesting()` method for test isolation (`@visibleForTesting`)
- `loadTranslationsForTesting()` method for unit testing without asset bundle
- 61 tests (up from 12) covering core runtime, extensions, and CLI tools

### Removed
- `shard_i18n_migrator` as separate executable (use `shard_i18n_cli migrate`)
- `shard_i18n_migrator.dart` library export from runtime package

### Migration from 0.3.x
- `import 'package:shard_i18n/shard_i18n.dart'` — unchanged
- CLI: `dart run shard_i18n_cli verify` (instead of `dart run shard_i18n:shard_i18n_cli verify`)
- If you used `debugLogMissingKeys`, note it now defaults to `false`

---

## [0.3.2] - 2025-12-18

### Changed
- Bumped version for dependency updates

---

## [0.3.1] - 2025-12-18

### Fixed
- Reformatted code to ensure pub.dev analyzer compatibility
- Updated `.gitignore` to allow markdown documentation files in `doc/api/`

### Changed
- Enabled automated GitHub publishing via OIDC token authentication
- Added GitHub Pages workflow for automatic documentation deployment

---

## [0.3.0] - 2025-12-18

### Added

#### New CLI Command: `extract`
- **Source code scanning** - Detect all i18n API usage patterns in Dart files:
  - `context.t('key')` / `context.t('key', params: {...})`
  - `context.tn('key', count: n)`
  - `'key'.tx` (getter)
  - `'key'.t({...})` / `'key'.tn(count: n)`
- **JSON comparison** - Compare extracted keys against translation files
- **Output formats**:
  - `text` - Human-readable with statistics
  - `json` - Machine-readable for CI/CD integration
  - `diff` - Git-style `+`/`-` format
- **Auto-fix mode** (`--fix`) - Generate missing entries in reference locale
- **Prune mode** (`--prune`) - Remove orphaned keys not found in code
- **Strict mode** (`--strict`) - Exit code 1 on discrepancies (for CI)
- **Placeholder validation** - Detect mismatches between code and JSON
- **Plural form validation** - Check for proper plural structures
- **Verbose mode** (`-v`) - Show per-file breakdown of found keys

#### Documentation Site
- **Docsify-based documentation** - Zero build step, GitHub Pages ready
- **Getting Started** - Installation, quick start, basic usage guides
- **Core Concepts** - Msgid translations, sharded files, fallback strategy, pluralization, interpolation
- **API Reference** - Complete documentation of ShardI18n class, extensions, plural rules
- **CLI Tools** - Detailed documentation for verify, fill, and extract commands
- **Migrator** - Step-by-step guides for migrating from gen_l10n and easy_localization
- **Guides** - Migration, BLoC integration, testing, CI/CD
- **Advanced Topics** - Custom plural rules, performance optimization, large apps

### Changed
- CLI version updated to 0.3.0
- Added `analyzer` dependency for AST parsing in extract command

### Fixed
- Closes [#2](https://github.com/moinsen-dev/shard_i18n/issues/2) - Add `extract` command

---

## [0.2.2] - 2025-12-03

### Added
- **String extensions** - New `ShardI18nStringX` extension for translating strings without BuildContext:
  - `.tx` getter for simple translations: `'Hello World'.tx`
  - `.t()` method with parameters: `'Hello, {name}!'.t({'name': 'World'})`
  - `.tn()` method for plurals: `'items_count'.tn(count: 5)`
  - Useful when context is not available or for more concise code

---

## [0.2.1] - 2025-12-03

### Fixed
- **BREAKING: Flutter 3.38+ compatibility** - Migrated from deprecated `AssetManifest.json` to the new `AssetManifest` API
  - Flutter 3.38 removed `AssetManifest.json` which broke locale discovery and translation loading
  - Now uses `AssetManifest.loadFromAssetBundle()` which is the official Flutter 3.x+ API
  - Cached `AssetManifest` instance for better performance
  - Added debug logging for translation file discovery

---

## [0.2.0] - 2025-12-03

### Changed
- **Dependencies updated** for pub.dev compatibility:
  - `analyzer: ^8.4.1` → `^9.0.0` (latest stable)
  - `http: ^1.5.0` → `^1.6.0`
  - `mockito: ^5.5.1` → `^5.6.1`
  - `build_runner: ^2.10.1` → `^2.10.4`
  - `json_serializable: ^6.11.1` → `^6.11.3`

### Fixed
- **Code formatting** - Applied `dart format` to all Dart files to match Dart style guidelines
- **pub.dev score** - Resolved static analysis warnings and dependency compatibility issues

---

## [0.1.0] - 2025-01-04

### Added

#### Core Features
- **ShardI18n singleton** - Main i18n manager with ChangeNotifier for reactive UI updates
- **Runtime translation lookups** - No code generation required
- **Sharded JSON architecture** - Organize translations by feature to minimize merge conflicts
- **Msgid-based lookups** - Use natural English directly in code with automatic fallback
- **BuildContext extensions** - Convenient `context.t()` and `context.tn()` methods
- **String interpolation** - Named placeholders with `{param}` syntax
- **CLDR plural rules** - Support for 15+ languages with proper one/few/many/other forms:
  - English, German, Dutch, Swedish, Norwegian, Danish, Finnish, Italian, Spanish, Portuguese
  - Turkish (no plural distinction)
  - Russian, Ukrainian, Serbian, Croatian, Bosnian (complex Slavic rules)
  - Polish (complex one/few/many/other)
  - Czech, Slovak (one/few/other)
  - French, Romanian, Lithuanian, Latvian (special cases)
- **Dynamic locale switching** - Change language at runtime without app restart
- **Multi-level fallback** - locale+country → locale → en → msgid
- **Automatic locale discovery** - Scans AssetManifest.json to find available locales
- **Debug logging** - Missing key detection with one-time logging to prevent spam
- **Cache management** - Efficient caching with manual clearCache() for testing

#### Example App
- **Full integration example** - Complete working app demonstrating all features
- **LanguageCubit** - BLoC-based state management for locale switching
- **SharedPreferences** - Persist user's language choice across app restarts
- **Language picker** - Beautiful modal bottom sheet for selecting languages
- **Feature demonstrations**:
  - Simple translations
  - Interpolation with parameters
  - Plural forms with dynamic counts
  - Runtime locale switching
  - Native language names

#### CLI Tool
- **`verify` command** - Check translation consistency across locales
  - Detect missing keys
  - Validate placeholder parity (`{name}` exists in all translations)
  - Report extra keys
  - Summary statistics
- **`fill` command** - Auto-translate missing keys using AI providers
  - **OpenAI** integration (GPT-4o-mini) with placeholder preservation
  - **DeepL** integration with professional translation quality
  - Batch translation with rate limiting
  - Dry-run mode for preview
  - Automatic plural form handling
  - Writes to appropriate locale files with pretty formatting

#### Translation Assets
- **Example translations** for en, de, tr, ru locales
- **Demonstration of all features**:
  - Simple strings
  - Interpolation
  - English/German/Turkish plural forms (one/other)
  - Russian plural forms (one/few/many/other)
  - Feature-based sharding (core.json, auth.json)

#### Testing
- **Comprehensive unit tests** - 50+ test cases covering:
  - Singleton pattern
  - String interpolation (single/multiple/missing/null placeholders)
  - All plural rules for supported languages
  - BuildContext extensions
  - Locale tag conversion
  - Edge cases
- **High test coverage** of core functionality

#### Documentation
- **Comprehensive README.md**:
  - Feature overview with comparison table
  - Installation guide
  - Quick start tutorial
  - Complete API reference
  - CLI tool documentation
  - Migration guide from other i18n solutions
  - Performance considerations
  - Testing examples
  - Best practices
- **Inline DartDoc comments** on all public APIs
- **Example code** throughout documentation
- **CHANGELOG.md** with full release notes

### Technical Details
- **Minimum Flutter version**: 1.17.0
- **Minimum Dart SDK**: ^3.9.2
- **Dependencies**:
  - `args: ^2.4.2` (CLI)
  - `http: ^1.1.2` (AI providers)
  - `path: ^1.8.3` (file utilities)
- **Dev Dependencies**:
  - `flutter_lints: ^5.0.0`
  - `mockito: ^5.4.4`
  - `build_runner: ^2.4.8`

### Architecture
- **Zero-dependency core** - Only Flutter SDK required for runtime
- **Lazy loading** - Only current locale loaded on demand
- **O(1) lookups** - HashMap-based translation dictionary
- **Production-ready** - Error handling, logging, validation
- **Thread-safe** - Proper async/await patterns
- **Memory efficient** - Caching with manual control

### Known Limitations
- Asset loading requires Flutter's AssetManifest.json (no pure Dart support)
- Plural rules are pre-defined (use `registerPluralRule()` for custom languages)
- No ICU message format support (planned for future release)

## [Unreleased]

### Planned Features
- [ ] Rich ICU message format support (`select`, `gender`)
- [ ] Dev overlay for live-editing translations in debug mode
- [ ] VS Code extension (quick-add keys, jump to definition)
- [ ] Build-time reporting for CI (missing keys diff)
- [ ] JSON schema validation for translation files
- [ ] Widget tests for example app
- [ ] CLI tests with mocked file system
- [ ] GitHub Actions CI/CD pipeline
- [ ] pub.dev publication

---

[0.3.0]: https://github.com/moinsen-dev/shard_i18n/releases/tag/v0.3.0
[0.2.2]: https://github.com/moinsen-dev/shard_i18n/releases/tag/v0.2.2
[0.2.1]: https://github.com/moinsen-dev/shard_i18n/releases/tag/v0.2.1
[0.2.0]: https://github.com/moinsen-dev/shard_i18n/releases/tag/v0.2.0
[0.1.0]: https://github.com/moinsen-dev/shard_i18n/releases/tag/v0.1.0
