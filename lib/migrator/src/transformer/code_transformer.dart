import 'package:logger/logger.dart';

import '../config/migration_config.dart';
import '../models/analysis_result.dart';
import '../models/migration_result.dart';
import 'code_rewriter.dart';
import 'import_manager.dart';
import '../interactive/user_prompter.dart';

/// Result of code transformation
class TransformResult {
  final List<String> modifiedFiles;
  final int stringsExtracted;
  final int importsAdded;
  final List<MigrationWarning> warnings;
  final Map<String, Map<String, dynamic>>
      extractedStrings; // feature -> key -> value (String or Map for plurals)

  const TransformResult({
    required this.modifiedFiles,
    required this.stringsExtracted,
    required this.importsAdded,
    required this.warnings,
    required this.extractedStrings,
  });
}

/// Transforms Dart code to use shard_i18n
class CodeTransformer {
  final MigrationConfig config;
  final bool interactive;
  final bool verbose;

  late final CodeRewriter _rewriter;
  late final ImportManager _importManager;
  late final UserPrompter? _prompter;
  late final Logger _logger;

  CodeTransformer({
    required this.config,
    required this.interactive,
    required this.verbose,
  }) {
    _rewriter = CodeRewriter(config: config, verbose: verbose);
    _importManager = ImportManager(verbose: verbose);
    _prompter = interactive ? UserPrompter(config: config) : null;
    _logger = Logger(
      printer: SimplePrinter(colors: false),
      level: verbose ? Level.debug : Level.info,
    );
  }

  /// Transform analyzed files to use shard_i18n
  Future<TransformResult> transform(
    AnalysisResult analysis, {
    required bool dryRun,
  }) async {
    _log('Transforming ${analysis.filesAnalyzed.length} files');

    final List<String> modifiedFiles = [];
    final List<MigrationWarning> warnings = [];
    final Map<String, Map<String, dynamic>> extractedStrings = {};
    int stringsExtracted = 0;
    int importsAdded = 0;

    // For each file with detected strings
    for (final entry in analysis.fileBreakdown.entries) {
      final filePath = entry.key;
      final fileAnalysis = entry.value;

      _log('Processing: $filePath');

      // Determine which strings to extract
      final stringsToExtract = <DetectedString>[];

      for (final str in fileAnalysis.strings) {
        // Auto-extract high-confidence strings
        if (str.confidence >= config.autoExtractThreshold) {
          stringsToExtract.add(str);
        }
        // Prompt for ambiguous strings in interactive mode
        else if (interactive && str.category == StringCategory.ambiguous) {
          if (_prompter?.shouldExtractString(str) ?? false) {
            stringsToExtract.add(str);
          }
        }
      }

      if (stringsToExtract.isEmpty) {
        continue;
      }

      // Determine feature name from file path
      final featureName = _determineFeature(filePath);

      // Initialize feature map if needed
      extractedStrings[featureName] ??= {};

      // Extract strings and collect keys for JSON
      for (final str in stringsToExtract) {
        // For plural strings, generate JSON plural structure
        if (str.isPlural) {
          final pluralKey = _generatePluralKey(str.value);
          final pluralForms = _extractPluralForms(str.value, pluralKey);
          extractedStrings[featureName]![pluralKey] = pluralForms;
        } else {
          final key = _generateKey(str.value);
          extractedStrings[featureName]![key] = str.value;
        }
      }

      // Rewrite the file
      final rewritten = await _rewriter.rewriteFile(
        filePath: filePath,
        stringsToExtract: stringsToExtract,
        dryRun: dryRun,
      );

      if (rewritten != null) {
        modifiedFiles.add(filePath);
        stringsExtracted += stringsToExtract.length;

        // Add import
        final importAdded = await _importManager.addShardI18nImport(
          filePath: filePath,
          dryRun: dryRun,
        );

        if (importAdded) {
          importsAdded++;
        }
      }
    }

    return TransformResult(
      modifiedFiles: modifiedFiles,
      stringsExtracted: stringsExtracted,
      importsAdded: importsAdded,
      warnings: warnings,
      extractedStrings: extractedStrings,
    );
  }

  String _determineFeature(String filePath) {
    // Check config mappings first
    for (final entry in config.featureMappings.entries) {
      if (filePath.contains(entry.key)) {
        return entry.value.replaceAll('.json', '');
      }
    }

    // Extract from path: lib/pages/auth/login.dart → auth
    if (filePath.contains('/pages/')) {
      final parts = filePath.split('/pages/');
      if (parts.length > 1) {
        final subParts = parts[1].split('/');
        if (subParts.isNotEmpty) {
          return subParts.first;
        }
      }
    }

    // Default to core
    return 'core';
  }

  String _generateKey(String value) {
    if (config.keyStrategy == 'msgid') {
      // Use the string itself as the key
      return value;
    } else {
      // Generate a stable ID
      return _generateStableId(value);
    }
  }

  String _generatePluralKey(String value) {
    // Generate a semantic key for plurals
    // e.g., "{count} item" or "{itemCount} item{itemCount__...}" -> "count_item_count"
    // This should match the logic in CodeRewriter._generatePluralKey

    // Extract the clean base part (before the conditional placeholder)
    // Pattern: "{var} text{var____...}" -> "{var} text"
    String cleanValue = value;

    // Find placeholders that contain conditional patterns (with multiple underscores or numbers)
    // and remove them along with everything after
    final match = RegExp(r'\{[^}]*__[^}]*\}').firstMatch(cleanValue);
    if (match != null) {
      // Remove the conditional placeholder and everything after it
      cleanValue = cleanValue.substring(0, match.start);
    }

    // Normalize the placeholder name to "count" (to match CodeRewriter logic)
    // Replace any placeholder like {itemCount}, {n}, {num} with {count}
    cleanValue = cleanValue.replaceAll(RegExp(r'\{[^}]+\}'), '{count}');

    final cleaned = cleanValue
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'),
            '_') // Convert all non-alphanumeric to underscore
        .replaceAll(RegExp(r'_+'), '_') // Replace multiple underscores with one
        .replaceAll(
            RegExp(r'^_|_$'), ''); // Remove leading/trailing underscores

    return '${cleaned}_count';
  }

  Map<String, String> _extractPluralForms(String value, String pluralKey) {
    // Extract the base word from the plural key
    // e.g., "count_item_count" -> "item"
    String baseWord =
        pluralKey.replaceAll('_count', '').replaceAll('count_', '');

    // If the base word is empty or just underscores, use a fallback
    if (baseWord.isEmpty || baseWord.replaceAll('_', '').isEmpty) {
      baseWord = 'item';
    }

    // Generate singular and plural forms
    // This is a simple heuristic - works for most English cases
    final singular = '{count} $baseWord';
    final plural = '{count} ${baseWord}s';

    return {
      'one': singular,
      'other': plural,
    };
  }

  String _generateStableId(String value) {
    // Generate a stable identifier from the string
    final cleaned = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    // Limit length
    if (cleaned.length > 50) {
      return cleaned.substring(0, 50);
    }

    return cleaned;
  }

  void _log(String message) {
    _logger.i(message);
  }
}
