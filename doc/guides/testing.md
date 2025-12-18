# Testing Guide

This guide covers testing strategies for apps using shard_i18n.

## Unit Testing

### Testing Translation Logic

Test code that uses translations:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shard_i18n/shard_i18n.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ShardI18n.instance.init(
      supportedLocales: [const Locale('en')],
      defaultLocale: const Locale('en'),
      basePath: 'assets/i18n',
    );
  });

  test('greeting message includes name', () {
    final message = ShardI18n.instance.translate(
      'Hello, {name}!',
      params: {'name': 'Alice'},
    );
    expect(message, 'Hello, Alice!');
  });

  test('plural forms work correctly', () {
    expect(
      ShardI18n.instance.translatePlural('item_count', 0),
      'No items',
    );
    expect(
      ShardI18n.instance.translatePlural('item_count', 1),
      '1 item',
    );
    expect(
      ShardI18n.instance.translatePlural('item_count', 5),
      '5 items',
    );
  });
}
```

### Mocking Translations

For isolated unit tests, mock the translation layer:

```dart
import 'package:mocktail/mocktail.dart';

class MockShardI18n extends Mock implements ShardI18n {}

void main() {
  late MockShardI18n mockI18n;

  setUp(() {
    mockI18n = MockShardI18n();
    when(() => mockI18n.translate(any())).thenReturn('Mocked');
  });

  test('uses translation service', () {
    // Test code that depends on translations
  });
}
```

## Widget Testing

### Basic Widget Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shard_i18n/shard_i18n.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ShardI18n.instance.init(
      supportedLocales: [const Locale('en')],
      defaultLocale: const Locale('en'),
      basePath: 'assets/i18n',
    );
  });

  testWidgets('displays translated welcome message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Text(context.t('Welcome!')),
        ),
      ),
    );

    expect(find.text('Welcome!'), findsOneWidget);
  });
}
```

### Testing with AnimatedBuilder

```dart
testWidgets('rebuilds on locale change', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AnimatedBuilder(
        animation: ShardI18n.instance,
        builder: (context, _) {
          return Text(context.t('Hello'));
        },
      ),
    ),
  );

  expect(find.text('Hello'), findsOneWidget);

  // Change locale
  await ShardI18n.instance.setLocale(const Locale('de'));
  await tester.pump();

  expect(find.text('Hallo'), findsOneWidget);
});
```

### Testing Locale Switching

```dart
testWidgets('language selector changes locale', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AnimatedBuilder(
        animation: ShardI18n.instance,
        builder: (context, _) {
          return Column(
            children: [
              Text(context.t('Settings')),
              ElevatedButton(
                onPressed: () => ShardI18n.instance.setLocale(const Locale('de')),
                child: const Text('German'),
              ),
            ],
          );
        },
      ),
    ),
  );

  expect(find.text('Settings'), findsOneWidget);

  await tester.tap(find.text('German'));
  await tester.pumpAndSettle();

  expect(find.text('Einstellungen'), findsOneWidget);
});
```

## Integration Testing

### Full App Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full localization flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Verify default locale
    expect(find.text('Welcome'), findsOneWidget);

    // Open settings
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Change to German
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    // Verify locale changed
    expect(find.text('Willkommen'), findsOneWidget);

    // Navigate and verify consistency
    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();
    expect(find.text('Startseite'), findsOneWidget);
  });
}
```

### Testing Multiple Locales

```dart
void main() {
  final testLocales = [
    (Locale('en'), 'Welcome', 'Settings'),
    (Locale('de'), 'Willkommen', 'Einstellungen'),
    (Locale('fr'), 'Bienvenue', 'Paramètres'),
  ];

  for (final (locale, welcome, settings) in testLocales) {
    testWidgets('displays correctly in ${locale.languageCode}', (tester) async {
      await ShardI18n.instance.setLocale(locale);

      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      expect(find.text(welcome), findsOneWidget);
      expect(find.text(settings), findsOneWidget);
    });
  }
}
```

## Golden Tests

### Visual Regression Testing

```dart
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('login screen matches golden', (tester) async {
    await loadAppFonts();
    await ShardI18n.instance.init(...);

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen()),
    );

    await screenMatchesGolden(tester, 'login_screen_en');
  });

  testGoldens('login screen in German matches golden', (tester) async {
    await loadAppFonts();
    await ShardI18n.instance.init(...);
    await ShardI18n.instance.setLocale(const Locale('de'));

    await tester.pumpWidget(
      MaterialApp(home: LoginScreen()),
    );

    await screenMatchesGolden(tester, 'login_screen_de');
  });
}
```

## Test Fixtures

### Create Test Translations

```dart
// test/fixtures/i18n/en/core.json
{
  "Welcome!": "Welcome!",
  "Hello, {name}!": "Hello, {name}!",
  "item_count": {
    "zero": "No items",
    "one": "1 item",
    "other": "{count} items"
  }
}
```

### Test Helper

```dart
// test/helpers/i18n_test_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shard_i18n/shard_i18n.dart';

