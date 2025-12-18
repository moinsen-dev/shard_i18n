# ShardI18n Class

The `ShardI18n` class is the core singleton that manages all internationalization functionality.

## Overview

```dart
import 'package:shard_i18n/shard_i18n.dart';

// Access the singleton instance
final i18n = ShardI18n.instance;
```

## Properties

### instance

```dart
static ShardI18n get instance
```

Returns the singleton instance. Always use this to access ShardI18n.

### locale

```dart
Locale get locale
```

Returns the currently active locale.

```dart
final current = ShardI18n.instance.locale;
print(current.languageCode);  // "en"
```

### supportedLocales

```dart
List<Locale> get supportedLocales
```

Returns all locales discovered from the assets directory.

```dart
final locales = ShardI18n.instance.supportedLocales;
// [Locale('en'), Locale('de'), Locale('fr')]
```

### isBootstrapped

```dart
bool get isBootstrapped
```

Returns `true` if `bootstrap()` has been called successfully.

```dart
if (ShardI18n.instance.isBootstrapped) {
  // Safe to use translations
}
```

### debugLogMissingKeys

```dart
bool debugLogMissingKeys
```

When `true`, logs missing translation keys to the console. Default: `false`.

```dart
ShardI18n.instance.debugLogMissingKeys = true;
```

## Methods

### bootstrap()

```dart
Future<void> bootstrap(Locale locale)
```

Initializes the i18n system. Must be called before `runApp()`.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ShardI18n.instance.bootstrap(const Locale('en'));
  runApp(const MyApp());
}
```

**Parameters:**
- `locale` - The initial locale to load

**Throws:**
- `StateError` if called more than once

### setLocale()

```dart
Future<void> setLocale(Locale locale)
```

Changes the active locale at runtime. Triggers UI rebuild via `notifyListeners()`.

```dart
await ShardI18n.instance.setLocale(const Locale('de'));
```

**Parameters:**
- `locale` - The new locale to switch to

### translate()

```dart
String translate(String key, {Map<String, Object?> params = const {}})
```

Translates a key with optional parameter interpolation.

```dart
final text = ShardI18n.instance.translate(
  'Hello, {name}!',
  params: {'name': 'World'},
);
// "Hello, World!"
```

**Parameters:**
- `key` - The translation key (msgid)
- `params` - Optional map of placeholder values

**Returns:** The translated string, or the key itself if not found.

### plural()

```dart
String plural(
  String key, {
  required num count,
  Map<String, Object?> params = const {},
})
```

Returns the correct plural form based on count.

```dart
final text = ShardI18n.instance.plural(
  'items_count',
  count: 5,
  params: {'name': 'Cart'},
);
// "5 items"
```

**Parameters:**
- `key` - The translation key
- `count` - The number to determine plural form
- `params` - Optional additional parameters

### registerPluralRule()

```dart
void registerPluralRule(String langCode, String Function(num) rule)
```

Registers a custom plural rule for a language.

```dart
ShardI18n.instance.registerPluralRule('custom', (num n) {
  if (n == 0) return 'zero';
  if (n == 1) return 'one';
  if (n >= 2 && n <= 4) return 'few';
  return 'other';
});
```

**Parameters:**
- `langCode` - The language code (e.g., 'en', 'de')
- `rule` - Function that returns the plural category

### clearCache()

```dart
void clearCache()
```

Clears the translation cache. Useful in testing.

```dart
ShardI18n.instance.clearCache();
```

## ChangeNotifier

`ShardI18n` extends `ChangeNotifier`, allowing widgets to react to locale changes:

```dart
AnimatedBuilder(
  animation: ShardI18n.instance,
  builder: (context, _) {
    return MaterialApp(
      locale: ShardI18n.instance.locale,
      // ...
    );
  },
)
```

## Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:shard_i18n/shard_i18n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable debug logging
  ShardI18n.instance.debugLogMissingKeys = true;

  // Bootstrap with English
  await ShardI18n.instance.bootstrap(const Locale('en'));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ShardI18n.instance,
      builder: (context, _) {
        return MaterialApp(
          locale: ShardI18n.instance.locale,
          supportedLocales: ShardI18n.instance.supportedLocales,
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using translate directly
            Text(ShardI18n.instance.translate('Welcome')),

            // Using plural directly
            Text(ShardI18n.instance.plural('items_count', count: 5)),

            // Switch language
            ElevatedButton(
              onPressed: () async {
                await ShardI18n.instance.setLocale(const Locale('de'));
              },
              child: const Text('Switch to German'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Thread Safety

`ShardI18n` is designed for use on the main isolate. Translation loading is async but thread-safe for typical Flutter usage patterns.
