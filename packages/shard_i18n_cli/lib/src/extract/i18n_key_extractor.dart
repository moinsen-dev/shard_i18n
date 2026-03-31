/// AST visitor for extracting i18n keys from Dart source files.
///
/// Detects all shard_i18n API usage patterns:
/// - `context.t('key')` / `context.t('key', params: {...})`
/// - `context.tn('key', count: n)`
/// - `'key'.tx` (getter)
/// - `'key'.t({...})` / `'key'.tn(count: n)`
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import 'extraction_result.dart';

/// Extracts i18n keys from Dart source files.
class I18nKeyExtractor {
  /// Whether to print verbose output.
  final bool verbose;

  /// Callback for logging messages.
  final void Function(String message)? onLog;

  I18nKeyExtractor({this.verbose = false, this.onLog});

  /// Extract i18n keys from a list of file paths.
  Future<ExtractionResult> extract(List<String> filePaths) async {
    final stopwatch = Stopwatch()..start();
    final allKeys = <ExtractedKey>[];
    final byFile = <String, List<ExtractedKey>>{};
    final errors = <ScanError>[];

    for (final filePath in filePaths) {
      try {
        final keys = await extractFromFile(filePath);
        if (keys.isNotEmpty) {
          allKeys.addAll(keys);
          byFile[filePath] = keys;
          _log('Found ${keys.length} key(s) in $filePath');
        }
      } catch (e) {
        errors.add(
          ScanError(filePath: filePath, message: e.toString(), isWarning: true),
        );
        _log('Warning: Could not parse $filePath: $e');
      }
    }

    stopwatch.stop();

    // Build unique keys and categorize
    final uniqueKeys = <String>{};
    final pluralKeys = <String>{};
    final placeholdersByKey = <String, Set<String>>{};

    for (final key in allKeys) {
      uniqueKeys.add(key.key);
      if (key.isPlural) {
        pluralKeys.add(key.key);
      }
      if (key.placeholders.isNotEmpty) {
        placeholdersByKey
            .putIfAbsent(key.key, () => {})
            .addAll(key.placeholders);
      }
    }

    return ExtractionResult(
      keys: allKeys,
      byFile: byFile,
      uniqueKeys: uniqueKeys,
      pluralKeys: pluralKeys,
      placeholdersByKey: placeholdersByKey,
      filesScanned: filePaths.length,
      scanDuration: stopwatch.elapsed,
      errors: errors,
    );
  }

  /// Extract i18n keys from a single file.
  Future<List<ExtractedKey>> extractFromFile(String filePath) async {
    final content = await File(filePath).readAsString();
    final parseResult = parseString(
      content: content,
      throwIfDiagnostics: false,
    );

    final visitor = _I18nKeyExtractorVisitor(
      filePath: filePath,
      lineInfo: parseResult.lineInfo,
    );
    parseResult.unit.accept(visitor);

    return visitor.extractedKeys;
  }

  void _log(String message) {
    if (verbose) {
      onLog?.call(message);
    }
  }
}

