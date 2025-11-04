# Shard I18n Migrator - Implementation Status

## 🎉 Phase 1: Foundation - COMPLETED

All core architecture and foundational components are fully implemented and compile successfully with zero errors.

### ✅ Completed Components

#### 1. Package Structure & Configuration
- ✅ Package directory structure (`packages/shard_i18n_migrator/`)
- ✅ pubspec.yaml with all required dependencies
  - analyzer (AST parsing)
  - path, glob (file operations)
  - yaml (configuration)
  - args (CLI parsing)
  - interact (interactive prompts)
  - logger (logging)
  - test framework
- ✅ Clean compilation (`dart analyze` passes with no errors)

#### 2. Core Models
- ✅ `AnalysisResult` - Comprehensive analysis statistics
  - Total/extractable/technical/ambiguous string counts
  - Interpolation and plural pattern counts
  - Per-file breakdown with `FileAnalysis` and `DetectedString`
- ✅ `MigrationResult` - Migration operation results
  - Created/modified file tracking
  - Statistics (strings extracted, keys generated)
  - Warnings and errors collection
- ✅ `StringCategory` enum - Classification system
  - uiText, likelyUi, ambiguous, technical, debug

#### 3. Configuration System
- ✅ `MigrationConfig` class - Full configuration support
  - Key strategy (msgid vs stable_id)
  - Feature mappings for sharding
  - Exclude patterns
  - Confidence threshold
  - Source/target locales
  - Load from YAML
  - Save template with comments

#### 4. String Detection Engine (`ProjectAnalyzer`)
- ✅ AST-based parsing using analyzer package
- ✅ Recursive visitor pattern (`StringDetectorVisitor`)
  - Visits `SimpleStringLiteral` and `StringInterpolation`
  - Extracts string values and templates
  - Handles interpolation expression parsing
- ✅ **Context Detection**
  - Widget constructor detection (Text, AppBar, Button, etc.)
  - Named parameter detection (title, hint, label, tooltip)
  - Method invocation detection (debugPrint, print)
  - Full AST tree walking for context
- ✅ **Confidence Scoring System (0-100)**
  - Base score: 50
  - Context-based: +45 for Text widget, +40 for UI widgets
  - Linguistic analysis: +10 for multi-word, +5 for capitalized
  - Technical patterns: -30 for snake_case, -40 for URLs
  - Properly clamped to 0-100 range
- ✅ **Pattern Detection**
  - Interpolation detection (StringInterpolation AST nodes)
  - Placeholder extraction from expressions
  - Plural pattern detection (conditional expressions with count == 1)
- ✅ **Classification Algorithm**
  - 90-100%: UI text (Text widgets, UI parameters)
  - 60-89%: Likely UI (natural language patterns)
  - 40-59%: Ambiguous (requires review)
  - 0-39%: Technical (code strings)

#### 5. Code Transformation (`CodeTransformer`)
- ✅ Transform orchestration framework
- ✅ String filtering by confidence threshold
- ✅ Feature determination from file paths
  - Config-based mapping
  - Auto-detection from path structure (lib/pages/auth → auth)
  - Fallback to core.json
- ✅ Key generation strategies
  - Msgid: Use natural language as keys
  - Stable ID: Generate semantic identifiers
- ✅ `TransformResult` model with extracted strings map
- ⚠️ **TODO**: Actual file rewriting (AST manipulation to replace strings)
- ⚠️ **TODO**: Import injection for shard_i18n package

#### 6. Asset Generation (`AssetGenerator`)
- ✅ JSON file generation with proper formatting
- ✅ Feature-based sharding
  - One JSON file per feature (auth.json, profile.json, core.json)
  - Organized under assets/i18n/{locale}/
- ✅ Directory creation
- ✅ Pretty-printed JSON with 2-space indentation
- ✅ Dry-run support

#### 7. Bootstrap Generation (`BootstrapGenerator`)
- ✅ **pubspec.yaml updater**
  - Adds shard_i18n dependency
  - Adds asset paths for i18n files
  - Safe modification (checks for existing entries)
- ✅ **LanguageCubit generator**
  - Complete Bloc-based state management
  - SharedPreferences persistence
  - ShardI18n integration
  - Full template with loadInitial() and changeLanguage()
- ⚠️ **TODO**: main.dart bootstrap injection
  - Need to safely inject initialization code
  - Wrap MaterialApp in AnimatedBuilder
  - Add BlocProvider

