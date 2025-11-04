import 'dart:io';
import 'package:glob/glob.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

import 'config/migration_config.dart';
import 'models/analysis_result.dart';
import 'models/migration_result.dart';
import 'analyzer/project_analyzer.dart';
import 'transformer/code_transformer.dart';
import 'generator/asset_generator.dart';
import 'generator/bootstrap_generator.dart';
import 'validator/migration_validator.dart';

/// Main orchestrator for Flutter app i18n migration
class ShardI18nMigrator {
  final bool verbose;
  late final Logger _logger;

  ShardI18nMigrator({this.verbose = false}) {
    _logger = Logger(
      printer: SimplePrinter(colors: false),
      level: verbose ? Level.debug : Level.info,
    );
  }

  /// Analyze a project for migration without making changes
  Future<AnalysisResult> analyze(String projectPath) async {
    _log('Starting analysis of: $projectPath');

    // Find all Dart files
    final dartFiles = await _findDartFiles(projectPath);
    _log('Found ${dartFiles.length} Dart files');

    // Analyze each file
    final analyzer = ProjectAnalyzer(verbose: verbose);
    final result = await analyzer.analyze(dartFiles);

    _log('Analysis complete');
    return result;
  }

  /// Migrate a project to use shard_i18n
  Future<MigrationResult> migrate(
    String projectPath, {
    MigrationConfig? config,
    bool dryRun = false,
    bool interactive = true,
  }) async {
    _log('Starting migration of: $projectPath');
    _log('Mode: ${interactive ? "Interactive" : "Automatic"}');
    _log('Dry run: ${dryRun ? "Yes" : "No"}');

    config ??= MigrationConfig.createDefault();

    try {
      // Step 1: Analyze the project
      _log('Step 1: Analyzing project...');
      final dartFiles =
          await _findDartFiles(projectPath, config.excludePatterns);
      final analyzer = ProjectAnalyzer(verbose: verbose);
      final analysis = await analyzer.analyze(dartFiles);

      // Step 2: Transform code
      _log('Step 2: Transforming code...');
      final transformer = CodeTransformer(
        config: config,
        interactive: interactive,
        verbose: verbose,
      );
      final transformResult = await transformer.transform(
        analysis,
        dryRun: dryRun,
      );

      // Step 3: Generate assets
      _log('Step 3: Generating translation assets...');
      final assetGenerator = AssetGenerator(
        config: config,
        verbose: verbose,
      );
      final assetResult = await assetGenerator.generate(
        transformResult,
        projectPath: projectPath,
        dryRun: dryRun,
      );

      // Step 4: Generate bootstrap code
      _log('Step 4: Setting up bootstrap code...');
      final bootstrapGenerator = BootstrapGenerator(
        config: config,
        verbose: verbose,
      );
      await bootstrapGenerator.generate(
        projectPath: projectPath,
        dryRun: dryRun,
      );

      // Step 5: Validate (if not dry run)
      if (!dryRun) {
        _log('Step 5: Validating migration...');
        final validator = MigrationValidator(verbose: verbose);
        await validator.validate(projectPath);
      }

      _log('Migration ${dryRun ? "preview" : "completed"} successfully');

      return MigrationResult(
        createdFiles:
            assetResult.createdFiles + bootstrapGenerator.createdFiles,
        modifiedFiles:
            transformResult.modifiedFiles + bootstrapGenerator.modifiedFiles,
        stringsExtracted: transformResult.stringsExtracted,
        jsonKeysGenerated: assetResult.jsonKeysGenerated,
        importsAdded: transformResult.importsAdded,
        warnings: transformResult.warnings + assetResult.warnings,
        errors: [],
        success: true,
      );
    } catch (e, stack) {
      return MigrationResult.failed([
        MigrationError(
          message: e.toString(),
          stackTrace: stack,
        ),
      ]);
    }
  }

  /// Find all Dart files in a directory
  Future<List<String>> _findDartFiles(
    String dirPath, [
    List<String> excludePatterns = const [],
  ]) async {
    final files = <String>[];
    final dir = Directory(dirPath);

    if (!dir.existsSync()) {
      return files;
    }

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = path.relative(entity.path, from: dirPath);

        // Check if file matches any exclude pattern
        bool excluded = false;
        for (final pattern in excludePatterns) {
          if (Glob(pattern).matches(relativePath)) {
            excluded = true;
            break;
          }
        }

        if (!excluded) {
          files.add(entity.path);
        }
      }
    }

    return files;
  }

  void _log(String message) {
    _logger.i(message);
  }
}
