# Pluralization

shard_i18n supports CLDR-based pluralization for 25+ languages with proper handling of complex plural rules.

## Basic Plurals

Define plural forms in JSON:

```json
{
  "items_count": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

Use `context.tn()` for plurals:

```dart
Text(context.tn('items_count', count: 1))   // "1 item"
Text(context.tn('items_count', count: 5))   // "5 items"
Text(context.tn('items_count', count: 0))   // "0 items"
```

## Plural Categories

CLDR defines six plural categories:

| Category | Description | Example Languages |
|----------|-------------|-------------------|
| `zero` | Zero items | Arabic, Latvian |
| `one` | Singular | English, German |
| `two` | Dual | Arabic, Welsh |
| `few` | Small plural | Russian, Polish |
| `many` | Large plural | Russian, Polish |
| `other` | Default/all others | All languages |

**Note:** Not all languages use all categories.

## Language Examples

### English (one/other)

```json
{
  "messages_count": {
    "one": "{count} message",
    "other": "{count} messages"
  }
}
```

| Count | Result |
|-------|--------|
| 0 | "0 messages" |
| 1 | "1 message" |
| 2+ | "2 messages" |

### German (one/other)

Same as English:

```json
{
  "messages_count": {
    "one": "{count} Nachricht",
    "other": "{count} Nachrichten"
  }
}
```

### Russian (one/few/many/other)

Russian has complex plural rules:

```json
{
  "messages_count": {
    "one": "{count} сообщение",
    "few": "{count} сообщения",
    "many": "{count} сообщений",
    "other": "{count} сообщения"
  }
}
```

| Count | Category | Result |
|-------|----------|--------|
| 1, 21, 31 | one | "1 сообщение" |
| 2-4, 22-24 | few | "2 сообщения" |
| 5-20, 25-30 | many | "5 сообщений" |
| 1.5 | other | "1.5 сообщения" |

### Polish (one/few/many/other)

Similar to Russian with different rules:

```json
{
  "files_count": {
    "one": "{count} plik",
    "few": "{count} pliki",
    "many": "{count} plików",
    "other": "{count} pliku"
  }
}
```

### Arabic (zero/one/two/few/many/other)

Arabic uses all six categories:

```json
{
  "books_count": {
    "zero": "لا كتب",
    "one": "كتاب واحد",
    "two": "كتابان",
    "few": "{count} كتب",
    "many": "{count} كتاباً",
    "other": "{count} كتاب"
  }
}
```

### Turkish (one/other)

Turkish has simple plurals (no grammatical plural):

```json
{
  "items_count": {
    "one": "{count} öğe",
    "other": "{count} öğe"
  }
}
```

## Additional Parameters

Combine plurals with other parameters:

```json
{
  "user_posts": {
    "one": "{name} has {count} post",
    "other": "{name} has {count} posts"
  }
}
```

```dart
context.tn(
  'user_posts',
  count: 5,
  params: {'name': 'Alice'},
)
// "Alice has 5 posts"
```

## Supported Languages

shard_i18n includes built-in plural rules for:

- **Germanic:** English, German, Dutch, Swedish, Norwegian, Danish
- **Romance:** French, Spanish, Portuguese, Italian, Romanian
- **Slavic:** Russian, Ukrainian, Polish, Czech, Slovak, Serbian, Croatian, Bosnian
- **Other:** Turkish, Finnish, Hungarian, Bulgarian, Greek, Lithuanian, Latvian

## Custom Plural Rules

Register custom rules for unsupported languages:

```dart
ShardI18n.instance.registerPluralRule('my_lang', (num n) {
  if (n == 0) return 'zero';
  if (n == 1) return 'one';
  if (n >= 2 && n <= 4) return 'few';
  return 'other';
});
```

## Best Practices

1. **Always include `other`** - It's the required fallback
2. **Test with edge cases** - 0, 1, 2, 5, 11, 21, 100
3. **Provide all needed forms** - Check CLDR for your languages
4. **Use `{count}` placeholder** - Consistency helps translators

## Debugging Plurals

Check which category is selected:

```dart
// Enable debug logging
ShardI18n.instance.debugLogMissingKeys = true;

// Try different counts
for (final count in [0, 1, 2, 5, 11, 21]) {
  print('$count: ${context.tn("items_count", count: count)}');
}
```

## CLDR Reference

For complete plural rules, see:
- [CLDR Plural Rules](https://cldr.unicode.org/index/cldr-spec/plural-rules)
- [Language Plural Rules](https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_plural_rules.html)
