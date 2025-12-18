# verify Command

The `verify` command checks translation consistency across all locales.

## Usage

```bash
dart run shard_i18n_cli verify [options]
```

## Options

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--path` | `-p` | `assets/i18n` | Path to i18n assets directory |

## What It Checks

1. **Missing keys** - Keys in reference locale not present in other locales
2. **Extra keys** - Keys in other locales not present in reference locale
3. **Placeholder parity** - Same `{placeholders}` in all translations

## Example Output

```
$ dart run shard_i18n_cli verify

🔍 Verifying translations in: assets/i18n

📁 Found locales: en, de, fr, es

📊 Reference locale: en (150 keys)

  de:
    ✅ All keys present (150 keys)

  fr:
    ⚠️  Missing 5 key(s):
       - New Feature Title
       - Welcome back, {name}!
       - items_count
       ... and 2 more
    ⚠️  Placeholder mismatches:
       - Hello, {name}!: placeholders mismatch

  es:
    ⚠️  Missing 3 key(s):
       - New Feature Title
       - Beta label
       - experimental.warning
    ⚠️  Extra 1 key(s):
       - old_unused_key

❌ Verification failed with errors
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All translations verified successfully |
| 1 | Verification failed with errors |

## Reference Locale

The first locale directory found (alphabetically) is used as the reference. Typically this is `en`.

To ensure English is the reference:
- Name the directory `en` (not `english`)
- Or structure directories so `en` comes first alphabetically

## Placeholder Validation

The verify command checks that all `{placeholder}` names match across translations:

**English:**
```json
{
  "greeting": "Hello, {firstName} {lastName}!"
}
```

**German (correct):**
```json
{
  "greeting": "Hallo, {firstName} {lastName}!"
}
```

**German (error - missing placeholder):**
```json
{
  "greeting": "Hallo, {firstName}!"
}
```

## Best Practices

### Run Before Commits

```bash
# Pre-commit hook
dart run shard_i18n_cli verify || exit 1
```

### Run in CI

```yaml
- name: Verify translations
  run: dart run shard_i18n_cli verify
```

### Combine with Extract

```bash
# Full check
dart run shard_i18n_cli extract --strict
dart run shard_i18n_cli verify
```

## Common Issues

### Missing Keys

**Cause:** Keys added to English but not translated yet.

**Fix:**
```bash
dart run shard_i18n_cli fill --from=en --to=de,fr --provider=openai --key=$KEY
```

### Extra Keys

**Cause:** Keys removed from English but still in other locales.

**Fix:** Manually remove from affected locale files, or use `extract --prune` for English.

### Placeholder Mismatch

**Cause:** Translator accidentally removed or renamed a placeholder.

**Fix:** Manually correct the translation to include all placeholders.

## Related Commands

- [extract](extract.md) - Find missing/orphaned keys by scanning code
- [fill](fill.md) - Auto-translate missing keys
