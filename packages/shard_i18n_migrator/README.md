# Shard I18n Migrator

Automated migration tool for converting Flutter applications from hardcoded strings to the shard_i18n internationalization system.

## Overview

The Shard I18n Migrator is an intelligent CLI tool that:

1. **Analyzes** your Flutter project to identify translatable strings
2. **Classifies** strings using confidence scoring (UI vs technical strings)
3. **Transforms** your code to use `context.t()` and `context.tn()`
4. **Generates** translation JSON files with feature-based sharding
5. **Configures** your project with necessary dependencies and bootstrap code
6. **Validates** the migrated project for correctness

## Features

- ✅ **Intelligent String Detection**: Uses AST parsing to find string literals
- ✅ **Context-Aware Classification**: Scores confidence based on widget context
- ✅ **Interpolation Handling**: Converts `$var` and `${expr}` to `{placeholder}` syntax
- ✅ **Plural Pattern Detection**: Identifies and converts ternary plural patterns
- ✅ **Feature-Based Sharding**: Organizes translations by app features
- ✅ **Interactive Mode**: Prompts for ambiguous strings
- ✅ **Dry-Run Preview**: See changes before applying them
- ✅ **Configurable**: Supports migration_config.yaml for customization
- ✅ **Safe**: Validates generated code with flutter analyze

## Current Status

**Phase 1 (Foundation) - ✅ COMPLETED**

The core architecture is fully implemented and compiles successfully:

- ✅ Package structure with all dependencies
- ✅ AST parser using analyzer package
- ✅ String detection with context classification
- ✅ Confidence scoring system (0-100)
- ✅ Core models (AnalysisResult, MigrationResult)
- ✅ Migration configuration system
- ✅ Code transformation framework
- ✅ JSON asset generation with sharding
- ✅ Bootstrap code generation (pubspec, LanguageCubit)
- ✅ Migration validator

**Phase 2 (Implementation) - 🚧 IN PROGRESS**

Next steps:
- ⏳ Implement actual code rewriting (replace strings with context.t())
- ⏳ Add import injection for shard_i18n package
- ⏳ Implement interactive CLI prompting
- ⏳ Add main.dart bootstrap injection
- ⏳ Comprehensive testing

## Installation

```bash
# From the shard_i18n repository
cd packages/shard_i18n_migrator
dart pub get
```

## Usage

### Analyze Your Project

Preview what strings will be extracted:

```bash
dart run shard_i18n_migrator analyze lib/
```

Output:
```
Analysis Results:
────────────────────────────────────────────────────────────
Total string literals found: 247
Extractable UI strings: 198
Technical/code strings: 35
Ambiguous strings (require review): 14

Interpolation patterns detected: 23
Plural patterns detected: 8

Average confidence score: 87.3%
────────────────────────────────────────────────────────────
```

### Initialize Configuration

Create a customizable migration config:

```bash
dart run shard_i18n_migrator init
```

This creates `migration_config.yaml`:

```yaml
# Key generation strategy: msgid (natural language) or stable_id (semantic IDs)
key_strategy: msgid

# Feature mapping for sharding
feature_mappings:
  lib/pages/auth/: auth.json
  lib/pages/profile/: profile.json
  lib/widgets/: core.json

# Patterns to exclude from migration
exclude:
  - lib/generated/
  - '**/*_test.dart'
  - lib/config/

# Confidence threshold for automatic extraction (0-100)
auto_extract_threshold: 80

# Source locale (baseline language)
source_locale: en

# Target locales to set up
target_locales:
  # - de
  # - fr
  # - es

# Preserve original string formatting
preserve_formatting: true

# Generate stable IDs for volatile/marketing copy
stable_ids_for_volatile: false
```

### Dry Run Migration

Preview changes without modifying files:

```bash
dart run shard_i18n_migrator migrate lib/ --dry-run
```

### Interactive Migration

Migrate with prompts for ambiguous strings:

```bash
dart run shard_i18n_migrator migrate lib/
```

Example interaction:
```
Found: "production" (confidence: 52%)
Context: final mode = "production";
Extract this string? [y/N/s(kip all)]
> N

Found: "Hello, $userName!" (confidence: 95%)
Context: Text widget
Key: "Hello, {name}!"
Accept? [Y/n]
> Y
```

### Automatic Migration

Use configuration file, no prompts:

```bash
dart run shard_i18n_migrator migrate lib/ --auto
```

## How It Works

### 1. String Detection

The analyzer uses the Dart `analyzer` package to parse your code into an Abstract Syntax Tree (AST). It then visits each string literal and classifies it.

**Detection Algorithm**:

```dart
// High confidence (95%): Text widget
Text('Sign in')

// High confidence (90%): UI parameters
TextField(hintText: 'Enter email')

// Medium confidence (75%): Multi-word, capitalized
final message = 'Welcome to the app';

// Low confidence (30%): Technical patterns
const apiKey = 'production_api_key';  // snake_case
const url = 'https://api.example.com';  // URL pattern
```