/// AST visitor that detects i18n API usage patterns.
class _I18nKeyExtractorVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final LineInfo lineInfo;
  final List<ExtractedKey> extractedKeys = [];

  _I18nKeyExtractorVisitor({required this.filePath, required this.lineInfo});

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Check for context.t() / context.tn() patterns
    _checkContextMethod(node);

    // Check for 'key'.t() / 'key'.tn() string extension patterns
    _checkStringExtensionMethod(node);

    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // Check for 'key'.tx getter pattern
    _checkTxProperty(node);
    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Also check for prefixed identifier form of .tx
    _checkPrefixedTx(node);
    super.visitPrefixedIdentifier(node);
  }

  /// Check for context.t('key') or context.tn('key', count: n) patterns.
  void _checkContextMethod(MethodInvocation node) {
    final target = node.target;
    if (target == null) return;

    // Check if target ends with 'context' (e.g., context, buildContext)
    final targetName = target.toString().toLowerCase();
    if (!targetName.endsWith('context')) return;

    final methodName = node.methodName.name;
    if (methodName != 't' && methodName != 'tn') return;

    // Get the first positional argument (the key)
    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final firstArg = args.first;
    final key = _extractStringValue(firstArg);
    if (key == null) return;

    final isPlural = methodName == 'tn';
    final location = lineInfo.getLocation(node.offset);

    extractedKeys.add(
      ExtractedKey(
        key: key,
        filePath: filePath,
        line: location.lineNumber,
        column: location.columnNumber,
        callType: isPlural ? I18nCallType.contextTn : I18nCallType.contextT,
        placeholders: _extractPlaceholders(key),
        isPlural: isPlural,
        snippet: _getSnippet(node),
      ),
    );
  }

  /// Check for 'key'.t({...}) or 'key'.tn(count: n) string extension patterns.
  void _checkStringExtensionMethod(MethodInvocation node) {
    final target = node.realTarget;
    if (target == null) return;

    // Target must be a string literal
    final key = _extractStringValue(target);
    if (key == null) return;

    final methodName = node.methodName.name;
    if (methodName != 't' && methodName != 'tn') return;

    final isPlural = methodName == 'tn';
    final location = lineInfo.getLocation(node.offset);

    extractedKeys.add(
      ExtractedKey(
        key: key,
        filePath: filePath,
        line: location.lineNumber,
        column: location.columnNumber,
        callType: isPlural ? I18nCallType.stringTn : I18nCallType.stringT,
        placeholders: _extractPlaceholders(key),
        isPlural: isPlural,
        snippet: _getSnippet(node),
      ),
    );
  }

  /// Check for 'key'.tx getter pattern via PropertyAccess.
  void _checkTxProperty(PropertyAccess node) {
    if (node.propertyName.name != 'tx') return;

    final target = node.target;
    if (target == null) return;

    final key = _extractStringValue(target);
    if (key == null) return;

    final location = lineInfo.getLocation(node.offset);

    extractedKeys.add(
      ExtractedKey(
        key: key,
        filePath: filePath,
        line: location.lineNumber,
        column: location.columnNumber,
        callType: I18nCallType.stringTx,
        placeholders: _extractPlaceholders(key),
        isPlural: false,
        snippet: _getSnippet(node),
      ),
    );
  }

  /// Check for prefixed identifier form of .tx.
  void _checkPrefixedTx(PrefixedIdentifier node) {
    if (node.identifier.name != 'tx') return;

    final prefix = node.prefix;
    // This handles cases like variable.tx but we only want string.tx
    // In practice, PrefixedIdentifier won't match 'string'.tx,
    // that goes through PropertyAccess. But keep for completeness.
    final key = _extractStringValue(prefix);
    if (key == null) return;

    final location = lineInfo.getLocation(node.offset);

    extractedKeys.add(
      ExtractedKey(
        key: key,
        filePath: filePath,
        line: location.lineNumber,
        column: location.columnNumber,
        callType: I18nCallType.stringTx,
        placeholders: _extractPlaceholders(key),
        isPlural: false,
        snippet: _getSnippet(node),
      ),
    );
  }

  /// Extract string value from an expression.
  /// Returns null if the expression is not a string literal.
  String? _extractStringValue(Expression expr) {
    if (expr is SimpleStringLiteral) {
      return expr.value;
    } else if (expr is AdjacentStrings) {
      // Handle adjacent strings like 'Hello ' 'World'
      final buffer = StringBuffer();
      for (final string in expr.strings) {
        if (string is SimpleStringLiteral) {
          buffer.write(string.value);
        } else {
          // Contains interpolation, skip
          return null;
        }
      }
      return buffer.toString();
    } else if (expr is StringInterpolation) {
      // For interpolated strings, we can't reliably extract the key
      // since it depends on runtime values
      return null;
    }
    return null;
  }

  /// Extract placeholders from a key string.
  /// Placeholders are in the format {name}.
  Set<String> _extractPlaceholders(String key) {
    final placeholders = <String>{};
    final regex = RegExp(r'\{(\w+)\}');

    for (final match in regex.allMatches(key)) {
      final name = match.group(1);
      if (name != null) {
        placeholders.add(name);
      }
    }

    return placeholders;
  }

  /// Get a code snippet for context.
  String _getSnippet(AstNode node) {
    // Return the node's source representation, truncated if too long
    final source = node.toString();
    if (source.length > 80) {
      return '${source.substring(0, 77)}...';
    }
    return source;
  }
}

/// Find all Dart files in a directory (recursively).
Future<List<String>> findDartFiles(String path, {List<String>? exclude}) async {
  final dir = Directory(path);
  final files = <String>[];
  final excludePatterns = exclude ?? [];

  if (!await dir.exists()) {
    return files;
  }

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // Check exclude patterns
      final relativePath = entity.path;
      final shouldExclude = excludePatterns.any((pattern) {
        if (pattern.contains('*')) {
          // Simple glob matching
          final regexPattern = pattern
              .replaceAll('.', r'\.')
              .replaceAll('*', '.*');
          return RegExp(regexPattern).hasMatch(relativePath);
        }
        return relativePath.contains(pattern);
      });

      if (!shouldExclude) {
        files.add(entity.path);
      }
    }
  }

  return files;
}
