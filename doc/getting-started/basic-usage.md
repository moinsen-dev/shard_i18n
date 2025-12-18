# Basic Usage

This guide covers common usage patterns for shard_i18n.

## Simple Translations

Use `context.t()` for simple string translations:

```dart
Text(context.t('Sign in'))
Text(context.t('Welcome to our app'))
Text(context.t('Settings'))
```

## Translations with Parameters

Use the `params` argument for string interpolation:

```dart
// JSON: "Hello, {name}!": "Hello, {name}!"
Text(context.t('Hello, {name}!', params: {'name': userName}))

// Multiple parameters
// JSON: "Welcome back, {name}! You have {count} notifications."
Text(context.t(
  'Welcome back, {name}! You have {count} notifications.',
  params: {'name': 'Alice', 'count': 5},
))
```

## Plurals

Use `context.tn()` for pluralized strings:

```dart
// JSON structure:
// "items_count": {
//   "one": "{count} item",
//   "other": "{count} items"
// }

Text(context.tn('items_count', count: 1))  // "1 item"
Text(context.tn('items_count', count: 5))  // "5 items"
```

You can also pass additional parameters:

```dart
// JSON: "user_messages": {
//   "one": "{name} has {count} message",
//   "other": "{name} has {count} messages"
// }

Text(context.tn(
  'user_messages',
  count: messageCount,
  params: {'name': 'Alice'},
))
```

## String Extensions

Since v0.2.2, you can use string extensions when BuildContext is not available:

```dart
// Simple translation
Text('Sign in'.tx)

// With parameters
Text('Hello, {name}!'.t({'name': 'World'}))

// Plurals
Text('items_count'.tn(count: 5))
```

This is useful in:
- View models or controllers
- Helper functions
- Places where context isn't accessible

## Language Switching

Change the locale at runtime:

```dart
// Switch to German
await ShardI18n.instance.setLocale(const Locale('de'));

// Switch to German (Germany)
await ShardI18n.instance.setLocale(const Locale('de', 'DE'));

// Get current locale
final currentLocale = ShardI18n.instance.locale;

// Get supported locales (auto-discovered from assets)
final locales = ShardI18n.instance.supportedLocales;
```

## Conditional Translations

Use conditional expressions for dynamic keys:

```dart
Text(context.t(isLoggedIn ? 'Sign out' : 'Sign in'))

Text(context.t(
  isAdmin ? 'admin.dashboard' : 'user.dashboard',
))
```

## Lists and Loops

Translate items in lists:

```dart
ListView.builder(
  itemCount: menuItems.length,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text(context.t(menuItems[index].titleKey)),
      subtitle: Text(context.t(menuItems[index].descriptionKey)),
    );
  },
)
```

## Error Messages

Use stable IDs for error messages:

```json
{
  "error.network": "Network connection failed",
  "error.timeout": "Request timed out",
  "error.unknown": "An unknown error occurred"
}
```

```dart
void handleError(AppError error) {
  final message = switch (error) {
    NetworkError() => context.t('error.network'),
    TimeoutError() => context.t('error.timeout'),
    _ => context.t('error.unknown'),
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

## Form Validation

Translate validation messages:

```dart
TextFormField(
  decoration: InputDecoration(
    labelText: context.t('Email'),
    hintText: context.t('Enter your email'),
  ),
  validator: (value) {
    if (value?.isEmpty ?? true) {
      return context.t('Email is required');
    }
    if (!value!.contains('@')) {
      return context.t('Invalid email format');
    }
    return null;
  },
)
```

## Debug Mode

Enable logging of missing keys during development:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable debug logging
  ShardI18n.instance.debugLogMissingKeys = true;

  await ShardI18n.instance.bootstrap(const Locale('en'));
  runApp(const MyApp());
}
```

## Next Steps

- Learn about [Sharded Files](../concepts/sharded-files.md) for organizing translations
- Explore [Pluralization](../concepts/pluralization.md) for complex plural rules
- Set up [CI/CD](../guides/ci-cd.md) for translation verification