#### 8. Validation (`MigrationValidator`)
- ✅ Framework for validation
- ✅ flutter analyze integration
- ✅ JSON validation placeholder
- ⚠️ **TODO**: Comprehensive JSON validation
- ⚠️ **TODO**: Placeholder consistency checking

#### 9. Main Orchestrator (`ShardI18nMigrator`)
- ✅ High-level migration workflow
- ✅ 5-step process:
  1. Analyze project
  2. Transform code
  3. Generate assets
  4. Bootstrap setup
  5. Validate
- ✅ Dry-run support throughout pipeline
- ✅ Interactive vs automatic mode support
- ✅ Error handling with MigrationResult
- ✅ File finding with exclude pattern support

#### 10. CLI Interface
- ✅ Command structure (analyze, migrate, init)
- ✅ Argument parsing with args package
- ✅ Options:
  - `--dry-run` for preview
  - `--auto` for non-interactive mode
  - `--config` for custom config path
  - `--verbose` for detailed logging
- ✅ User-friendly output with statistics
- ✅ Usage help text

#### 11. Documentation
- ✅ Comprehensive README.md
  - Overview and features
  - Current status tracking
  - Installation and usage examples
  - How it works (detailed algorithms)
  - Configuration options
  - Architecture diagram
  - Development roadmap
- ✅ Implementation status document (this file)

### 📊 Statistics

**Files Created**: 15
- 1 pubspec.yaml
- 1 CLI entry point
- 1 main library export
- 3 model files
- 1 config file
- 5 core component files
- 2 documentation files

**Lines of Code**: ~1,700 (excluding comments)
- Models: ~250 lines
- Config: ~150 lines
- ProjectAnalyzer: ~400 lines
- Transformers/Generators: ~600 lines
- CLI & Orchestrator: ~300 lines

**Compilation Status**: ✅ Zero errors, zero warnings

---

## 🚧 Phase 2: Implementation - TODO

These components have frameworks in place but need full implementation.

### High Priority

#### 1. Code Rewriting Engine
**Status**: Framework exists, needs implementation

**TODO**:
- [ ] AST-based code modification using analyzer
- [ ] Replace string literals with `context.t()` calls
- [ ] Handle interpolation conversion
  - `'Hello, $name'` → `context.t('Hello, {name}!', params: {'name': name})`
- [ ] Generate plural calls
  - Ternary → `context.tn('key', count: count)`
- [ ] Preserve code formatting
- [ ] Handle edge cases (raw strings, const strings, concatenation)

**Approach**:
```dart
// Use analyzer's SourceEdit for safe transformations
final edits = <SourceEdit>[];

for (final string in detectedStrings) {
  final replacement = _generateReplacement(string);
  edits.add(SourceEdit(string.offset, string.length, replacement));
}

final newSource = SourceEdit.applySequence(originalSource, edits);
```

#### 2. Import Manager
**Status**: Not started

**TODO**:
- [ ] Detect if shard_i18n is already imported
- [ ] Add import at appropriate location (after flutter imports)
- [ ] Handle import conflicts
- [ ] Organize imports correctly

**Approach**:
```dart
// Check existing imports
final hasImport = compilationUnit.directives
    .whereType<ImportDirective>()
    .any((d) => d.uri.stringValue == 'package:shard_i18n/shard_i18n.dart');

if (!hasImport) {
  // Find insertion point (after last import)
  // Insert: import 'package:shard_i18n/shard_i18n.dart';
}
```

#### 3. Interactive CLI Prompting
**Status**: Framework exists, needs implementation

**TODO**:
- [ ] Integrate `interact` package
- [ ] Prompt user for ambiguous strings (40-80% confidence)
- [ ] Options: Yes/No/Skip all similar
- [ ] Show context and snippet
- [ ] Remember user choices for similar patterns

**Approach**:
```dart
import 'package:interact/interact.dart';

if (string.category == StringCategory.ambiguous) {
  final choice = Confirm(
    prompt: 'Extract "${string.value}"? (confidence: ${string.confidence}%)',
    defaultValue: false,
  ).interact();

  if (!choice) continue;
}
```

#### 4. main.dart Bootstrap Injection
**Status**: Not started

**TODO**:
- [ ] Parse main.dart safely
- [ ] Inject initialization code before runApp()
- [ ] Wrap MaterialApp in AnimatedBuilder
- [ ] Add BlocProvider
- [ ] Add localizationsDelegates
- [ ] Handle existing bootstrap code (avoid duplicates)

