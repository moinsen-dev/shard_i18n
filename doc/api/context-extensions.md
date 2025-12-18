# Context Extensions

shard_i18n provides convenient extension methods on `BuildContext` for translating strings in widgets.

## Import

```dart
import 'package:shard_i18n/shard_i18n.dart';
```

## Methods

### t()

```dart
String t(String key, {Map<String, Object?> params = const {}})
```

Translates a string with optional parameter interpolation.

**Basic usage:**

```dart
Text(context.t('Sign in'))
Text(context.t('Welcome'))
Text(context.t('Settings'))
```

**With parameters:**

```dart
Text(context.t('Hello, {name}!', params: {'name': 'World'}))
Text(context.t('You have {count} notifications', params: {'count': 5}))
```

**Parameters:**
- `key` - The translation key (msgid or stable ID)
- `params` - Optional map of placeholder values to interpolate

**Returns:** The translated string, or the key itself if not found.

### tn()

```dart
String tn(String key, {required num count, Map<String, Object?> params = const {}})
```

Returns the correct plural form based on the count.

**Basic usage:**

```dart
Text(context.tn('items_count', count: 1))   // "1 item"
Text(context.tn('items_count', count: 5))   // "5 items"
Text(context.tn('items_count', count: 0))   // "0 items"
```

**With additional parameters:**

```dart
Text(context.tn(
  'user_messages',
  count: messageCount,
  params: {'name': 'Alice'},
))
// "Alice has 5 messages"
```

**Parameters:**
- `key` - The translation key for the plural string
- `count` - The number to determine which plural form to use
- `params` - Optional additional parameters (count is automatically included)

**Returns:** The correct plural form with interpolated values.

## Examples

### Simple Translations

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('Home')),
      ),
      body: Column(
        children: [
          Text(context.t('Welcome to our app')),
          Text(context.t('Get started below')),
        ],
      ),
    );
  }
}
```

### Dynamic Content

```dart
class ProfilePage extends StatelessWidget {
  final String userName;
  final int followerCount;

  const ProfilePage({
    required this.userName,
    required this.followerCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(context.t('Hello, {name}!', params: {'name': userName})),
        Text(context.tn('followers_count', count: followerCount)),
      ],
    );
  }
}
```

### Conditional Translations

```dart
class AuthButton extends StatelessWidget {
  final bool isLoggedIn;

  const AuthButton({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      child: Text(context.t(isLoggedIn ? 'Sign out' : 'Sign in')),
    );
  }
}
```

### Form Fields

```dart
class LoginForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: context.t('Email'),
            hintText: context.t('Enter your email'),
          ),
        ),
        TextFormField(
          decoration: InputDecoration(
            labelText: context.t('Password'),
            hintText: context.t('Enter your password'),
          ),
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: () {},
          child: Text(context.t('Sign in')),
        ),
      ],
    );
  }
}
```

### Lists and Loops

```dart
class MenuList extends StatelessWidget {
  final List<MenuItem> items;

  const MenuList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(context.t(item.titleKey)),
          subtitle: Text(context.t(item.descriptionKey)),
        );
      },
    );
  }
}
```

### Error Handling

```dart
void showError(BuildContext context, AppError error) {
  final message = switch (error) {
    NetworkError() => context.t('error.network'),
    TimeoutError() => context.t('error.timeout'),
    AuthError() => context.t('error.auth'),
    _ => context.t('error.unknown'),
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

## JSON Structure

For `t()`:

```json
{
  "Sign in": "Sign in",
  "Hello, {name}!": "Hello, {name}!",
  "error.network": "Network connection failed"
}
```

For `tn()`:

```json
{
  "items_count": {
    "one": "{count} item",
    "other": "{count} items"
  },
  "followers_count": {
    "one": "{count} follower",
    "other": "{count} followers"
  }
}
```

## Best Practices

1. **Use `t()` for non-plural strings**
2. **Use `tn()` only for count-based plurals**
3. **Keep keys readable** - Natural English text works best
4. **Pass all required parameters** - Missing ones show as `{placeholder}`
5. **Handle nulls before passing** - Use `??` to provide defaults
