# Custom Plural Rules

shard_i18n includes CLDR-based plural rules for 25+ languages. This guide covers customizing and extending plural support.

## Built-in Plural Rules

### Supported Languages

| Language | Code | Forms |
|----------|------|-------|
| English | en | one, other |
| German | de | one, other |
| French | fr | one, other |
| Spanish | es | one, other |
| Italian | it | one, other |
| Portuguese | pt | one, other |
| Dutch | nl | one, other |
| Russian | ru | one, few, many, other |
| Polish | pl | one, few, many, other |
| Ukrainian | uk | one, few, many, other |
| Czech | cs | one, few, other |
| Arabic | ar | zero, one, two, few, many, other |
| Chinese | zh | other |
| Japanese | ja | other |
| Korean | ko | other |
| Vietnamese | vi | other |
| Turkish | tr | one, other |
| Hebrew | he | one, two, many, other |
| Romanian | ro | one, few, other |
| Croatian | hr | one, few, other |
| Serbian | sr | one, few, other |
| Slovenian | sl | one, two, few, other |
| Lithuanian | lt | one, few, other |
| Latvian | lv | zero, one, other |
| Irish | ga | one, two, few, many, other |

### Plural Form Examples

**English (simple):**
```json
{
  "item_count": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

**Russian (complex):**
```json
{
  "item_count": {
    "one": "{count} элемент",
    "few": "{count} элемента",
    "many": "{count} элементов",
    "other": "{count} элемента"
  }
}
```

**Arabic (six forms):**
```json
{
  "item_count": {
    "zero": "لا عناصر",
    "one": "عنصر واحد",
    "two": "عنصران",
    "few": "{count} عناصر",
    "many": "{count} عنصرًا",
    "other": "{count} عنصر"
  }
}
```

## How Plural Rules Work

### CLDR Categories

The Unicode CLDR defines these plural categories:

| Category | Description | Example (English) |
|----------|-------------|-------------------|
| `zero` | Zero quantity | 0 items |
| `one` | Singular | 1 item |
| `two` | Dual | 2 items |
| `few` | Paucal | 2-4 items (Slavic) |
| `many` | Many | 5+ items (Slavic) |
| `other` | General plural | Default fallback |

### Rule Selection

The plural form is selected based on the count value:

```dart
// English: n == 1 ? 'one' : 'other'
context.tn('item_count', count: 1)  // "1 item"
context.tn('item_count', count: 5)  // "5 items"

// Russian: Complex rules based on last digits
context.tn('item_count', count: 1)   // "1 элемент" (one)
context.tn('item_count', count: 2)   // "2 элемента" (few)
context.tn('item_count', count: 5)   // "5 элементов" (many)
context.tn('item_count', count: 21)  // "21 элемент" (one)
```

## Custom Plural Rules

### Override Existing Language

To customize plural rules for a language:

```dart
// lib/i18n/custom_plurals.dart
import 'package:shard_i18n/shard_i18n.dart';

class CustomEnglishPluralRules extends PluralRules {
  @override
  String selectPlural(int count) {
    if (count == 0) return 'zero';
    if (count == 1) return 'one';
    return 'other';
  }
}

// Register during initialization
void main() async {
  await ShardI18n.instance.init(
    supportedLocales: [const Locale('en')],
    defaultLocale: const Locale('en'),
    basePath: 'assets/i18n',
    pluralRules: {
      'en': CustomEnglishPluralRules(),
    },
  );
}
```

Then update your translations:

```json
{
  "item_count": {
    "zero": "No items",
    "one": "1 item",
    "other": "{count} items"
  }
}
```

### Add New Language

For languages not included by default:

```dart
class WelshPluralRules extends PluralRules {
  @override
  String selectPlural(int count) {
    // Welsh has 6 plural forms
    if (count == 0) return 'zero';
    if (count == 1) return 'one';
    if (count == 2) return 'two';
    if (count == 3) return 'few';
    if (count == 6) return 'many';
    return 'other';
  }
}

