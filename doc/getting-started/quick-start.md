# Quick Start

Get your Flutter app internationalized in 3 simple steps.

## Step 1: Bootstrap in main()

Initialize shard_i18n before running your app:

```dart
import 'package:flutter/material.dart';
import 'package:shard_i18n/shard_i18n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bootstrap with initial locale
  await ShardI18n.instance.bootstrap(const Locale('en'));

  runApp(const MyApp());
}
```

## Step 2: Wire up MaterialApp

Wrap your `MaterialApp` with `AnimatedBuilder` to react to locale changes:

```dart
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
```

## Step 3: Use Translations in Widgets

Use the `context.t()` extension to translate strings:

```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('Welcome')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple translation
            Text(context.t('Hello, World!')),

            // With interpolation
            Text(context.t('Hello, {name}!', params: {'name': 'Flutter'})),

            // Plurals
            Text(context.tn('items_count', count: 5)),
          ],
        ),
      ),
    );
  }
}
```

## Complete Example

Here's a complete working example:

```dart
import 'package:flutter/material.dart';
import 'package:shard_i18n/shard_i18n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      appBar: AppBar(title: Text(context.t('Welcome'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.t('Hello, {name}!', params: {'name': 'World'})),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Switch to German
                await ShardI18n.instance.setLocale(const Locale('de'));
              },
              child: Text(context.t('Change Language')),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Translation File

Create `assets/i18n/en/core.json`:

```json
{
  "Welcome": "Welcome",
  "Hello, {name}!": "Hello, {name}!",
  "Change Language": "Change Language",
  "items_count": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

And `assets/i18n/de/core.json`:

```json
{
  "Welcome": "Willkommen",
  "Hello, {name}!": "Hallo, {name}!",
  "Change Language": "Sprache wechseln",
  "items_count": {
    "one": "{count} Artikel",
    "other": "{count} Artikel"
  }
}
```

## Next Steps

- Learn about [Basic Usage](basic-usage.md) patterns
- Understand [Msgid Translations](../concepts/msgid-translations.md)
- Set up [BLoC Integration](../guides/bloc-integration.md) for state management
