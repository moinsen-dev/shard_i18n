# shard_i18n

**Runtime, sharded, msgid-based internationalization for Flutter - no code generation required.**

A tiny, production-ready i18n layer for Flutter that solves the pain points of traditional approaches:
- ✅ **No codegen** - Pure runtime lookups with `context.t('Sign in')`
- ✅ **Sharded by feature** - `assets/i18n/<locale>/<feature>.json` prevents merge conflicts
- ✅ **Msgid ergonomics** - Use readable English directly in code; auto-fallback if missing
- ✅ **BLoC-ready** - Tiny `LanguageCubit` drives `Locale`; UI pulls strings via context
- ✅ **Dynamic switching** - Change language at runtime without restart
- ✅ **CLDR plurals** - Proper `one/few/many/other` forms for 15+ languages
- ✅ **AI-powered CLI** - Auto-translate missing keys with OpenAI/DeepL

[![pub package](https://img.shields.io/pub/v/shard_i18n.svg)](https://pub.dev/packages/shard_i18n)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

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
| Tedious translation workflows | **AI-powered CLI** to fill missing translations |

---

## Installation

### 1. Add dependency

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  shard_i18n: ^0.1.0
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

## CLI Tool

Automate translation workflows with the included CLI.

### Verify Translations

Check for missing keys and placeholder consistency:

```bash
dart run shard_i18n_cli verify
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
dart run shard_i18n_cli fill \
  --from=en \
  --to=de,tr,fr \
  --provider=openai \
  --key=$OPENAI_API_KEY

# Using DeepL
dart run shard_i18n_cli fill \
  --from=en \
  --to=de \
  --provider=deepl \
  --key=$DEEPL_API_KEY

# Dry run (preview without writing)
dart run shard_i18n_cli fill \
  --from=en \
  --to=de \
  --provider=openai \
  --key=$OPENAI_API_KEY \
  --dry-run
```

The CLI preserves `{placeholders}` and writes translated entries to the appropriate locale files.

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

### From `flutter_gen`/`easy_localization`

1. Export your current locale files to `assets/i18n/<locale>/core.json`
2. Replace generated method calls with `context.t('msgid')`
3. Keep `GlobalMaterialLocalizations` etc. if you use them
4. Run `dart run shard_i18n_cli verify` to check consistency

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

- [ ] Rich ICU message format support (`select`, `gender`)
- [ ] Dev overlay for live-editing translations in debug mode
- [ ] VS Code extension (quick-add keys, jump to definition)
- [ ] Build-time reporting for CI (missing keys diff)
- [ ] JSON schema validation for translation files

---

## Contributing

Contributions welcome! Please:

1. Open an issue first to discuss major changes
2. Add tests for new features
3. Run `flutter test` before submitting PR
4. Follow existing code style

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