**Approach**:
```dart
// Find main() function
// Find runApp() call
// Inject before runApp():
//   - WidgetsFlutterBinding.ensureInitialized()
//   - final locale = await LanguageCubit.loadInitial()
//   - await ShardI18n.instance.bootstrap(locale)
//
// Modify runApp() to wrap in BlocProvider
```

### Medium Priority

#### 5. JSON Validation
**Status**: Placeholder exists

**TODO**:
- [ ] Validate JSON syntax
- [ ] Check placeholder consistency between code and JSON
- [ ] Verify plural forms match CLDR rules
- [ ] Detect duplicate keys
- [ ] Check for orphaned keys (in JSON but not in code)

#### 6. Comprehensive Testing
**Status**: Not started

**TODO**:
- [ ] Unit tests for each component
  - String detection accuracy
  - Confidence scoring correctness
  - Interpolation conversion
  - Plural pattern detection
  - Key generation
- [ ] Integration tests
  - End-to-end migration on sample projects
  - Dry-run vs actual run consistency
- [ ] Test fixtures
  - Minimal app (10 strings)
  - Medium app (100 strings)
  - Large app (500+ strings)
  - Edge cases (plurals, complex interpolation)

### Low Priority (Future Enhancements)

#### 7. Advanced Features
- [ ] Stable ID generation with semantic naming
- [ ] Context-specific key prefixes
- [ ] Auto-detection of string constants for extraction
- [ ] Multiline string handling optimization
- [ ] String concatenation merging
- [ ] Support for adjacent string literals
- [ ] Better plural form detection (handle more patterns)

#### 8. VS Code Extension (Phase 3)
- [ ] Extension scaffold
- [ ] Right-click "Extract to shard_i18n"
- [ ] Hover to preview translations
- [ ] Quick-fix suggestions
- [ ] Navigate to JSON definitions
- [ ] Inline warnings for missing translations

---

## 🎯 Next Steps (Recommended Order)

Based on the plan, here's the suggested implementation sequence:

### Week 1: Code Rewriting
1. Implement AST-based string replacement
2. Add context.t() generation for simple strings
3. Handle interpolation conversion
4. Test on simple examples

### Week 2: Import & Integration
1. Implement import manager
2. Add main.dart bootstrap injection
3. Test end-to-end on minimal project
4. Fix any integration issues

### Week 3: Interactive & Polish
1. Implement interactive CLI prompting
2. Add better progress reporting
3. Enhance validation
4. Improve error messages

### Week 4: Testing & Refinement
1. Create test fixtures
2. Write comprehensive test suite
3. Test on real projects
4. Fix bugs and edge cases

### Week 5: Documentation & Release
1. Write user guide
2. Create migration examples
3. Record demo video
4. Publish to pub.dev

---

## 💡 Design Decisions

### Why Msgid-first?
- More readable code
- Self-documenting
- Easier to maintain
- Aligns with shard_i18n philosophy

### Why Feature-based Sharding?
- Avoids merge conflicts
- Clear ownership
- Scales well with team size
- Follows shard_i18n best practices

### Why Interactive Mode?
- Safer for ambiguous cases
- Builds user confidence
- Allows learning from user choices
- Prevents false positives

### Why Dry-run by Default?
- Preview before committing
- Builds trust
- Allows review
- Standard for migration tools

---

## 🧪 Testing Strategy

### Unit Tests (Per Component)
- String detection: 95%+ precision, <5% false negatives
- Confidence scoring: Validate against known examples
- Pattern detection: Cover all interpolation and plural patterns
- Key generation: Verify uniqueness and format

### Integration Tests (End-to-End)
- Minimal app: All strings extracted correctly
- Medium app: Feature sharding works
- Large app: Performance (< 2 min for 1000 files)
- Edge cases: Complex patterns handled

### Validation Tests
- Generated code compiles
- App runs without errors
- Translations load correctly
- Locale switching works

### Acceptance Criteria
- ✅ >95% string detection accuracy
- ✅ <5% false negatives on UI strings
- ✅ 100% generated code compiles
- ✅ All extracted strings display correctly
- ✅ Interactive mode resolves ambiguity

---

## 📚 References

- [Shard I18n Documentation](../../README.md)
- [Dart Analyzer Package](https://pub.dev/packages/analyzer)
- [Flutter Internationalization](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [CLDR Plural Rules](https://cldr.unicode.org/index/cldr-spec/plural-rules)

---

## 🤝 Contributing

This is an active project. Contributions are welcome!

**Areas where help is needed**:
1. Code rewriting implementation
2. Test fixtures and examples
3. Edge case handling
4. Documentation and guides
5. VS Code extension

See the main shard_i18n repository for contribution guidelines.
