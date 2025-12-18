# extract Command

The `extract` command scans your Dart source code for i18n API usage and compares it against your JSON translation files.

## Usage

```bash
dart run shard_i18n_cli extract [options]
```

## Options

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--path` | `-p` | `lib/` | Source directory to scan |
| `--i18n` | `-i` | `assets/i18n` | Path to i18n assets directory |
| `--format` | `-f` | `text` | Output format (`text`, `json`, `diff`) |
| `--locale` | `-l` | `en` | Reference locale to compare against |
| `--fix` | | | Auto-generate missing entries |
| `--prune` | | | Remove orphaned keys from JSON |
| `--dry-run` | | | Preview changes without writing |
| `--strict` | | | Exit code 1 on discrepancies (for CI) |
| `--verbose` | `-v` | | Show per-file breakdown |

## Detection Patterns

The extract command detects all shard_i18n API usage patterns:

```dart
// Context extension methods
context.t('Hello, world!')
context.t('Welcome, {name}!', params: {'name': userName})
context.tn('item_count', count: itemCount)

// String extension methods
'Hello, world!'.tx
'Welcome, {name}!'.t({'name': userName})
'item_count'.tn(count: itemCount)
```

## Output Formats

### Text (Default)

Human-readable format with statistics and categorized findings:

```bash
dart run shard_i18n_cli extract
```

**Output:**
```
🔍 Scanning lib/ for i18n usage...
📊 Comparing against assets/i18n/en...

✅ Statistics:
   Files scanned:     42
   Keys in code:      156
   Keys in JSON:      160
   Matched:           152 (97.4%)
   Missing in JSON:   4
   Orphaned in JSON:  8

❌ Missing in JSON (4):
   • "New feature coming soon!"
   • "Upload failed: {error}"
   • "item_deleted"
   • "Welcome back, {name}!"

⚠️  Orphaned in JSON (8):
   • "old_feature_text"
   • "deprecated_message"
   ...
```

### JSON

Machine-readable format for CI/CD integration:

```bash
dart run shard_i18n_cli extract --format=json
```

**Output:**
```json
{
  "statistics": {
    "filesScanned": 42,
    "keysInCode": 156,
    "keysInJson": 160,
    "matched": 152,
    "coveragePercent": 97.4,
    "missingCount": 4,
    "orphanedCount": 8
  },
  "missingInJson": [
    "New feature coming soon!",
    "Upload failed: {error}"
  ],
  "orphanedInJson": [
    "old_feature_text",
    "deprecated_message"
  ],
  "placeholderMismatches": [],
  "pluralIssues": []
}
```

### Diff

Git-style diff format showing additions and removals:

```bash
dart run shard_i18n_cli extract --format=diff
```

**Output:**
```diff
--- code keys
+++ json keys

+ New feature coming soon!
+ Upload failed: {error}
+ item_deleted
+ Welcome back, {name}!
- old_feature_text
- deprecated_message
```

## Auto-Fix Mode

Automatically generate missing entries in your reference locale:

```bash
# Preview what would be added
dart run shard_i18n_cli extract --fix --dry-run

# Apply fixes
dart run shard_i18n_cli extract --fix
```

**Behavior:**
- Creates entries where `msgid = value` (English text as both key and value)
- Detects plural keys (used with `tn()`) and creates proper plural forms:
  ```json
  {
    "item_count": {
      "one": "item_count",
      "other": "item_count"
    }
  }
  ```
- Writes to `core.json` by default (or detects shard from source path)

## Prune Mode

Remove orphaned keys that exist in JSON but are no longer used in code:

```bash
# Preview what would be removed
dart run shard_i18n_cli extract --prune --dry-run

# Remove orphaned keys
dart run shard_i18n_cli extract --prune
```

> **Warning:** Always use `--dry-run` first to preview changes before pruning.

## CI/CD Integration

Use `--strict` mode to fail the build when discrepancies are found:

```bash
dart run shard_i18n_cli extract --strict --format=json
```

**Exit codes:**
- `0` - All keys are in sync
- `1` - Discrepancies found (missing or orphaned keys)

### GitHub Actions Example

```yaml
name: i18n Check

