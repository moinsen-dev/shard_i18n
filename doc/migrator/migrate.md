# migrate Command

The `migrate` command executes the migration from your existing i18n solution to shard_i18n.

## Usage

```bash
dart run shard_i18n_migrator migrate [options]
```

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--path` | `.` | Project root directory |
| `--dry-run` | | Preview changes without writing |
| `--backup` | `true` | Create backup of modified files |
| `--update-imports` | `true` | Update import statements |
| `--remove-old` | `false` | Remove old i18n files after migration |
| `--shard-strategy` | `feature` | How to organize shards: `single`, `feature`, `custom` |

## Migration Steps

The migrate command performs these operations:

### 1. Convert Translation Files

**From ARB (gen_l10n):**
```json
// lib/l10n/app_en.arb
{
  "welcomeMessage": "Welcome to our app!",
  "@welcomeMessage": {
    "description": "Welcome message on home screen"
  },
  "itemCount": "{count, plural, one{1 item} other{{count} items}}",
  "@itemCount": {
    "placeholders": {
      "count": {"type": "int"}
    }
  }
}
```

**To shard_i18n JSON:**
```json
// assets/i18n/en/core.json
{
  "Welcome to our app!": "Welcome to our app!",
  "item_count": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

### 2. Update Source Code

**Before:**
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(l10n.welcomeMessage),
        Text(l10n.itemCount(itemCount)),
      ],
    );
  }
}
```

**After:**
```dart
import 'package:shard_i18n/shard_i18n.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(context.t('Welcome to our app!')),
        Text(context.tn('item_count', count: itemCount)),
      ],
    );
  }
}
```

### 3. Update pubspec.yaml

Adds shard_i18n dependency and removes old dependencies:

```yaml
dependencies:
  shard_i18n: ^0.3.0
  # flutter_localizations removed if --remove-old
```

### 4. Update App Bootstrap

**Before:**
```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ...
)
```

**After:**
```dart
MaterialApp(
  // shard_i18n uses AnimatedBuilder pattern
  builder: (context, child) {
    return AnimatedBuilder(
      animation: ShardI18n.instance,
      builder: (context, _) => child!,
    );
  },
  // ...
)
```

## Dry Run

Always preview changes first:

```bash
dart run shard_i18n_migrator migrate --dry-run
```

**Output:**
```
🔄 Migration Preview (dry run)

📁 Files to create:
   + assets/i18n/en/core.json (156 keys)
   + assets/i18n/de/core.json (156 keys)
   + assets/i18n/fr/core.json (156 keys)

📝 Files to modify:
   ~ lib/features/auth/login_page.dart (12 changes)
   ~ lib/features/home/home_page.dart (28 changes)
   ~ lib/main.dart (bootstrap changes)
   ~ pubspec.yaml (dependency changes)

🗑️  Files to remove (if --remove-old):
   - lib/l10n/app_en.arb
   - lib/l10n/app_de.arb
   - lib/l10n/l10n.yaml

Run without --dry-run to apply changes.
```

## Shard Strategies

### Single Shard

All translations in one file:

```bash
dart run shard_i18n_migrator migrate --shard-strategy=single
```

```
assets/i18n/en/core.json  # All 156 keys
```

### Feature-Based (Default)

Organize by source feature:

```bash
dart run shard_i18n_migrator migrate --shard-strategy=feature
```

```
assets/i18n/en/
├── core.json      # Common/shared
├── auth.json      # lib/features/auth/*
├── home.json      # lib/features/home/*
└── settings.json  # lib/features/settings/*
```

### Custom

Use your own mapping:

```bash
dart run shard_i18n_migrator migrate --shard-strategy=custom --shard-config=shards.yaml
```

**shards.yaml:**
```yaml
shards:
  auth:
    - login
    - register
    - password
  onboarding:
    - welcome
    - tutorial
  default: core
```

## Backup and Rollback

Backups are created by default:

```
.shard_i18n_backup/
├── 2024-01-15_143022/
│   ├── lib/
│   │   └── features/...
│   └── pubspec.yaml
```

**To rollback:**
```bash
# Restore from backup
cp -r .shard_i18n_backup/2024-01-15_143022/* .
```

## Post-Migration Steps

After migration:

1. **Verify translations:**
   ```bash
   dart run shard_i18n_cli verify
   ```

2. **Check for missing keys:**
   ```bash
   dart run shard_i18n_cli extract --strict
   ```

3. **Test the app:**
   ```bash
   flutter run
   ```

4. **Remove backup (optional):**
   ```bash
   rm -rf .shard_i18n_backup/
   ```

## Handling Edge Cases

### ICU Select Patterns

Select patterns are converted to separate keys:

**Before (ARB):**
```json
{
  "greeting": "{gender, select, male{Mr.} female{Ms.} other{Dear}} {name}"
}
```

**After (manual handling recommended):**
```dart
// Use conditional logic in code
final title = switch(gender) {
  'male' => context.t('Mr.'),
  'female' => context.t('Ms.'),
  _ => context.t('Dear'),
};
Text('$title ${context.t('{name}', params: {'name': name})}')
```

### Dynamic Keys

Dynamic keys need manual migration:

```dart
// Before - dynamic key lookup
Text(l10n.getMessage(keyName))

// After - use msgid directly or map
final messages = {
  'error': 'An error occurred',
  'success': 'Operation successful',
};
Text(context.t(messages[keyName]!))
```

### HTML/Rich Text

HTML in translations is preserved:

```json
{
  "Terms and <b>Conditions</b>": "Terms and <b>Conditions</b>"
}
```

## Troubleshooting

### "Cannot parse ICU pattern"

Complex ICU patterns may need manual conversion. Check the migration log for details.

### "Import update failed"

If automatic import updates fail, manually update:
```dart
// Remove
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Add
import 'package:shard_i18n/shard_i18n.dart';
```

### "Key collision detected"

If the same msgid maps to different values:
```
Warning: Key collision for "Save"
  - settings.arb: "Save Settings"
  - profile.arb: "Save Profile"
```

Resolve by making keys unique:
```dart
context.t('Save Settings')
context.t('Save Profile')
```
