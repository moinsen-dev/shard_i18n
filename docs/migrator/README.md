# Migrator Tool

The shard_i18n Migrator helps you migrate from other Flutter i18n solutions to shard_i18n.

## Supported Source Formats

| Source | Package | Status |
|--------|---------|--------|
| `gen_l10n` | flutter_localizations | ✅ Full support |
| `easy_localization` | easy_localization | ✅ Full support |
| `intl` | intl | ✅ Full support |

## Quick Start

```bash
# Analyze current setup
dart run shard_i18n_migrator analyze

# Generate migration plan
dart run shard_i18n_migrator analyze --output=migration-plan.json

# Execute migration
dart run shard_i18n_migrator migrate
```

## How It Works

The migrator performs these steps:

1. **Analysis** - Scans your project for existing i18n patterns
2. **Extraction** - Extracts all translation keys and values
3. **Conversion** - Converts ARB/JSON to shard_i18n format
4. **Code Update** - Replaces API calls in source files
5. **Cleanup** - Removes old configuration (optional)

## Migration Process

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Analyze    │────▶│  Generate   │────▶│  Review     │
│  Project    │     │  Plan       │     │  Changes    │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Verify     │◀────│  Update     │◀────│  Execute    │
│  Result     │     │  Imports    │     │  Migration  │
└─────────────┘     └─────────────┘     └─────────────┘
```

## Example

**Before (gen_l10n):**
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.welcomeMessage)
Text(AppLocalizations.of(context)!.itemCount(5))
```

**After (shard_i18n):**
```dart
import 'package:shard_i18n/shard_i18n.dart';

Text(context.t('Welcome to our app!'))
Text(context.tn('item_count', count: 5))
```

## Commands

- [analyze](analyze.md) - Analyze current i18n setup
- [migrate](migrate.md) - Execute the migration
- [Configuration](configuration.md) - Configure migration behavior

## Safety Features

- **Dry Run Mode** - Preview all changes before applying
- **Backup Creation** - Automatic backup of modified files
- **Incremental Migration** - Migrate file-by-file if needed
- **Rollback Support** - Restore from backup if issues arise

## When to Use

Consider migrating to shard_i18n if you want:

- **No code generation** - Instant hot reload
- **Msgid-based keys** - Natural English text as keys
- **Sharded files** - Better team collaboration
- **Simpler API** - `context.t()` vs `AppLocalizations.of(context)!.key`
