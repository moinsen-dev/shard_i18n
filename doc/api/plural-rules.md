# Plural Rules Reference

shard_i18n includes built-in CLDR plural rules for 25+ languages.

## Supported Languages

| Language | Code | Categories |
|----------|------|------------|
| English | en | one, other |
| German | de | one, other |
| Dutch | nl | one, other |
| Swedish | sv | one, other |
| Norwegian | no | one, other |
| Danish | da | one, other |
| Finnish | fi | one, other |
| Italian | it | one, other |
| Spanish | es | one, other |
| Portuguese | pt | one, other |
| French | fr | one, other |
| Turkish | tr | other |
| Russian | ru | one, few, many, other |
| Ukrainian | uk | one, few, many, other |
| Polish | pl | one, few, many, other |
| Czech | cs | one, few, other |
| Slovak | sk | one, few, other |
| Serbian | sr | one, few, other |
| Croatian | hr | one, few, other |
| Bosnian | bs | one, few, other |
| Romanian | ro | one, few, other |
| Bulgarian | bg | one, other |
| Greek | el | one, other |
| Hungarian | hu | one, other |
| Lithuanian | lt | one, few, other |
| Latvian | lv | zero, one, other |

## Rule Definitions

### Germanic Languages (en, de, nl, sv, no, da)

```
one:   n = 1
other: everything else
```

| n | Category |
|---|----------|
| 1 | one |
| 0, 2, 3... | other |

### Romance Languages (fr, es, pt, it)

```
one:   n = 0..1
other: everything else
```

| n | Category |
|---|----------|
| 0, 1 | one |
| 2, 3, 4... | other |

Note: French uses `one` for both 0 and 1.

### Slavic - Russian/Ukrainian

```
one:   n % 10 = 1 AND n % 100 != 11
few:   n % 10 = 2..4 AND n % 100 != 12..14
many:  n % 10 = 0 OR n % 10 = 5..9 OR n % 100 = 11..14
other: decimal numbers
```

| n | Category |
|---|----------|
| 1, 21, 31, 41... | one |
| 2-4, 22-24, 32-34... | few |
| 0, 5-20, 25-30... | many |
| 1.5, 2.5... | other |

### Slavic - Polish

```
one:   n = 1
few:   n % 10 = 2..4 AND n % 100 != 12..14
many:  n != 1 AND n % 10 = 0..1 OR n % 10 = 5..9 OR n % 100 = 12..14
other: decimal numbers
```

### Slavic - Czech/Slovak

```
one:   n = 1
few:   n = 2..4
other: everything else
```

### Turkish

```
other: all numbers
```

Turkish has no grammatical plural distinction.

### Latvian

```
zero:  n = 0
one:   n % 10 = 1 AND n % 100 != 11
other: everything else
```

## JSON Examples

### English

```json
{
  "items": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

### Russian

```json
{
  "items": {
    "one": "{count} предмет",
    "few": "{count} предмета",
    "many": "{count} предметов",
    "other": "{count} предмета"
  }
}
```

### Polish

```json
{
  "files": {
    "one": "{count} plik",
    "few": "{count} pliki",
    "many": "{count} plików",
    "other": "{count} pliku"
  }
}
```

### Turkish

```json
{
  "items": {
    "other": "{count} öğe"
  }
}
```

## Custom Rules

Register custom plural rules for unsupported languages:

```dart
// Simple one/other
ShardI18n.instance.registerPluralRule('my_lang', (num n) {
  return n == 1 ? 'one' : 'other';
});

// Complex rule
ShardI18n.instance.registerPluralRule('my_lang', (num n) {
  if (n == 0) return 'zero';
  if (n == 1) return 'one';
  if (n == 2) return 'two';
  if (n >= 3 && n <= 10) return 'few';
  if (n >= 11 && n <= 99) return 'many';
  return 'other';
});
```

## Testing Plural Rules

Verify plural forms work correctly:

```dart
void testPlurals() {
  final testCases = [0, 1, 2, 3, 4, 5, 11, 21, 22, 25, 100, 101, 111];

  for (final n in testCases) {
    final result = context.tn('items_count', count: n);
    print('$n: $result');
  }
}
```

## CLDR Reference

For complete CLDR plural rules:

- [CLDR Plural Rules](https://cldr.unicode.org/index/cldr-spec/plural-rules)
- [Unicode CLDR Charts](https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_plural_rules.html)

## Best Practices

1. **Always include `other`** - It's the required fallback
2. **Test with edge cases** - 0, 1, 2, 5, 11, 21, 100
3. **Check CLDR for your languages** - Rules vary significantly
4. **Use `{count}` consistently** - It's auto-included in params
