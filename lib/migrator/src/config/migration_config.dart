import 'dart:io';
import 'package:yaml/yaml.dart';

/// Configuration for the migration process
class MigrationConfig {
  /// Key generation strategy: 'msgid' (use natural language as keys)
  /// or 'stable_id' (use semantic IDs like 'auth.sign_in')
  final String keyStrategy;

  /// Mapping of source directories to JSON feature files
  /// Example: {'lib/pages/auth/': 'auth.json', 'lib/pages/profile/': 'profile.json'}
  final Map<String, String> featureMappings;

  /// Patterns to exclude from migration
  final List<String> excludePatterns;

  /// Confidence threshold for automatic extraction (0-100)
  /// Strings with confidence below this will prompt for user review
  final int autoExtractThreshold;

  /// Source locale (typically 'en' for English)
  final String sourceLocale;

  /// Target locales to set up (empty = English only)
  final List<String> targetLocales;

  /// Whether to preserve original string formatting
  final bool preserveFormatting;

  /// Whether to generate stable IDs for volatile copy
  final bool stableIdsForVolatile;

  const MigrationConfig({
    this.keyStrategy = 'msgid',
    this.featureMappings = const {},
    this.excludePatterns = const [],
    this.autoExtractThreshold = 80,
    this.sourceLocale = 'en',
    this.targetLocales = const [],
    this.preserveFormatting = true,
    this.stableIdsForVolatile = false,
  });

  /// Load configuration from a YAML file
  static Future<MigrationConfig> load(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('Configuration file not found: $path');
    }

    final contents = await file.readAsString();
    final yaml = loadYaml(contents) as Map;

    return MigrationConfig(
      keyStrategy: yaml['key_strategy'] as String? ?? 'msgid',
      featureMappings: _parseFeatureMappings(yaml['feature_mappings']),
      excludePatterns: _parseStringList(yaml['exclude']),
      autoExtractThreshold: yaml['auto_extract_threshold'] as int? ?? 80,
      sourceLocale: yaml['source_locale'] as String? ?? 'en',
      targetLocales: _parseStringList(yaml['target_locales']),
      preserveFormatting: yaml['preserve_formatting'] as bool? ?? true,
      stableIdsForVolatile: yaml['stable_ids_for_volatile'] as bool? ?? false,
    );
  }

  /// Save configuration to a YAML file
  Future<void> save(String path) async {
    final buffer = StringBuffer();

    buffer.writeln('# Shard I18n Migration Configuration');
    buffer.writeln();
    buffer.writeln(
        '# Key generation strategy: msgid (natural language) or stable_id (semantic IDs)');
    buffer.writeln('key_strategy: $keyStrategy');
    buffer.writeln();

    buffer.writeln('# Feature mapping for sharding');
    buffer.writeln('# Maps source directories to JSON file names');
    buffer.writeln('feature_mappings:');
    if (featureMappings.isEmpty) {
      buffer.writeln('  lib/pages/auth/: auth.json');
      buffer.writeln('  lib/pages/profile/: profile.json');
      buffer.writeln('  lib/widgets/: core.json');
    } else {
      for (final entry in featureMappings.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
    }
    buffer.writeln();

    buffer.writeln('# Patterns to exclude from migration');
    buffer.writeln('exclude:');
    if (excludePatterns.isEmpty) {
      buffer.writeln('  - lib/generated/');
      buffer.writeln('  - \'**/*_test.dart\'');
      buffer.writeln('  - lib/config/');
    } else {
      for (final pattern in excludePatterns) {
        buffer.writeln('  - $pattern');
      }
    }
    buffer.writeln();

    buffer.writeln('# Confidence threshold for automatic extraction (0-100)');
    buffer
        .writeln('# Strings below this threshold will prompt for user review');
    buffer.writeln('auto_extract_threshold: $autoExtractThreshold');
    buffer.writeln();

    buffer.writeln('# Source locale (baseline language)');
    buffer.writeln('source_locale: $sourceLocale');
    buffer.writeln();

    buffer.writeln('# Target locales to set up (leave empty for English only)');
    buffer.writeln('target_locales:');
    if (targetLocales.isEmpty) {
      buffer.writeln('  # - de');
      buffer.writeln('  # - fr');
      buffer.writeln('  # - es');
    } else {
      for (final locale in targetLocales) {
        buffer.writeln('  - $locale');
      }
    }
    buffer.writeln();

    buffer.writeln('# Preserve original string formatting (multiline, etc.)');
    buffer.writeln('preserve_formatting: $preserveFormatting');
    buffer.writeln();

    buffer.writeln('# Generate stable IDs for volatile/marketing copy');
    buffer.writeln('stable_ids_for_volatile: $stableIdsForVolatile');

    await File(path).writeAsString(buffer.toString());
  }

  /// Create a default configuration
  factory MigrationConfig.createDefault() {
    return const MigrationConfig();
  }

  static Map<String, String> _parseFeatureMappings(dynamic value) {
    if (value == null) return {};
    if (value is! Map) return {};

    return Map<String, String>.fromEntries(
      value.entries.map((e) => MapEntry(e.key.toString(), e.value.toString())),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];

    return value.map((e) => e.toString()).toList();
  }
}
