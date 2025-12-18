# Migration Guide

This guide walks you through migrating from other Flutter i18n solutions to shard_i18n.

## Why Migrate?

| Feature | gen_l10n | easy_localization | shard_i18n |
|---------|----------|-------------------|------------|
| Code generation | Required | Optional | None |
| Hot reload | After rebuild | Partial | Instant |
| Key format | camelCase IDs | Various | Msgid (natural text) |
| File organization | Single ARB | Single file | Sharded by feature |
| Team collaboration | Merge conflicts | Merge conflicts | Minimal conflicts |
| Learning curve | Medium | Low | Very low |

## Before You Start

### 1. Audit Your Current Setup

Run the analyzer to understand your current state:

```bash
dart pub add shard_i18n --dev
dart run shard_i18n_migrator analyze
```

### 2. Plan Your Migration

Decide on:
- **Timing**: Feature freeze recommended during migration
- **Sharding**: How to organize translation files
- **Rollback**: Keep old files until verified

### 3. Create a Branch

```bash
git checkout -b migrate-to-shard-i18n
```

## Migration from gen_l10n

### Step 1: Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  shard_i18n: ^0.3.0
```

### Step 2: Run Migration

```bash
# Preview changes
dart run shard_i18n_migrator migrate --dry-run

# Execute migration
dart run shard_i18n_migrator migrate
```

### Step 3: Update Bootstrap

**Before:**
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const HomePage(),
)
```

**After:**
```dart
import 'package:shard_i18n/shard_i18n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ShardI18n.instance.init(
    supportedLocales: [
      const Locale('en'),
      const Locale('de'),
      const Locale('fr'),
    ],
    defaultLocale: const Locale('en'),
    basePath: 'assets/i18n',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ShardI18n.instance,
      builder: (context, _) {
        return MaterialApp(
          locale: ShardI18n.instance.currentLocale,
          home: const HomePage(),
        );
      },
    );
  }
}
```

### Step 4: Update Translations

**Before (ARB):**
```json
{
  "welcomeMessage": "Welcome, {name}!",
  "@welcomeMessage": {
    "placeholders": {
      "name": {"type": "String"}
    }
  }
}
```

**After (JSON):**
```json
{
  "Welcome, {name}!": "Welcome, {name}!"
}
```

### Step 5: Update Code

**Before:**
```dart
Text(AppLocalizations.of(context)!.welcomeMessage(userName))
```

**After:**
```dart
Text(context.t('Welcome, {name}!', params: {'name': userName}))
```

### Step 6: Verify

```bash
dart run shard_i18n_cli extract --strict
dart run shard_i18n_cli verify
```

## Migration from easy_localization

### Step 1: Add Dependencies

```yaml
dependencies:
  shard_i18n: ^0.3.0
  # Remove easy_localization after migration
```

### Step 2: Convert Translation Files

**Before (easy_localization JSON):**
```json
{
  "greeting": "Hello!",
  "welcome": {
    "title": "Welcome",
    "subtitle": "Get started"
  }
}
```

**After (shard_i18n JSON):**
```json
{
  "Hello!": "Hello!",
  "Welcome": "Welcome",
  "Get started": "Get started"
}
```

> Note: Nested keys become flat msgid keys.

### Step 3: Update Bootstrap

**Before:**
```dart
runApp(
  EasyLocalization(
    supportedLocales: [Locale('en'), Locale('de')],
    path: 'assets/translations',
    fallbackLocale: Locale('en'),
    child: MyApp(),
  ),
);
```

