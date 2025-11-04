import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:logger/logger.dart';

/// Manages imports in Dart files
class ImportManager {
  final bool verbose;
  late final Logger _logger;

  ImportManager({required this.verbose}) {
    _logger = Logger(
      printer: SimplePrinter(colors: false),
      level: verbose ? Level.debug : Level.info,
    );
  }

  /// Add shard_i18n import to a file if not already present
  Future<bool> addShardI18nImport({
    required String filePath,
    required bool dryRun,
  }) async {
    final content = await File(filePath).readAsString();
    final parseResult =
        parseString(content: content, throwIfDiagnostics: false);

    // Check if import already exists
    final hasImport = parseResult.unit.directives
        .whereType<ImportDirective>()
        .any((d) => d.uri.stringValue == 'package:shard_i18n/shard_i18n.dart');

    if (hasImport) {
      _log('Import already exists in: $filePath');
      return false;
    }

    // Find the insertion point
    final insertionPoint = _findImportInsertionPoint(parseResult.unit);

    // Build the import statement
    const importStatement = "\nimport 'package:shard_i18n/shard_i18n.dart';";

    // Insert the import
    final modifiedContent = content.substring(0, insertionPoint) +
        importStatement +
        content.substring(insertionPoint);

    // Write back
    if (!dryRun) {
      await File(filePath).writeAsString(modifiedContent);
      _log('✓ Added import to: $filePath');
    } else {
      _log('Would add import to: $filePath');
    }

    return true;
  }

  /// Find the best position to insert the import
  int _findImportInsertionPoint(CompilationUnit unit) {
    final directives = unit.directives;

    if (directives.isEmpty) {
      // No directives, insert at beginning
      return 0;
    }

    // Find the last import directive
    ImportDirective? lastImport;
    for (final directive in directives) {
      if (directive is ImportDirective) {
        lastImport = directive;
      }
    }

    if (lastImport != null) {
      // Insert after the last import
      return lastImport.end;
    }

    // No imports, but there might be library/part directives
    // Insert before the first non-import directive
    return directives.first.offset;
  }

  void _log(String message) {
    _logger.i(message);
  }
}