// Register
await ShardI18n.instance.init(
  pluralRules: {
    'cy': WelshPluralRules(),
  },
);
```

## Plural Form Reference

### Germanic Languages (en, de, nl, etc.)

```dart
String selectPlural(int n) {
  return n == 1 ? 'one' : 'other';
}
```

### Romance Languages (fr, es, it, pt)

```dart
String selectPlural(int n) {
  return (n == 0 || n == 1) ? 'one' : 'other';
}
```

### Slavic Languages (ru, pl, uk)

```dart
String selectPlural(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;

  if (mod10 == 1 && mod100 != 11) {
    return 'one';
  }
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'few';
  }
  if (mod10 == 0 || (mod10 >= 5 && mod10 <= 9) || (mod100 >= 11 && mod100 <= 14)) {
    return 'many';
  }
  return 'other';
}
```

### East Asian Languages (zh, ja, ko, vi)

```dart
String selectPlural(int n) {
  return 'other';  // No grammatical plural
}
```

### Arabic

```dart
String selectPlural(int n) {
  if (n == 0) return 'zero';
  if (n == 1) return 'one';
  if (n == 2) return 'two';

  final mod100 = n % 100;
  if (mod100 >= 3 && mod100 <= 10) return 'few';
  if (mod100 >= 11 && mod100 <= 99) return 'many';

  return 'other';
}
```

## Testing Plural Rules

### Unit Test

```dart
void main() {
  group('Russian plural rules', () {
    final rules = RussianPluralRules();

    test('selects correct form', () {
      expect(rules.selectPlural(1), 'one');
      expect(rules.selectPlural(2), 'few');
      expect(rules.selectPlural(5), 'many');
      expect(rules.selectPlural(21), 'one');
      expect(rules.selectPlural(22), 'few');
      expect(rules.selectPlural(25), 'many');
    });
  });
}
```

### Edge Cases

Test these edge cases for your custom rules:

| Count | Expected (Russian) |
|-------|-------------------|
| 0 | many |
| 1 | one |
| 2-4 | few |
| 5-20 | many |
| 21 | one |
| 22-24 | few |
| 25-30 | many |
| 100 | many |
| 101 | one |
| 111 | many |
| 121 | one |

## Best Practices

### 1. Always Include 'other'

Every plural key should have an 'other' form as fallback:

```json
{
  "item_count": {
    "one": "{count} item",
    "other": "{count} items"  // Required fallback
  }
}
```

### 2. Use {count} Placeholder

Include the count in plural strings:

```json
{
  "item_count": {
    "one": "{count} item",    // Not "1 item"
    "other": "{count} items"
  }
}
```

### 3. Validate with extract

Use the extract command to check plural forms:

```bash
dart run shard_i18n_cli extract --verbose
```

```
⚠️  Plural Issues (1):
   • "item_count"
     Missing required form: "other"
```

### 4. Reference CLDR

For accurate rules, consult the Unicode CLDR:
- [CLDR Plural Rules](https://cldr.unicode.org/index/cldr-spec/plural-rules)
- [Plural Rule Charts](https://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html)

## Debugging Plurals

### Check Which Form is Selected

```dart
// Debug helper
void debugPlural(String key, int count) {
  final rules = ShardI18n.instance.getPluralRules();
  final form = rules.selectPlural(count);
  print('count: $count -> form: $form');

  final result = ShardI18n.instance.translatePlural(key, count);
  print('result: $result');
}

// Usage
debugPlural('item_count', 21);
// Output:
// count: 21 -> form: one
// result: 21 элемент
```

### Common Issues

**Wrong form selected:**
- Check locale is correctly set
- Verify custom rules are registered
- Test with edge case numbers

**Missing translation:**
- Ensure JSON has all required forms
- Check for typos in form names
- Verify file is loaded for locale
