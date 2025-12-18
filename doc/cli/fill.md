# fill Command

The `fill` command auto-translates missing keys using AI providers (OpenAI or DeepL).

## Usage

```bash
dart run shard_i18n_cli fill [options]
```

## Options

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--from` | | `en` | Source locale |
| `--to` | | *required* | Target locales (comma-separated) |
| `--provider` | | `openai` | Translation provider (`openai`, `deepl`) |
| `--key` | | *required* | API key for the provider |
| `--path` | `-p` | `assets/i18n` | Path to i18n assets directory |
| `--dry-run` | | | Preview without writing files |

## Providers

### OpenAI

Uses GPT-4o-mini for translation:

```bash
dart run shard_i18n_cli fill \
  --from=en \
  --to=de \
  --provider=openai \
  --key=$OPENAI_API_KEY
```

**Requirements:**
- OpenAI API key with GPT-4 access
- Environment variable: `OPENAI_API_KEY`

**Pricing:** ~$0.0001 per translation (varies by length)

### DeepL

Uses DeepL API for professional-quality translations:

```bash
dart run shard_i18n_cli fill \
  --from=en \
  --to=de \
  --provider=deepl \
  --key=$DEEPL_API_KEY
```

**Requirements:**
- DeepL API key (free or pro)
- Environment variable: `DEEPL_API_KEY`

**Pricing:** Free tier: 500k chars/month. Pro: varies.

## Examples

### Single Locale

```bash
dart run shard_i18n_cli fill \
  --from=en \
  --to=de \
  --provider=openai \
  --key=$OPENAI_API_KEY
```

### Multiple Locales

```bash
dart run shard_i18n_cli fill \
  --from=en \
  --to=de,fr,es,it \
  --provider=openai \
  --key=$OPENAI_API_KEY
```

### Preview Mode

See what would be translated without writing files:

```bash
dart run shard_i18n_cli fill \
  --from=en \
  --to=de \
  --provider=openai \
  --key=$OPENAI_API_KEY \
  --dry-run
```

## Example Output

```
$ dart run shard_i18n_cli fill --from=en --to=de --provider=openai --key=$KEY

🤖 Filling translations using openai
   Source: en
   Targets: de

📝 Processing de...
   Found 12 missing key(s)
   🔄 Translating 12 key(s)...
   ✅ Added 12 translation(s)

✅ Fill operation completed!
```

## Placeholder Preservation

The AI providers are instructed to preserve `{placeholders}`:

**English:**
```json
{
  "Hello, {name}!": "Hello, {name}!"
}
```

**Generated German:**
```json
{
  "Hello, {name}!": "Hallo, {name}!"
}
```

## Plural Forms

Plural forms are translated individually:

**English:**
```json
{
  "items_count": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

**Generated German:**
```json
{
  "items_count": {
    "one": "{count} Artikel",
    "other": "{count} Artikel"
  }
}
```

## Rate Limiting

The fill command includes automatic rate limiting:
- 100ms delay between translations
- Prevents API throttling
- Progress shown during translation

## Output Location

Translations are written to `core.json` in the target locale directory:

```
assets/i18n/
  en/
    core.json
  de/
    core.json  ← translations added here
```

## Best Practices

### Always Preview First

```bash
# Preview
dart run shard_i18n_cli fill --from=en --to=de --provider=openai --key=$KEY --dry-run

# Then apply
dart run shard_i18n_cli fill --from=en --to=de --provider=openai --key=$KEY
```

### Review AI Translations

AI translations are good but not perfect. Review for:
- Context-appropriate terminology
- Brand-specific terms
- Technical accuracy

### Use DeepL for European Languages

DeepL often produces better quality for European languages.

### Secure Your API Key

```bash
# Use environment variable
export OPENAI_API_KEY=sk-...
dart run shard_i18n_cli fill --from=en --to=de --provider=openai --key=$OPENAI_API_KEY

# Never commit keys to git
```

## Error Handling

If a translation fails:
- The original text is preserved
- Warning is shown in console
- Other translations continue

```
   ⚠️  Translation error for "complex text": API timeout
```

## Cost Estimation

**OpenAI GPT-4o-mini:**
- ~1000 translations ≈ $0.10
- Depends on text length

**DeepL:**
- Free: 500k characters/month
- Pro: ~$0.02 per 1000 characters

## Related Commands

- [extract](extract.md) - Find missing keys to translate
- [verify](verify.md) - Verify all translations are complete
