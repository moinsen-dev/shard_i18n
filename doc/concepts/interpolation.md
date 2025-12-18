# Interpolation

shard_i18n supports named parameter interpolation using `{placeholder}` syntax.

## Basic Interpolation

Define placeholders in your JSON:

```json
{
  "Hello, {name}!": "Hello, {name}!"
}
```

Pass values via the `params` argument:

```dart
context.t('Hello, {name}!', params: {'name': 'World'})
// "Hello, World!"
```

## Multiple Parameters

Use multiple placeholders in a single string:

```json
{
  "order_confirmation": "Order #{orderId} placed for {amount} on {date}"
}
```

```dart
context.t('order_confirmation', params: {
  'orderId': '12345',
  'amount': '\$99.99',
  'date': 'Dec 18, 2025',
})
// "Order #12345 placed for $99.99 on Dec 18, 2025"
```

## Data Types

Parameters can be any type that converts to string:

```dart
context.t('You have {count} items', params: {
  'count': 42,        // int
})

context.t('Total: {amount}', params: {
  'amount': 99.99,    // double
})

context.t('Status: {active}', params: {
  'active': true,     // bool
})

context.t('User: {user}', params: {
  'user': userObject, // uses toString()
})
```

## With Plurals

Combine interpolation with plurals:

```json
{
  "user_followers": {
    "one": "{name} has {count} follower",
    "other": "{name} has {count} followers"
  }
}
```

```dart
context.tn('user_followers', count: 1000, params: {'name': 'Alice'})
// "Alice has 1000 followers"
```

Note: `{count}` is automatically available in plural forms.

## Missing Parameters

If a parameter is missing, the placeholder remains:

```dart
context.t('Hello, {name}!', params: {})
// "Hello, {name}!"
```

This helps identify missing parameters during development.

## Null Handling

Null values are handled gracefully:

```dart
context.t('Hello, {name}!', params: {'name': null})
// "Hello, !"  (null becomes empty string)
```

For explicit null handling:

```dart
context.t('Hello, {name}!', params: {
  'name': userName ?? 'Guest',
})
```

## Formatting

shard_i18n doesn't include built-in formatters. Use Dart's formatting:

```dart
// Number formatting
import 'package:intl/intl.dart';

final formatter = NumberFormat.currency(symbol: '\$');
context.t('Total: {amount}', params: {
  'amount': formatter.format(99.99),
})

// Date formatting
final dateFormatter = DateFormat.yMMMd();
context.t('Created: {date}', params: {
  'date': dateFormatter.format(DateTime.now()),
})
```

## Escaping

To include literal `{` or `}`, use double braces:

```json
{
  "code_example": "Use {{name}} for interpolation"
}
```

```dart
context.t('code_example')
// "Use {name} for interpolation"
```

## Parameter Naming

Use descriptive, consistent names:

```json
{
  "Good examples": {
    "greeting": "Hello, {userName}!",
    "order": "Order #{orderId}",
    "price": "Price: {formattedPrice}",
    "date": "Date: {formattedDate}"
  },
  "Avoid": {
    "bad1": "Hello, {x}!",
    "bad2": "Order #{1}",
    "bad3": "Price: {p}"
  }
}
```

## Common Patterns

### User Greeting

```json
{
  "welcome_back": "Welcome back, {firstName}!"
}
```

### Counts with Context

```json
{
  "search_results": "Found {count} results for \"{query}\""
}
```

### Time-based Messages

```json
{
  "last_seen": "Last seen {timeAgo}",
  "updated": "Updated {relativeTime}"
}
```

### Error Messages

```json
{
  "field_required": "{fieldName} is required",
  "min_length": "{fieldName} must be at least {min} characters",
  "max_length": "{fieldName} must be at most {max} characters"
}
```

## Best Practices

1. **Use descriptive names** - `{userName}` not `{u}`
2. **Be consistent** - Same parameter, same name everywhere
3. **Document parameters** - Help translators understand context
4. **Test with edge cases** - Empty strings, long strings, special characters
5. **Validate early** - Check required parameters before translation

## String Extensions

Interpolation also works with string extensions:

```dart
'Hello, {name}!'.t({'name': 'World'})
// "Hello, World!"
```