Future<void> initTestI18n() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await ShardI18n.instance.init(
    supportedLocales: [
      const Locale('en'),
      const Locale('de'),
    ],
    defaultLocale: const Locale('en'),
    basePath: 'test/fixtures/i18n',
  );
}

Widget wrapWithI18n(Widget child) {
  return MaterialApp(
    home: AnimatedBuilder(
      animation: ShardI18n.instance,
      builder: (_, __) => child,
    ),
  );
}
```

### Using the Helper

```dart
import 'helpers/i18n_test_helper.dart';

void main() {
  setUpAll(() => initTestI18n());

  testWidgets('my widget test', (tester) async {
    await tester.pumpWidget(wrapWithI18n(MyWidget()));
    // ...
  });
}
```

## CLI Testing

### Testing Extract Command

```bash
# Create test project structure
mkdir -p test_project/lib
mkdir -p test_project/assets/i18n/en

# Create test dart file
cat > test_project/lib/main.dart << 'EOF'
import 'package:shard_i18n/shard_i18n.dart';

void test(BuildContext context) {
  context.t('Hello');
  context.t('World');
}
EOF

# Create test JSON
cat > test_project/assets/i18n/en/core.json << 'EOF'
{
  "Hello": "Hello"
}
EOF

# Run extract and verify output
dart run shard_i18n_cli extract \
  --path=test_project/lib \
  --i18n=test_project/assets/i18n \
  --format=json

# Expected: "World" in missingInJson
```

### Testing Verify Command

```bash
# Test with missing translation
dart run shard_i18n_cli verify --path=test_project/assets/i18n
# Should show missing key warning
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2

      - name: Install dependencies
        run: flutter pub get

      - name: Verify i18n consistency
        run: dart run shard_i18n_cli extract --strict

      - name: Run unit tests
        run: flutter test

      - name: Run integration tests
        run: flutter test integration_test
```

### Pre-commit Hook

```bash
#!/bin/sh
# .git/hooks/pre-commit

# Check i18n consistency
dart run shard_i18n_cli extract --strict
if [ $? -ne 0 ]; then
  echo "i18n check failed. Please fix missing translations."
  exit 1
fi

# Run tests
flutter test
```

## Best Practices

### 1. Test All Locales

Don't just test the default locale:

```dart
for (final locale in supportedLocales) {
  testWidgets('works in ${locale.languageCode}', ...);
}
```

### 2. Test Edge Cases

- Empty strings
- Very long strings
- Special characters
- RTL languages
- Plurals with 0, 1, 2, large numbers

### 3. Test Fallback Behavior

```dart
test('falls back to msgid for missing translation', () {
  final result = ShardI18n.instance.translate('This key does not exist');
  expect(result, 'This key does not exist');
});
```

### 4. Isolate Tests

Reset state between tests:

```dart
setUp(() async {
  await ShardI18n.instance.setLocale(const Locale('en'));
});
```

### 5. Use Meaningful Assertions

```dart
// ✗ Bad - doesn't tell you what's wrong
expect(find.byType(Text), findsWidgets);

// ✓ Good - clear about expected content
expect(find.text('Welcome to our app!'), findsOneWidget);
```