on: [push, pull_request]

jobs:
  i18n:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1

      - name: Install dependencies
        run: dart pub get

      - name: Check i18n consistency
        run: dart run shard_i18n_cli extract --strict
```

### GitLab CI Example

```yaml
i18n-check:
  stage: test
  script:
    - dart pub get
    - dart run shard_i18n_cli extract --strict --format=json
  artifacts:
    reports:
      dotenv: i18n-report.json
```

## Verbose Mode

Show per-file breakdown of where keys are found:

```bash
dart run shard_i18n_cli extract --verbose
```

**Output:**
```
🔍 Scanning lib/ for i18n usage...

📁 lib/features/auth/login_page.dart
   Found 8 key(s):
   • "Email" (line 42)
   • "Password" (line 56)
   • "Sign In" (line 78)
   ...

📁 lib/features/home/home_page.dart
   Found 12 key(s):
   ...
```

## Examples

### Basic Usage

```bash
# Scan lib/ and compare with assets/i18n/en
dart run shard_i18n_cli extract
```

### Custom Paths

```bash
# Scan specific directory with custom i18n path
dart run shard_i18n_cli extract \
  --path=lib/features \
  --i18n=assets/translations \
  --locale=de
```

### Full Sync Workflow

```bash
# 1. Check current state
dart run shard_i18n_cli extract

# 2. Preview fixes
dart run shard_i18n_cli extract --fix --dry-run

# 3. Apply fixes
dart run shard_i18n_cli extract --fix

# 4. Translate new keys
dart run shard_i18n_cli fill --from=en --to=de,fr,es --provider=openai --key=$OPENAI_API_KEY

# 5. Verify all locales
dart run shard_i18n_cli verify
```

### Cleanup Workflow

```bash
# 1. Find orphaned keys
dart run shard_i18n_cli extract --format=diff

# 2. Preview what would be removed
dart run shard_i18n_cli extract --prune --dry-run

# 3. Remove orphaned keys
dart run shard_i18n_cli extract --prune

# 4. Commit changes
git add assets/i18n/
git commit -m "chore: remove orphaned i18n keys"
```

## Placeholder Detection

The extract command detects placeholders in both code and JSON:

**Code:**
```dart
context.t('Hello, {name}!', params: {'name': userName})
```

**JSON:**
```json
{
  "Hello, {name}!": "Hello, {name}!"
}
```

If placeholders don't match, you'll see a warning:

```
⚠️  Placeholder mismatches (1):
   • "Hello, {name}!"
     Code: {name}
     JSON: {firstName}
```

## Plural Form Validation

For keys used with `tn()`, the command validates plural forms:

**Expected JSON structure:**
```json
{
  "item_count": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

**Warnings shown for:**
- Plural key without proper map structure
- Missing `one` or `other` forms

## Shard Detection

When using `--fix`, the command intelligently assigns keys to shards based on source file location:

| Source Path | Target Shard |
|-------------|--------------|
| `lib/auth/*` | `auth.json` |
| `lib/settings/*` | `settings.json` |
| `lib/features/profile/*` | `profile.json` |
| Default | `core.json` |

## Best Practices

### Run Before Commits

Add to your pre-commit hook:

```bash
#!/bin/sh
dart run shard_i18n_cli extract --strict
```

### Regular Cleanup

Schedule regular cleanup of orphaned keys:

```bash
# Monthly cleanup
dart run shard_i18n_cli extract --prune
```

### Keep in Sync

After adding new UI text:

1. Run `extract --fix` to add missing keys
2. Run `fill` to translate to other locales
3. Run `verify` to ensure consistency

## Error Handling

### File Not Found

```
Error: Locale directory not found: assets/i18n/en
Make sure the i18n path and reference locale are correct.
```

**Solution:** Check `--i18n` and `--locale` arguments.

### Parse Errors

```
Warning: Could not parse lib/broken_file.dart: ...
```

**Solution:** Fix Dart syntax errors in the reported file.

## Related Commands

- [verify](verify.md) - Verify translation consistency across locales
- [fill](fill.md) - Auto-translate missing keys using AI
