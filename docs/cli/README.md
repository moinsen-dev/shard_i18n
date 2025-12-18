# CLI Tools Overview

shard_i18n includes powerful command-line tools for managing translations.

## Available Commands

| Command | Description |
|---------|-------------|
| [verify](verify.md) | Check translation consistency across locales |
| [fill](fill.md) | Auto-translate missing keys using AI |
| [extract](extract.md) | Scan code for i18n keys and compare with JSON |

## Installation

The CLI tools are included with the shard_i18n package. Run them via:

```bash
dart run shard_i18n_cli <command> [options]
```

Or if installed globally:

```bash
shard_i18n_cli <command> [options]
```

## Quick Reference

### Verify Translations

```bash
# Check all translations
dart run shard_i18n_cli verify

# Check custom path
dart run shard_i18n_cli verify --path=assets/i18n
```

### Extract and Analyze

```bash
# Scan code and report discrepancies
dart run shard_i18n_cli extract

# Auto-fix missing keys
dart run shard_i18n_cli extract --fix

# Remove orphaned keys
dart run shard_i18n_cli extract --prune

# CI mode (exit 1 on issues)
dart run shard_i18n_cli extract --strict
```

### Fill Translations

```bash
# Translate to German using OpenAI
dart run shard_i18n_cli fill \
  --from=en \
  --to=de \
  --provider=openai \
  --key=$OPENAI_API_KEY

# Preview without writing
dart run shard_i18n_cli fill \
  --from=en \
  --to=de,fr,es \
  --provider=openai \
  --key=$OPENAI_API_KEY \
  --dry-run
```

## Global Options

```
-h, --help       Display help message
-v, --version    Display version information
```

## Workflow

A typical translation workflow:

```bash
# 1. Extract keys from code and check status
dart run shard_i18n_cli extract

# 2. Auto-generate missing English entries
dart run shard_i18n_cli extract --fix

# 3. Translate to other locales
dart run shard_i18n_cli fill --from=en --to=de,fr --provider=openai --key=$KEY

# 4. Verify all translations are consistent
dart run shard_i18n_cli verify

# 5. Clean up orphaned keys
dart run shard_i18n_cli extract --prune
```

## CI/CD Integration

Add to your CI pipeline:

```yaml
# GitHub Actions example
- name: Check translations
  run: |
    dart run shard_i18n_cli extract --strict
    dart run shard_i18n_cli verify
```

See [CI/CD Setup](../guides/ci-cd.md) for detailed examples.