**Confidence Scoring**:
- **90-100**: Widget context (Text, AppBar title, etc.)
- **60-89**: Natural language patterns (multi-word, capitalized)
- **40-59**: Ambiguous (requires manual review)
- **0-39**: Technical (URLs, keys, debug strings)

### 2. Pattern Detection

**Interpolation**:
```dart
// Before
Text('Hello, $userName!')

// After
Text(context.t('Hello, {name}!', params: {'name': userName}))
```

**Pluralization**:
```dart
// Before
Text('${count} item${count == 1 ? '' : 's'}')

// After
Text(context.tn('items_count', count: count))

// Generated JSON
{
  "items_count": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

### 3. Feature-Based Sharding

Organizes translations by app features to avoid merge conflicts:

```
assets/i18n/
  en/
    core.json       # App-wide strings
    auth.json       # lib/pages/auth/
    profile.json    # lib/pages/profile/
    settings.json   # lib/pages/settings/
```

### 4. Bootstrap Generation

Automatically sets up your project:

**pubspec.yaml**:
```yaml
dependencies:
  shard_i18n: ^0.1.0

flutter:
  assets:
    - assets/i18n/en/
```

**lib/language_cubit.dart**:
```dart
class LanguageCubit extends Cubit<Locale> {
  // State management for locale switching
  // Persists to SharedPreferences
}
```

**lib/main.dart** (TODO):
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final locale = await LanguageCubit.loadInitial();
  await ShardI18n.instance.bootstrap(locale);

  runApp(
    BlocProvider(
      create: (_) => LanguageCubit(locale),
      child: MyApp(),
    ),
  );
}
```

## Configuration Options

### Key Strategies

**1. Msgid (Recommended)**
- Uses natural language as keys
- Readable and self-documenting
- Example: `"Sign in"` → `"Sign in"`

**2. Stable ID**
- Generates semantic keys
- Better for frequently changing copy
- Example: `"Sign in"` → `"auth.sign_in_button"`

### Feature Mappings

Map source directories to JSON files:

```yaml
feature_mappings:
  lib/pages/auth/login.dart: auth.json
  lib/pages/auth/signup.dart: auth.json
  lib/pages/profile/: profile.json
  lib/features/cart/: cart.json
```

Unmapped files default to `core.json`.

### Exclude Patterns

Skip files from migration:

```yaml
exclude:
  - lib/generated/
  - '**/*_test.dart'
  - lib/config/constants.dart
```

## Architecture

```
shard_i18n_migrator/
├── bin/
│   └── shard_i18n_migrator.dart       # CLI entry point
├── lib/
│   ├── src/
│   │   ├── analyzer/
│   │   │   └── project_analyzer.dart   # AST parsing & string detection
│   │   ├── transformer/
│   │   │   └── code_transformer.dart   # Code modification
│   │   ├── generator/
│   │   │   ├── asset_generator.dart    # JSON file generation
│   │   │   └── bootstrap_generator.dart # Setup code generation
│   │   ├── validator/
│   │   │   └── migration_validator.dart # Validation
│   │   ├── config/
│   │   │   └── migration_config.dart   # Configuration
│   │   └── models/
│   │       ├── analysis_result.dart
│   │       └── migration_result.dart
│   └── shard_i18n_migrator.dart       # Public API
└── pubspec.yaml
```

## Development Status

| Component | Status | Notes |
|-----------|--------|-------|
| AST Parser | ✅ Complete | Uses analyzer package |
| String Detection | ✅ Complete | Context-aware classification |
| Confidence Scoring | ✅ Complete | 0-100 scoring system |
| Interpolation Detection | ✅ Complete | Handles $var and ${expr} |
| Plural Detection | ✅ Complete | Ternary pattern recognition |
| Code Transformation | ⚠️ Partial | Framework done, needs file editing |
| Import Injection | ⏳ TODO | Add shard_i18n imports |
| JSON Generation | ✅ Complete | Feature-based sharding |
| Bootstrap Generation | ⚠️ Partial | pubspec + cubit done, main.dart TODO |
| Interactive CLI | ⏳ TODO | User prompts for ambiguous cases |
| Validation | ⚠️ Partial | Basic flutter analyze integration |
| Tests | ⏳ TODO | Unit and integration tests needed |

## Next Steps

1. **Implement Code Rewriting**: Actually modify .dart files to replace strings with context.t()
2. **Import Manager**: Add `import 'package:shard_i18n/shard_i18n.dart';` to files
3. **Interactive Prompting**: Use `interact` package for user input
4. **Main.dart Injection**: Safely inject bootstrap code into main.dart
5. **Comprehensive Testing**: Test on real projects of varying sizes
6. **VS Code Extension**: Future phase 2 deliverable

## Contributing

This is part of the shard_i18n project. See the main repository for contribution guidelines.

## License

MIT License - See repository root for details.
