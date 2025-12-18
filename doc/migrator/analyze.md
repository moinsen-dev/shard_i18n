# analyze Command

The `analyze` command scans your project to detect existing i18n implementations and generates a migration plan.

## Usage

```bash
dart run shard_i18n_migrator analyze [options]
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--path` | `.` | Project root directory |
| `--output` | | Output file for migration plan (JSON) |
| `--verbose` | | Show detailed analysis |

## What It Detects

### gen_l10n (flutter_localizations)

- `l10n.yaml` configuration
- ARB files in `lib/l10n/`
- `AppLocalizations.of(context)` calls
- Plural/select ICU patterns

### easy_localization

- `EasyLocalization` widget wrapper
- JSON/YAML translation files
- `tr()` and `plural()` calls
- Asset configuration

### intl Package

- `Intl.message()` calls
- `Intl.plural()` calls
- Generated message catalogs

## Example Output

```bash
$ dart run shard_i18n_migrator analyze

🔍 Analyzing project at ./

📦 Detected: gen_l10n (flutter_localizations)
   Configuration: lib/l10n/l10n.yaml
   ARB files: 3
   Locales: en, de, fr

📊 Translation Statistics:
   Total keys: 156
   With placeholders: 23
   Plural forms: 8
   Select forms: 2

📁 Source Files Using i18n:
   lib/features/auth/login_page.dart (12 calls)
   lib/features/home/home_page.dart (28 calls)
   lib/features/settings/settings_page.dart (15 calls)
   ... and 18 more files

✅ Analysis complete!
   Run 'dart run shard_i18n_migrator migrate' to proceed.
```

## JSON Output

Generate a detailed migration plan:

```bash
dart run shard_i18n_migrator analyze --output=migration-plan.json
```

**Output file:**
```json
{
  "source": "gen_l10n",
  "locales": ["en", "de", "fr"],
  "statistics": {
    "totalKeys": 156,
    "withPlaceholders": 23,
    "pluralForms": 8,
    "selectForms": 2
  },
  "files": {
    "arb": [
      "lib/l10n/app_en.arb",
      "lib/l10n/app_de.arb",
      "lib/l10n/app_fr.arb"
    ],
    "dart": [
      {
        "path": "lib/features/auth/login_page.dart",
        "calls": 12,
        "patterns": ["simple", "placeholder"]
      }
    ]
  },
  "translations": {
    "en": {
      "welcomeMessage": "Welcome to our app!",
      "itemCount": "{count, plural, one{1 item} other{{count} items}}"
    }
  }
}
```

## Verbose Mode

Show detailed per-file analysis:

```bash
dart run shard_i18n_migrator analyze --verbose
```

```
📁 lib/features/auth/login_page.dart
   Line 42: AppLocalizations.of(context)!.email
   Line 56: AppLocalizations.of(context)!.password
   Line 78: AppLocalizations.of(context)!.signIn
   ...
```

## Pre-Migration Checklist

After analysis, review:

1. **All locales detected?** - Check the locale list
2. **Key count matches expectations?** - Compare with your ARB files
3. **Plural forms identified?** - These need special handling
4. **No custom ICU patterns?** - Complex patterns may need manual review

## Troubleshooting

### "No i18n implementation detected"

Ensure your project has one of the supported patterns:
- `l10n.yaml` for gen_l10n
- `EasyLocalization` widget for easy_localization
- `Intl.message()` calls for intl

### "ARB files not found"

Check the `arb-dir` setting in your `l10n.yaml`:
```yaml
arb-dir: lib/l10n  # Default location
```

### Incomplete Detection

Some dynamic patterns may not be detected:
```dart
// These may not be detected
final key = condition ? 'keyA' : 'keyB';
Text(AppLocalizations.of(context)!.getMessage(key))
```

## Next Steps

After analysis:

1. Review the migration plan
2. Run `migrate --dry-run` to preview changes
3. Execute `migrate` to perform the migration
4. Run `extract --strict` to verify
