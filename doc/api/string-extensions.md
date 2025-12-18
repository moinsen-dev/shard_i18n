# String Extensions

Since v0.2.2, shard_i18n provides extension methods on `String` for translating without `BuildContext`.

## Import

```dart
import 'package:shard_i18n/shard_i18n.dart';
```

## When to Use

String extensions are useful when:
- BuildContext is not available
- Working in view models or controllers
- Helper functions outside widgets
- More concise code is preferred

## Properties and Methods

### tx (getter)

```dart
String get tx
```

Simple translation without parameters.

```dart
final text = 'Sign in'.tx;
final welcome = 'Welcome'.tx;
```

### t()

```dart
String t([Map<String, Object?> params = const {}])
```

Translation with optional parameters.

```dart
final greeting = 'Hello, {name}!'.t({'name': 'World'});
final message = 'You have {count} items'.t({'count': 5});
```

### tn()

```dart
String tn({required num count, Map<String, Object?> params = const {}})
```

Plural translation.

```dart
final items = 'items_count'.tn(count: 5);
final messages = 'messages_count'.tn(count: 1);
```

With additional parameters:

```dart
final result = 'user_posts'.tn(
  count: 10,
  params: {'name': 'Alice'},
);
// "Alice has 10 posts"
```

## Comparison

### Context Extensions vs String Extensions

```dart
// Context extensions (requires BuildContext)
Text(context.t('Sign in'))
Text(context.t('Hello, {name}!', params: {'name': 'World'}))
Text(context.tn('items_count', count: 5))

// String extensions (no BuildContext needed)
Text('Sign in'.tx)
Text('Hello, {name}!'.t({'name': 'World'}))
Text('items_count'.tn(count: 5))
```

Both produce identical results.

## Use Cases

### View Models

```dart
class CartViewModel extends ChangeNotifier {
  int _itemCount = 0;

  String get itemCountText => 'items_count'.tn(count: _itemCount);
  String get checkoutButtonText => 'Checkout'.tx;

  String getGreeting(String name) {
    return 'Hello, {name}!'.t({'name': name});
  }
}
```

### Helper Functions

```dart
String formatPrice(double price, String currency) {
  return 'Price: {amount} {currency}'.t({
    'amount': price.toStringAsFixed(2),
    'currency': currency,
  });
}

String getErrorMessage(ErrorType type) {
  return switch (type) {
    ErrorType.network => 'error.network'.tx,
    ErrorType.timeout => 'error.timeout'.tx,
    _ => 'error.unknown'.tx,
  };
}
```

### Data Classes

```dart
class Product {
  final String nameKey;
  final String descriptionKey;
  final int stockCount;

  Product({
    required this.nameKey,
    required this.descriptionKey,
    required this.stockCount,
  });

  String get localizedName => nameKey.tx;
  String get localizedDescription => descriptionKey.tx;
  String get stockText => 'stock_count'.tn(count: stockCount);
}
```

### Service Layer

```dart
class NotificationService {
  void showWelcome(String userName) {
    final message = 'Welcome, {name}!'.t({'name': userName});
    _showNotification(message);
  }

  void showItemAdded(int count) {
    final message = 'cart_items'.tn(count: count);
    _showNotification(message);
  }
}
```

### Stream Transformations

```dart
Stream<String> translateStream(Stream<String> keys) {
  return keys.map((key) => key.tx);
}
```

## Examples

### In Widgets

```dart
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(product.nameKey.tx),
          Text(product.descriptionKey.tx),
          Text('In stock'.tx),
          Text('stock_count'.tn(count: product.stock)),
        ],
      ),
    );
  }
}
```

### Computed Properties

```dart
class Order {
  final List<OrderItem> items;
  final double total;

  Order({required this.items, required this.total});

  String get summaryText {
    final itemText = 'items_count'.tn(count: items.length);
    final totalText = 'Total: {amount}'.t({'amount': '\$${total.toStringAsFixed(2)}'});
    return '$itemText - $totalText';
  }
}
```

## JSON Structure

Same as context extensions:

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

## Best Practices

1. **Prefer context extensions in widgets** - They're more explicit about the i18n source
2. **Use string extensions for logic** - View models, services, helpers
3. **Be consistent** - Pick one style per file/class
4. **Ensure bootstrap is called** - Extensions require `ShardI18n` to be initialized
5. **Handle initialization** - Check `isBootstrapped` before using in edge cases
