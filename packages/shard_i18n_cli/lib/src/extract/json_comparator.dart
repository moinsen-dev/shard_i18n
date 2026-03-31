/// Compares extracted i18n keys from source code against JSON translation files.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'extraction_result.dart';

/// Compares code keys against JSON translation files.
class JsonComparator {
  /// Path to i18n assets directory (e.g., 'assets/i18n').
  final String i18nPath;

  /// Reference locale to compare against (e.g., 'en').
  final String referenceLocale;

  /// Callback for logging messages.
  final void Function(String message)? onLog;

  JsonComparator({
    required this.i18nPath,
    this.referenceLocale = 'en',
    this.onLog,
  });

  /// Load all keys from JSON files for the reference locale.
  Future<Set<String>> loadJsonKeys() async {
    final translations = await loadTranslations();
    return _flattenKeys(translations);
  }

  /// Load full translation data (for placeholder/plural analysis).
  Future<Map<String, dynamic>> loadTranslations() async {
    final localeDir = Directory(p.join(i18nPath, referenceLocale));
    final merged = <String, dynamic>{};

    if (!await localeDir.exists()) {
      throw StateError(
        'Locale directory not found: ${localeDir.path}. '
        'Make sure the i18n path and reference locale are correct.',
      );
    }

    await for (final entity in localeDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final Map<String, dynamic> data = json.decode(content);
          merged.addAll(data);
          _log('Loaded ${data.length} keys from ${p.basename(entity.path)}');
        } catch (e) {
          _log('Warning: Could not read ${entity.path}: $e');
        }
      }
    }

    return merged;
  }

  /// Load translations organized by shard file.
  Future<Map<String, Map<String, dynamic>>> loadTranslationsByFile() async {
    final localeDir = Directory(p.join(i18nPath, referenceLocale));
    final byFile = <String, Map<String, dynamic>>{};

    if (!await localeDir.exists()) {
      return byFile;
    }

    await for (final entity in localeDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final Map<String, dynamic> data = json.decode(content);
          byFile[entity.path] = data;
        } catch (e) {
          _log('Warning: Could not read ${entity.path}: $e');
        }
      }
    }

    return byFile;
  }

  /// Compare extraction result against JSON translations.
  Future<ComparisonResult> compare(ExtractionResult extracted) async {
    final jsonTranslations = await loadTranslations();
    final jsonKeys = _flattenKeys(jsonTranslations);

    // Find missing and orphaned keys
    final missingInJson = extracted.uniqueKeys.difference(jsonKeys);
    final orphanedInJson = jsonKeys.difference(extracted.uniqueKeys);
    final matchedKeys = extracted.uniqueKeys.intersection(jsonKeys);

    // Check placeholder mismatches
    final placeholderMismatches = <String, PlaceholderMismatch>{};
    for (final key in matchedKeys) {
      final codePlaceholders = extracted.placeholdersByKey[key] ?? {};
      final jsonValue = jsonTranslations[key];
      final jsonPlaceholders = _extractJsonPlaceholders(jsonValue);

      if (codePlaceholders.isNotEmpty || jsonPlaceholders.isNotEmpty) {
        if (!_setsEqual(codePlaceholders, jsonPlaceholders)) {
          placeholderMismatches[key] = PlaceholderMismatch(
            key: key,
            inCode: codePlaceholders,
            inJson: jsonPlaceholders,
          );
        }
      }
    }

    // Check plural form issues
    final pluralIssues = <String, PluralFormIssue>{};
    for (final key in extracted.pluralKeys) {
      if (missingInJson.contains(key)) continue;

      final jsonValue = jsonTranslations[key];
      if (jsonValue is! Map) {
        pluralIssues[key] = PluralFormIssue(
          key: key,
          message: 'Key is used as plural (tn) but JSON value is not a map',
          missingPluralForms: true,
        );
      } else {
        // Check for required plural forms
        final forms = jsonValue.keys.toSet().cast<String>();
        if (!forms.contains('one') && !forms.contains('other')) {
          pluralIssues[key] = PluralFormIssue(
            key: key,
            message: 'Plural forms missing "one" or "other"',
            availableForms: forms,
          );
        }
      }
    }

    // Build statistics
    final stats = Statistics(
      totalKeysInCode: extracted.uniqueKeys.length,
      totalKeysInJson: jsonKeys.length,
      matchedCount: matchedKeys.length,
      missingCount: missingInJson.length,
      orphanedCount: orphanedInJson.length,
      filesScanned: extracted.filesScanned,
      jsonFilesLoaded: await _countJsonFiles(),
    );

    return ComparisonResult(
      missingInJson: missingInJson,
      orphanedInJson: orphanedInJson,
      matchedKeys: matchedKeys,
      placeholderMismatches: placeholderMismatches,
      pluralIssues: pluralIssues,
      stats: stats,
    );
  }

  /// Detect which shard a key should belong to based on source file path.
  ///
  /// Uses heuristics based on the source file location:
  /// - lib/auth/* -> auth.json
  /// - lib/settings/* -> settings.json
  /// - Default: core.json
  String detectShard(String key, String? sourceFilePath) {
    if (sourceFilePath == null) return 'core.json';

    // Extract feature name from path
    final parts = p.split(sourceFilePath);
    final libIndex = parts.indexOf('lib');

    if (libIndex >= 0 && libIndex + 1 < parts.length) {
      final feature = parts[libIndex + 1];
      // Skip common non-feature directories
      if (!['src', 'core', 'common', 'utils', 'widgets'].contains(feature)) {
        return '$feature.json';
      }
    }

    return 'core.json';
  }

  /// Flatten nested keys from translations (for plural forms).
  Set<String> _flattenKeys(Map<String, dynamic> translations) {
    final keys = <String>{};

    for (final entry in translations.entries) {
      keys.add(entry.key);
      // Note: We don't recurse into plural form maps,
      // as the key itself is what we match
    }

    return keys;
  }

  /// Extract placeholders from a JSON value.
  Set<String> _extractJsonPlaceholders(dynamic value) {
    final placeholders = <String>{};
    final regex = RegExp(r'\{(\w+)\}');

    if (value is String) {
      for (final match in regex.allMatches(value)) {
        final name = match.group(1);
        if (name != null) {
          placeholders.add(name);
        }
      }
    } else if (value is Map) {
      // Plural forms - check all forms
      for (final formValue in value.values) {
        if (formValue is String) {
          for (final match in regex.allMatches(formValue)) {
            final name = match.group(1);
            if (name != null) {
              placeholders.add(name);
            }
          }
        }
      }
    }

    return placeholders;
  }

  /// Check if two sets are equal.
  bool _setsEqual<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  /// Count JSON files in the reference locale directory.
  Future<int> _countJsonFiles() async {
    final localeDir = Directory(p.join(i18nPath, referenceLocale));
    if (!await localeDir.exists()) return 0;

    var count = 0;
    await for (final entity in localeDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        count++;
      }
    }
    return count;
  }

  void _log(String message) {
    onLog?.call(message);
  }
}
