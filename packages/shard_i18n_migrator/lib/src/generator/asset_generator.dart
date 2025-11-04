import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';

import '../config/migration_config.dart';
import '../transformer/code_transformer.dart';
import '../models/migration_result.dart';

/// Result of asset generation
class AssetResult {
  final List<String> createdFiles;
  final int jsonKeysGenerated;
  final List<MigrationWarning> warnings;

  const AssetResult({
    required this.createdFiles,
    required this.jsonKeysGenerated,
    required this.warnings,
  });
}

/// Generates translation assets (JSON files)
class AssetGenerator {
  final MigrationConfig config;
  final bool verbose;
  // ignore: unused_field
  late final Logger _logger;

  AssetGenerator({
    required this.config,
    required this.verbose,
  }) {
    _logger = Logger(
      printer: SimplePrinter(colors: false),
      level: verbose ? Level.debug : Level.info,
    );
  }

  /// Generate JSON translation files from extracted strings
  Future<AssetResult> generate(
    TransformResult transformResult, {
    required String projectPath,
    required bool dryRun,
  }) async {
    _log('Generating translation assets');

    final List<String> createdFiles = [];
    final List<MigrationWarning> warnings = [];
    int jsonKeysGenerated = 0;

    // Create base directory
    final i18nDir =
        path.join(projectPath, 'assets', 'i18n', config.sourceLocale);

    if (!dryRun) {
      await Directory(i18nDir).create(recursive: true);
    }

    // Generate JSON file for each feature
    for (final entry in transformResult.extractedStrings.entries) {
      final featureName = entry.key;
      final strings = entry.value;

      if (strings.isEmpty) continue;

      final jsonFile = path.join(i18nDir, '$featureName.json');
      final jsonContent = _generateJson(strings);

      if (dryRun) {
        _log('Would create: $jsonFile (${strings.length} keys)');
      } else {
        await File(jsonFile).writeAsString(jsonContent);
        _log('Created: $jsonFile');
      }

      createdFiles.add(jsonFile);
      jsonKeysGenerated += strings.length;
    }

    return AssetResult(
      createdFiles: createdFiles,
      jsonKeysGenerated: jsonKeysGenerated,
      warnings: warnings,
    );
  }

  String _generateJson(Map<String, dynamic> strings) {
    // Create a formatted JSON object
    // Note: strings can contain either String values (simple strings)
    // or Map<String, String> values (plural structures with "one"/"other" keys)
    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(strings);
  }

  void _log(String message) {
    if (verbose) print('[AssetGenerator] $message');
  }
}
