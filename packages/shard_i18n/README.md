# shard_i18n

**Runtime, sharded, msgid-based internationalization for Flutter - no code generation required.**

A tiny, production-ready i18n layer for Flutter that solves the pain points of traditional approaches:
- ✅ **No codegen** - Pure runtime lookups with `context.t('Sign in')` or `'Sign in'.tx`
- ✅ **Sharded by feature** - `assets/i18n/<locale>/<feature>.json` prevents merge conflicts
- ✅ **Msgid ergonomics** - Use readable English directly in code; auto-fallback if missing
- ✅ **BLoC-ready** - Tiny `LanguageCubit` drives `Locale`; UI pulls strings via context
- ✅ **Dynamic switching** - Change language at runtime without restart
- ✅ **CLDR plurals** - Proper `one/few/many/other` forms for 15+ languages
- ✅ **Automated migration** - Migrate existing apps automatically with `shard_i18n_cli`
- ✅ **AI-powered CLI** - Auto-translate missing keys with OpenAI/DeepL
- ✅ **Code-to-JSON sync** - `extract` command finds i18n usage and compares with JSON files

[![pub package](https://img.shields.io/pub/v/shard_i18n.svg)](https://pub.dev/packages/shard_i18n)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/moinsen-dev/shard_i18n/workflows/CI/badge.svg)](https://github.com/moinsen-dev/shard_i18n/actions)

📚 **[Full Documentation](https://moinsen-dev.github.io/shard_i18n/)** | 📦 **[pub.dev](https://pub.dev/packages/shard_i18n)** | 🐛 **[Issues](https://github.com/moinsen-dev/shard_i18n/issues)**

---

## Why shard_i18n?

Large teams fight over one giant ARB/JSON file and slow codegen cycles. `shard_i18n` removes those bottlenecks:

| Problem | shard_i18n Solution |
|---------|---------------------|
| Merge conflicts in monolithic translation files | **Sharded** translations by feature (`core.json`, `auth.json`, etc.) |
| Slow code generation cycles | **No codegen** - direct runtime lookups |
| Cryptic generated method names | **Natural msgid** usage: `context.t('Sign in')` |
| Complex setup for dynamic language switching | Built-in **locale switching** with `AnimatedBuilder` |
| Manual plural form management | **CLDR-based** plural resolver for 15+ languages |
| Time-consuming manual migration | **Automated migrator** extracts and transforms strings automatically |
| Tedious translation workflows | **AI-powered CLI** to fill missing translations |

---

## Installation

### 1. Add dependency

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  shard_i18n: ^0.3.0
  flutter_bloc: ^8.1.4        # for state management (optional but recommended)
  shared_preferences: ^2.2.3   # for persisting language choice (optional)

flutter:
  assets:
    - assets/i18n/
```

### 2. Create translation assets

Create sharded JSON files per locale:

```
assets/i18n/
  en/
    core.json
    auth.json
  de/
    core.json
    auth.json
  tr/
    core.json
  ru/
    core.json
```

**Example:** `assets/i18n/en/auth.json`

```json
{
  "Sign in": "Sign in",
  "Hello, {name}!": "Hello, {name}!",
  "items_count": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

**German:** `assets/i18n/de/auth.json`

```json
{
  "Sign in": "Anmelden",
  "Hello, {name}!": "Hallo, {name}!",
  "items_count": {
    "one": "{count} Artikel",
    "other": "{count} Artikel"
  }
}
```

---

## Quick Start

### 1. Bootstrap in `main()`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shard_i18n/shard_i18n.dart';
import 'language_cubit.dart'; // see below

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialLocale = await LanguageCubit.loadInitial();
  await ShardI18n.instance.bootstrap(initialLocale);

  runApp(
    BlocProvider(
      create: (_) => LanguageCubit(initialLocale),
      child: const MyApp(),
    ),
  );
}
```

### 2. Wire up MaterialApp

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LanguageCubit>().state;

    return AnimatedBuilder(
      animation: ShardI18n.instance,
      builder: (_, __) {
        return MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: ShardI18n.instance.supportedLocales,
          home: const HomePage(),
        );
      },
    );
  }
}
```

### 3. Use in widgets

```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('Hello, {name}!', params: {'name': 'World'})),
      ),
      body: Center(
        child: Text(context.tn('items_count', count: 5)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<LanguageCubit>().setLocale(Locale('de')),
        child: const Icon(Icons.language),
      ),
    );
  }
}
```

---

## API Reference

### BuildContext Extensions

```dart
// Simple translation with interpolation
context.t('Hello, {name}!', params: {'name': 'Alice'})

// Plural forms (automatically selects one/few/many/other based on locale)
context.tn('items_count', count: 5)
```

### String Extensions

For even more concise code, use string extensions (no `context` required):

```dart
// Simple translation (getter)
Text('Hello World'.tx)

// Translation with parameters
Text('Hello, {name}!'.t({'name': 'Alice'}))

// Plural forms
Text('items_count'.tn(count: 5))
```

| Method | Description | Example |
|--------|-------------|---------|
| `.tx` | Simple translation (getter) | `'Sign in'.tx` |
| `.t()` | Translation with optional params | `'Hello, {name}!'.t({'name': 'World'})` |
| `.tn()` | Pluralization with count | `'items_count'.tn(count: 5)` |

> **Note:** String extensions use `ShardI18n.instance` directly, so they work anywhere - in widgets, controllers, or utility classes.

### ShardI18n Singleton

```dart
// Bootstrap before runApp
await ShardI18n.instance.bootstrap(Locale('en'));

// Change locale at runtime
await ShardI18n.instance.setLocale(Locale('de'));

// Get current locale
ShardI18n.instance.locale

// Get discovered locales from assets
ShardI18n.instance.supportedLocales

// Register custom plural rules
ShardI18n.instance.registerPluralRule('fr', (n) => n <= 1 ? 'one' : 'other');

// Clear cache (useful for testing)
ShardI18n.instance.clearCache();
```

### LanguageCubit (Example)

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shard_i18n/shard_i18n.dart';

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit(super.initialLocale);

  static const _k = 'app_locale';

  static Future<Locale> loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_k);
    if (saved != null && saved.isNotEmpty) {
      final p = saved.split('-');
      return p.length == 2 ? Locale(p[0], p[1]) : Locale(p[0]);
    }
    return WidgetsBinding.instance.platformDispatcher.locale;
  }

  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;
    await ShardI18n.instance.setLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    final tag = locale.countryCode?.isNotEmpty == true
        ? '${locale.languageCode}-${locale.countryCode}'
        : locale.languageCode;
    await prefs.setString(_k, tag);
    emit(locale);
  }
}
```

---

## Features

### 1. Msgid vs. Stable IDs

By default, use **natural English msgids** for readability:

```dart
Text(context.t('Sign in'))
```

Switch to **stable IDs** when English copy is volatile:

```dart
Text(context.t('auth.sign_in'))
```

The lookup works for both! English translation file becomes:

```json
{
  "auth.sign_in": "Sign in"
}
```

### 2. Interpolation

Named placeholders using `{name}` syntax:

```json
{
  "Hello, {name}!": "Hallo, {name}!"
}
```

```dart
context.t('Hello, {name}!', params: {'name': 'Uli'})
```

### 3. Plurals (CLDR-style)

Define plural forms matching your locale's rules:

```json
{
  "items_count": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

**Russian** (complex `one/few/many/other`):

```json
{
  "items_count": {
    "one": "{count} предмет",
    "few": "{count} предмета",
    "many": "{count} предметов",
    "other": "{count} предмета"
  }
}
```

**Turkish** (no plural distinction):

```json
{
  "items_count": {
    "other": "{count} öğe"
  }
}
```

Supported plural rules: `en`, `de`, `nl`, `sv`, `no`, `da`, `fi`, `it`, `es`, `pt`, `tr`, `ro`, `bg`, `el`, `hu`, `ru`, `uk`, `sr`, `hr`, `bs`, `pl`, `cs`, `sk`, `fr`, `lt`, `lv`.

### 4. Fallback Strategy

```
1. Locale + country (e.g., de-DE)
   ↓ (if missing)
2. Locale language (e.g., de)
   ↓ (if missing)
3. English (en)
   ↓ (if missing)
4. Msgid/stable ID itself (developer-friendly)
```

### 5. Dynamic Locale Switching

```dart
await context.read<LanguageCubit>().setLocale(Locale('de'));
```

ShardI18n hot-loads the new locale's shards and notifies `AnimatedBuilder` to rebuild the UI. No app restart required!

---

## CLI Tools

shard_i18n includes two powerful CLI tools to streamline your i18n workflow:

### Installation

**Global installation (recommended):**

```bash
# Install globally
dart pub global activate shard_i18n

# Use commands directly
shard_i18n_cli verify
shard_i18n_cli analyze lib/
```

**Local execution (without global install):**

```bash
# Run from your project directory
dart run shard_i18n_cli verify
dart run shard_i18n_cli analyze lib/
```

---

## 1. Translation Management CLI (`shard_i18n_cli`)

Manage and automate translation workflows.

### Verify Translations

Check for missing keys and placeholder consistency:

```bash
shard_i18n_cli verify
# or: dart run shard_i18n_cli verify
```

Output:

```
🔍 Verifying translations in: assets/i18n

📁 Found locales: en, de, tr, ru

📊 Reference locale: en (15 keys)

  de:
    ✅ All keys present (15 keys)

  tr:
    ⚠️  Missing 2 key(s):
       - Welcome to shard_i18n
       - Features

  ru:
    ✅ All keys present (15 keys)
```

### Fill Missing Translations

Auto-translate missing keys using AI:

```bash
# Using OpenAI
shard_i18n_cli fill \
  --from=en \
  --to=de,tr,fr \
  --provider=openai \
  --key=$OPENAI_API_KEY

# Using DeepL
shard_i18n_cli fill \
  --from=en \
  --to=de \
  --provider=deepl \
  --key=$DEEPL_API_KEY

# Dry run (preview without writing)
shard_i18n_cli fill \
  --from=en \
  --to=de \
  --provider=openai \
  --key=$OPENAI_API_KEY \
  --dry-run
```

The CLI preserves `{placeholders}` and writes translated entries to the appropriate locale files.

### Extract i18n Keys from Code (NEW in v0.3.0)

Scan your source code to find all i18n usage and compare with JSON files:

```bash
# Basic usage - find discrepancies
shard_i18n_cli extract

# JSON output for CI/CD
shard_i18n_cli extract --format=json --strict

# Auto-fix missing keys
shard_i18n_cli extract --fix

# Remove orphaned keys
shard_i18n_cli extract --prune

# Preview changes
shard_i18n_cli extract --fix --dry-run
```

**Features:**
- Detects all i18n patterns: `context.t()`, `context.tn()`, `'key'.tx`, `'key'.t()`, `'key'.tn()`
- Three output formats: `text`, `json`, `diff`
- `--strict` mode for CI (exit code 1 on issues)
- `--fix` auto-generates missing entries
- `--prune` removes orphaned keys from JSON
- Validates placeholder consistency
- Checks plural form structure

**Example output:**
```
🔍 Scanning lib/ for i18n usage...

✅ Statistics:
   Files scanned:     42
   Keys in code:      156
   Keys in JSON:      160
   Matched:           152 (97.4%)
   Missing in JSON:   4
   Orphaned in JSON:  8

❌ Missing in JSON (4):
   • "New feature text"
   • "Upload failed: {error}"
```

---

## 2. Migration Tool (`shard_i18n_cli`)

Automatically migrate existing Flutter apps to use shard_i18n. The migrator analyzes your codebase, extracts translatable strings, and transforms your code to use the shard_i18n API.

### Analyze Your Project

Preview what strings will be extracted without making changes:

```bash
shard_i18n_cli analyze lib/
# or: dart run shard_i18n_cli analyze lib/
```

Output shows:
- Total translatable strings found
- Breakdown by category (extractable, technical, ambiguous)
- Confidence scores
- Strings with interpolation and plurals

**Options:**
- `--verbose` - Show detailed analysis per file
- `--config=path/to/config.yaml` - Use custom configuration

### Migrate Your Project

Transform your code to use shard_i18n:

```bash
# Dry run (preview changes without writing)
shard_i18n_cli migrate lib/ --dry-run

# Interactive mode (asks for confirmation on ambiguous strings)
shard_i18n_cli migrate lib/

# Automatic mode (extracts everything above confidence threshold)
shard_i18n_cli migrate lib/ --auto
```

**What it does:**
1. **Analyzes** all Dart files in the specified directory
2. **Extracts** translatable strings (UI text, error messages, etc.)
3. **Transforms** code to use `context.t()` and `context.tn()` for plurals
4. **Generates** JSON translation files in `assets/i18n/en/`
5. **Adds** necessary imports (`package:shard_i18n/shard_i18n.dart`)
6. **Preserves** interpolation parameters and plural forms

**Migration options:**
- `--dry-run` - Preview without modifying files
- `--auto` - Skip interactive prompts for ambiguous strings
- `--verbose` - Show detailed migration progress
- `--config=path` - Use custom migration config
- `--threshold=0.8` - Set confidence threshold (0.0-1.0)

### Configuration

Create a `shard_i18n_config.yaml` for fine-tuned migration:

```yaml
# Minimum confidence score to auto-extract (0.0 - 1.0)
autoExtractThreshold: 0.7

# Directories to exclude from analysis
excludePaths:
  - lib/generated/
  - test/
  - .dart_tool/

# Patterns to skip (regex)
skipPatterns:
  - '^[A-Z_]+$'  # ALL_CAPS constants
  - '^\d+$'      # Pure numbers

# Feature-based sharding
sharding:
  enabled: true
  defaultFeature: core
  # Map directories to features
  featureMapping:
    lib/auth/: auth
    lib/settings/: settings
    lib/profile/: profile
```

### Migration Workflow

**Recommended workflow for existing apps:**

1. **Analyze first:**
   ```bash
   shard_i18n_cli analyze lib/ --verbose
   ```

2. **Test on a single feature:**
   ```bash
   shard_i18n_cli migrate lib/auth/ --dry-run
   shard_i18n_cli migrate lib/auth/
   ```

3. **Run tests:**
   ```bash
   flutter test
   ```

4. **Migrate remaining code:**
   ```bash
   shard_i18n_cli migrate lib/ --auto
   ```

5. **Verify translations:**
   ```bash
   shard_i18n_cli verify
   ```

**Interactive mode** is recommended for the first migration - it prompts for confirmation on strings with low confidence scores, helping you avoid extracting technical strings or constants.

---

## Folder Structure (Best Practices)

```
assets/i18n/
  en/              # Source locale
    core.json      # App-wide strings
    auth.json      # Authentication feature
    settings.json  # Settings feature
  de/              # German translations
    core.json
    auth.json
    settings.json
  tr/              # Turkish translations
    core.json
    auth.json
  ru/              # Russian translations
    core.json
```

**Why sharded?**
- **Fewer merge conflicts**: Feature teams work on separate files
- **Faster loading**: Only current locale loaded (not all languages)
- **Easier maintenance**: Clear ownership per feature

---

## Testing

### Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shard_i18n/shard_i18n.dart';

void main() {
  test('interpolation works', () {
    final result = ShardI18n.instance.translate(
      'Hello, {name}!',
      params: {'name': 'World'},
    );
    expect(result, equals('Hello, World!'));
  });
}
```

### Widget Tests

```dart
testWidgets('displays translated text', (tester) async {
  await ShardI18n.instance.bootstrap(Locale('de'));
  await tester.pumpWidget(MyApp());
  expect(find.text('Anmelden'), findsOneWidget); // German "Sign in"
});
```

---

## Migration Guide

### Automated Migration (Recommended)

Use the **shard_i18n_cli** tool for automated migration from any existing i18n solution:

```bash
# 1. Analyze your codebase
shard_i18n_cli analyze lib/ --verbose

# 2. Run migration (interactive mode)
shard_i18n_cli migrate lib/

# 3. Review changes and test
flutter test

# 4. Verify translations
shard_i18n_cli verify
```

The migrator automatically:
- ✅ Extracts translatable strings from your code
- ✅ Transforms to `context.t()` and `context.tn()` calls
- ✅ Generates JSON translation files
- ✅ Preserves interpolation and plural forms
- ✅ Adds necessary imports

See the [Migration Tool section](#2-migration-tool-shard_i18n_cli) above for detailed usage.

### Manual Migration

If you prefer manual migration or have a unique setup:

1. Export your current locale files to `assets/i18n/<locale>/core.json`
2. Replace generated method calls with `context.t('msgid')`
3. Keep `GlobalMaterialLocalizations` etc. if you use them
4. Run `shard_i18n_cli verify` to check consistency

**Mixed mode** is fine: Keep legacy screens on old i18n while moving new features to `shard_i18n`.

---

## Performance

- **Startup**: Only current locale shards loaded (lazy, async)
- **Locale switch**: ~50-100ms for typical app (depends on shard count)
- **Lookups**: O(1) HashMap lookups in memory
- **Interpolation**: Simple regex replace
- **Best practice**: Keep shards <5-10k lines each

---

## Roadmap

- [x] ~~Build-time reporting for CI (missing keys diff)~~ - Added in v0.3.0 with `extract` command
- [ ] Rich ICU message format support (`select`, `gender`)
- [ ] Dev overlay for live-editing translations in debug mode
- [ ] VS Code extension (quick-add keys, jump to definition)
- [ ] JSON schema validation for translation files

---

## Contributing

Contributions welcome! Please:

1. Open an issue first to discuss major changes
2. Add tests for new features
3. Run `flutter test` before submitting PR
4. Follow existing code style

### For Maintainers

This package uses automated publishing via GitHub Actions. See [PUBLISHING.md](PUBLISHING.md) for details on releasing new versions.

**Quick release process:**
1. Update version in `pubspec.yaml` and `CHANGELOG.md`
2. Run `./scripts/pre_publish_check.sh` to verify readiness
3. Create and push a version tag: `git tag -a v0.2.0 -m "Release 0.2.0" && git push origin v0.2.0`
4. GitHub Actions will automatically publish to pub.dev

---

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/moinsen-dev/shard_i18n/issues)
- **Discussions**: [GitHub Discussions](https://github.com/moinsen-dev/shard_i18n/discussions)
- **Email**: support@moinsen.dev

---

**Made with ❤️ by the moinsen team**