**After:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ShardI18n.instance.init(
    supportedLocales: [Locale('en'), Locale('de')],
    defaultLocale: Locale('en'),
    basePath: 'assets/i18n',
  );

  runApp(MyApp());
}
```

### Step 4: Update Code

**Before:**
```dart
Text('greeting'.tr())
Text('welcome.title'.tr())
Text('items'.plural(count))
```

**After:**
```dart
Text('Hello!'.tx)
Text('Welcome'.tx)
Text(context.tn('item_count', count: count))
```

## Key Mapping Strategies

### Strategy 1: Direct Msgid (Recommended)

Use the English text as the key:

```dart
// Before: l10n.welcomeMessage
// After: context.t('Welcome to our app!')
```

**Pros:**
- Self-documenting code
- No key lookup needed
- Works with extract command

### Strategy 2: Create Key Constants

For long or repeated text:

```dart
// lib/l10n/keys.dart
class L10nKeys {
  static const termsAndConditions = 'By continuing, you agree to our Terms of Service and Privacy Policy.';
}

// Usage
Text(context.t(L10nKeys.termsAndConditions))
```

### Strategy 3: Hybrid Approach

Short keys for common items, msgid for unique text:

```dart
// Common (use short key)
context.t('OK')
context.t('Cancel')
context.t('Save')

// Unique (use msgid)
context.t('Your profile has been updated successfully.')
```

## Handling Plurals

### gen_l10n ICU Format

**Before:**
```json
{
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}"
}
```

**After:**
```json
{
  "item_count": {
    "zero": "No items",
    "one": "1 item",
    "other": "{count} items"
  }
}
```

**Code:**
```dart
// Before
l10n.itemCount(count)

// After
context.tn('item_count', count: count)
```

### easy_localization Plural

**Before:**
```dart
'items'.plural(count)
```

**After:**
```dart
context.tn('item_count', count: count)
```

## Handling Select/Gender

ICU select patterns require manual conversion:

**Before (ARB):**
```json
{
  "greeting": "{gender, select, male{Mr.} female{Ms.} other{Dear}} {name}"
}
```

**After (code logic):**
```dart
final title = switch (gender) {
  Gender.male => context.t('Mr.'),
  Gender.female => context.t('Ms.'),
  _ => context.t('Dear'),
};
Text('$title ${context.t('{name}', params: {'name': name})}')
```

## Incremental Migration

For large apps, migrate incrementally:

### Phase 1: Setup

1. Add shard_i18n dependency
2. Initialize alongside existing solution
3. Create initial JSON files

### Phase 2: New Features

Use shard_i18n for new features:

```dart
// Old features: keep using AppLocalizations
Text(l10n.existingFeature)

// New features: use shard_i18n
Text(context.t('New feature text'))
```

### Phase 3: Gradual Migration

Migrate one feature at a time:

```bash
# Week 1: Auth feature
# Week 2: Settings feature
# Week 3: Home feature
# ...
```

### Phase 4: Cleanup

Remove old i18n system when complete.

## Verification Checklist

After migration, verify:

- [ ] All locales have complete translations
  ```bash
  dart run shard_i18n_cli verify
  ```

- [ ] No missing keys in code
  ```bash
  dart run shard_i18n_cli extract --strict
  ```

- [ ] App builds successfully
  ```bash
  flutter build apk --debug
  ```

- [ ] All screens display correctly
- [ ] Locale switching works
- [ ] Plurals display correctly
- [ ] Placeholders are replaced

## Troubleshooting

### "Translation not found" at runtime

Check that:
1. JSON file exists for the locale
2. Key matches exactly (msgid-based)
3. `ShardI18n.init()` was called before use

### Placeholders not replaced

Ensure parameter names match:
```dart
// JSON: "Hello, {name}!"
context.t('Hello, {name}!', params: {'name': value})  // ✓
context.t('Hello, {name}!', params: {'userName': value})  // ✗
```

### Plurals not working

Check JSON structure:
```json
{
  "key": {
    "one": "...",    // Required
    "other": "..."   // Required
  }
}
```

## Next Steps

After successful migration:

1. **Set up CI/CD** - Add extract --strict to your pipeline
2. **Configure fill** - Set up AI translation for new keys
3. **Document for team** - Share the new workflow
4. **Remove old files** - Clean up ARB files and old config
