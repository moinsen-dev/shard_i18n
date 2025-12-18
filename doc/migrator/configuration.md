# Migrator Configuration

Configure the migrator behavior using command-line options or a configuration file.

## Configuration File

Create `shard_i18n_migrator.yaml` in your project root:

```yaml
# Source i18n system (auto-detected if not specified)
source: gen_l10n

# Paths
paths:
  project: .
  output: assets/i18n

# Locale settings
locales:
  reference: en
  supported: [en, de, fr, es]

# Shard organization
sharding:
  strategy: feature  # single, feature, custom
  custom_mapping:
    auth: [login, register, password, forgot]
    settings: [preferences, account, notifications]
    default: core

# Code transformation
transform:
  update_imports: true
  preserve_comments: true
  format_output: true

# Safety options
safety:
  create_backup: true
  backup_path: .shard_i18n_backup
  dry_run: false

# Cleanup
cleanup:
  remove_old_files: false
  remove_l10n_yaml: false
  remove_arb_files: false
```

## Source Systems

### gen_l10n Configuration

```yaml
source: gen_l10n

gen_l10n:
  arb_dir: lib/l10n
  template_arb_file: app_en.arb
  output_class: AppLocalizations
```

### easy_localization Configuration

```yaml
source: easy_localization

easy_localization:
  assets_path: assets/translations
  fallback_locale: en_US
  supported_locales: [en_US, de_DE, fr_FR]
```

### intl Configuration

```yaml
source: intl

intl:
  messages_dir: lib/src/messages
  generate_from_arb: true
```

## Sharding Strategies

### Single Shard

All translations in one file per locale:

```yaml
sharding:
  strategy: single
```

**Result:**
```
assets/i18n/
├── en/core.json  # All keys
├── de/core.json
└── fr/core.json
```

### Feature-Based Sharding

Automatically organize by source file location:

```yaml
sharding:
  strategy: feature
  feature_detection:
    base_path: lib/features
    depth: 1  # lib/features/[feature_name]/...
```

**Result:**
```
assets/i18n/
├── en/
│   ├── core.json      # lib/*, lib/common/*
│   ├── auth.json      # lib/features/auth/*
│   ├── home.json      # lib/features/home/*
│   └── settings.json  # lib/features/settings/*
```

### Custom Sharding

Define explicit key-to-shard mapping:

```yaml
sharding:
  strategy: custom
  custom_mapping:
    # Shard name: list of key prefixes/patterns
    auth:
      - login
      - register
      - password
      - "Sign in"
      - "Sign up"
    onboarding:
      - welcome
      - tutorial
      - "Get started"
    errors:
      - error_
      - "Error:"
      - "Failed to"
    default: core  # Fallback shard
```

## Transform Options

### Import Handling

```yaml
transform:
  update_imports: true
  import_style: package  # package or relative

  # Custom import mapping
  import_replacements:
    'package:flutter_gen/gen_l10n/app_localizations.dart': 'package:shard_i18n/shard_i18n.dart'
```

### Code Style

```yaml
transform:
  # Preserve existing code comments
  preserve_comments: true

  # Format output with dart format
  format_output: true

  # Line length for formatting
  line_length: 80

  # Quote style for strings
  quote_style: single  # single or double
```

### API Mapping

```yaml
transform:
  # How to transform API calls
  api_mapping:
    # AppLocalizations.of(context)!.key -> context.t('msgid')
    simple: context_t

    # AppLocalizations.of(context)!.key(param) -> context.t('msgid', params: {...})
    with_params: context_t_params

    # Plural forms
    plural: context_tn
```

## Safety Options

### Backup Configuration

```yaml
safety:
  # Create backup before modifying files
  create_backup: true

  # Backup location
  backup_path: .shard_i18n_backup

  # Include timestamp in backup folder
  timestamped_backup: true

  # Keep N most recent backups
  max_backups: 5
```

### Validation

```yaml
safety:
  # Validate translations after migration
  validate_output: true

  # Fail on warnings
  strict_mode: false

  # Skip files with errors
  skip_errors: true
```

## Cleanup Options

```yaml
cleanup:
  # Remove source i18n files after successful migration
  remove_old_files: false

  # Specific file types to remove
  remove_l10n_yaml: false
  remove_arb_files: false
  remove_generated_dart: false

  # Update pubspec.yaml
  update_pubspec: true
  remove_old_dependencies: false
```

## Environment Variables

Override configuration with environment variables:

```bash
# Override output path
SHARD_I18N_OUTPUT=custom/path dart run shard_i18n_migrator migrate

# Force dry run
SHARD_I18N_DRY_RUN=true dart run shard_i18n_migrator migrate

# Skip backup
SHARD_I18N_BACKUP=false dart run shard_i18n_migrator migrate
```

## Command-Line Overrides

Command-line options override config file:

```bash
# Config file says dry_run: false, but override with --dry-run
dart run shard_i18n_migrator migrate --dry-run

# Override shard strategy
dart run shard_i18n_migrator migrate --shard-strategy=single

# Override output path
dart run shard_i18n_migrator migrate --output=custom/i18n
```

## Example Configurations

### Minimal Configuration

```yaml
# Minimal - use all defaults
source: gen_l10n
```

### Team Project

```yaml
source: gen_l10n

sharding:
  strategy: feature

safety:
  create_backup: true

cleanup:
  remove_old_files: false  # Keep old files for review
```

### CI/CD Pipeline

```yaml
source: gen_l10n

safety:
  create_backup: false  # CI handles version control
  dry_run: false
  strict_mode: true

cleanup:
  remove_old_files: true
  update_pubspec: true
```

### Large Monorepo

```yaml
source: gen_l10n

paths:
  project: packages/my_app
  output: packages/my_app/assets/i18n

sharding:
  strategy: custom
  custom_mapping:
    shared: [common_, shared_]
    feature_a: [feature_a_]
    feature_b: [feature_b_]
    default: app
```
