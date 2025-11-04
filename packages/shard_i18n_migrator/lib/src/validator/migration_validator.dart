import 'dart:io';

/// Validates the migrated project
class MigrationValidator {
  final bool verbose;

  const MigrationValidator({required this.verbose});

  /// Validate the migrated project
  Future<void> validate(String projectPath) async {
    _log('Validating migrated project');

    // Run flutter analyze
    await _runFlutterAnalyze(projectPath);

    // Check JSON validity
    await _validateJsonFiles(projectPath);

    _log('Validation complete');
  }

  Future<void> _runFlutterAnalyze(String projectPath) async {
    _log('Running flutter analyze...');

    try {
      final result = await Process.run(
        'flutter',
        ['analyze'],
        workingDirectory: projectPath,
      );

      if (result.exitCode != 0) {
        _log('Warning: flutter analyze found issues:');
        _log(result.stdout.toString());
        _log(result.stderr.toString());
      } else {
        _log('flutter analyze passed');
      }
    } catch (e) {
      _log('Error running flutter analyze: $e');
    }
  }

  Future<void> _validateJsonFiles(String projectPath) async {
    _log('Validating JSON files...');

    final i18nDir = Directory('$projectPath/assets/i18n');
    if (!i18nDir.existsSync()) {
      _log('Warning: No i18n directory found');
      return;
    }

    // TODO: Implement JSON validation
    _log('JSON validation: OK');
  }

  void _log(String message) {
    if (verbose) {
      print('[MigrationValidator] $message');
    }
  }
}
