# Fallback Strategy

shard_i18n implements a multi-level fallback strategy to ensure translations always return a usable value.

## Fallback Chain

When you request a translation, shard_i18n tries multiple sources in order:

```
1. Exact locale (de-DE)
   ↓ if missing
2. Language only (de)
   ↓ if missing
3. English (en)
   ↓ if missing
4. Msgid/key itself
```

## Example

Request translation for `de-DE` locale:

```dart
context.t('Welcome')  // Current locale: de-DE
```

**Lookup order:**
1. Check `assets/i18n/de-DE/core.json` → Not found
2. Check `assets/i18n/de/core.json` → Found: "Willkommen"
3. Return "Willkommen"

If not found in German:
1. Check `assets/i18n/de-DE/core.json` → Not found
2. Check `assets/i18n/de/core.json` → Not found
3. Check `assets/i18n/en/core.json` → Found: "Welcome"
4. Return "Welcome"

If not found anywhere:
1. All lookups fail
2. Return the msgid: "Welcome"

## Regional Variants

Support regional variants with automatic fallback:

```
assets/i18n/
  en/          # Base English
    core.json
  en-GB/       # British English overrides
    core.json
  en-US/       # American English overrides
    core.json
```

**en/core.json (base):**
```json
{
  "Color": "Colour",
  "Favorite": "Favourite"
}
```

**en-US/core.json (override):**
```json
{
  "Color": "Color",
  "Favorite": "Favorite"
}
```

Request with `en-US` locale:
- "Color" → "Color" (from en-US)
- "Submit" → "Submit" (falls back to en)

## Partial Translations

You don't need complete translations for every locale:

```
assets/i18n/
  en/
    core.json        # 100 keys (complete)
    auth.json        # 50 keys (complete)
  de/
    core.json        # 80 keys (partial)
    auth.json        # 50 keys (complete)
```

Missing keys in German will show English text.

## Debug Logging

Enable logging to see fallback behavior:

```dart
ShardI18n.instance.debugLogMissingKeys = true;
```

Console output:
```
[shard_i18n] Missing translation: "New Feature" for locale de
[shard_i18n] Missing translation: "Beta Badge" for locale de
```

Each missing key is logged once per session to avoid spam.

## Leveraging Fallback

### Progressive Translation

Start with English and add translations gradually:

```dart
// Phase 1: English only
await ShardI18n.instance.bootstrap(const Locale('en'));

// Phase 2: Add partial German
// Missing keys show English automatically

// Phase 3: Complete German
// All keys translated
```

### Regional Customization

Override only what differs:

```json
// en/core.json (base - 100 keys)
{
  "Date format": "MM/DD/YYYY",
  "Currency": "USD",
  ...100 keys...
}

// en-GB/core.json (override - 2 keys)
{
  "Date format": "DD/MM/YYYY",
  "Currency": "GBP"
}
```

en-GB users get British date/currency, everything else falls back to base English.

## Fallback Configuration

The fallback chain is automatic, but you can influence it:

### Force Specific Locale

```dart
// Always use exact match, no fallback
await ShardI18n.instance.setLocale(const Locale('de'));
```

### Check Available Locales

```dart
final available = ShardI18n.instance.supportedLocales;
print(available);  // [en, de, fr, ...]
```

## Best Practices

1. **Always provide English** - It's the ultimate fallback
2. **Use msgid for fallback** - English text as key shows readable fallback
3. **Test missing keys** - Verify fallback behavior in development
4. **Log in development** - Enable `debugLogMissingKeys` during dev
5. **Disable logs in production** - Avoid log noise

## Graceful Degradation

The fallback strategy ensures your app never shows:
- Empty strings
- Key names (unless that's your key style)
- Crashes or errors

Instead, users see the best available translation.
