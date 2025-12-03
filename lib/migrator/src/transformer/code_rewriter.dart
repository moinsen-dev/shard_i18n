import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:logger/logger.dart';

import '../config/migration_config.dart';
import '../models/analysis_result.dart';

/// Represents a code edit to be made
class CodeEdit {
  final int offset;
  final int length;
  final String replacement;

  const CodeEdit({
    required this.offset,
    required this.length,
    required this.replacement,
  });
}

/// Rewrites Dart code to use shard_i18n
class CodeRewriter {
  final MigrationConfig config;
  final bool verbose;
  late final Logger _logger;

  CodeRewriter({required this.config, this.verbose = false}) {
    _logger = Logger(
      printer: SimplePrinter(colors: false),
      level: verbose ? Level.debug : Level.info,
    );
  }

  /// Rewrite a single file
  Future<String?> rewriteFile({
    required String filePath,
    required List<DetectedString> stringsToExtract,
    required bool dryRun,
  }) async {
    if (stringsToExtract.isEmpty) {
      return null;
    }

    _log('Rewriting: $filePath (${stringsToExtract.length} strings)');

    // Read the file
    final content = await File(filePath).readAsString();

    // Parse the file
    final parseResult = parseString(
      content: content,
      throwIfDiagnostics: false,
    );

    // Build the rewriter visitor
    final rewriter = _StringRewriterVisitor(
      stringsToExtract: stringsToExtract,
      config: config,
      verbose: verbose,
    );

    // Visit the AST to collect edits
    parseResult.unit.accept(rewriter);

    // Apply edits in reverse order (to maintain offsets)
    final edits = rewriter.edits..sort((a, b) => b.offset.compareTo(a.offset));

    String modifiedContent = content;
    for (final edit in edits) {
      modifiedContent = modifiedContent.replaceRange(
        edit.offset,
        edit.offset + edit.length,
        edit.replacement,
      );
    }

    // Write back to file
    if (!dryRun) {
      await File(filePath).writeAsString(modifiedContent);
      _log('✓ Rewrote: $filePath');
    } else {
      _log('Would rewrite: $filePath');
    }

    return modifiedContent;
  }

  void _log(String message) {
    _logger.i(message);
  }
}

/// AST visitor that collects code edits for string replacements
class _StringRewriterVisitor extends RecursiveAstVisitor<void> {
  final List<DetectedString> stringsToExtract;
  final MigrationConfig config;
  final bool verbose;
  final List<CodeEdit> edits = [];
  late final Logger _logger;

  _StringRewriterVisitor({
    required this.stringsToExtract,
    required this.config,
    this.verbose = false,
  }) {
    _logger = Logger(
      printer: SimplePrinter(colors: false),
      level: verbose ? Level.debug : Level.info,
    );
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _processStringLiteral(node);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _processStringLiteral(node);
    super.visitStringInterpolation(node);
  }

  void _processStringLiteral(StringLiteral node) {
    // Find if this string should be extracted
    final detectedString = _findMatchingString(node);
    if (detectedString == null) {
      return;
    }

    // Generate the replacement code
    final replacement = _generateReplacement(node, detectedString);
    if (replacement == null) {
      return;
    }

    // Add the edit
    edits.add(
      CodeEdit(
        offset: node.offset,
        length: node.length,
        replacement: replacement,
      ),
    );
  }

  DetectedString? _findMatchingString(StringLiteral node) {
    // Match by offset (most reliable)
    for (final str in stringsToExtract) {
      if (str.line == node.offset) {
        _logger.d('Matched by offset: ${str.value} (plural: ${str.isPlural})');
        return str;
      }
    }

    // Fallback: match by value
    final value = _getStringValue(node);
    for (final str in stringsToExtract) {
      if (str.value == value) {
        _logger.d('Matched by value: ${str.value} (plural: ${str.isPlural})');
        return str;
      }
    }

    if (value.isNotEmpty) {
      _logger.d('No match found for: $value');
    }

    return null;
  }

  String? _generateReplacement(StringLiteral node, DetectedString detected) {
    // Check if this is a plural pattern FIRST (takes priority over interpolation)
    if (detected.isPlural) {
      _logger.d('Detected plural pattern: ${detected.value}');
      final pluralReplacement = _generatePluralReplacement(node, detected);
      if (pluralReplacement != null) {
        _logger.d('Generated plural replacement: $pluralReplacement');
        return pluralReplacement;
      } else {
        _logger.d('Plural replacement failed, falling back');
      }
      // If plural replacement failed, fall through to interpolation/simple
    }

    // Check if this has interpolation
    if (detected.hasInterpolation && node is StringInterpolation) {
      return _generateInterpolatedReplacement(node, detected);
    }

    // Simple string replacement
    return _generateSimpleReplacement(node, detected);
  }

  String _generateSimpleReplacement(
    StringLiteral node,
    DetectedString detected,
  ) {
    // Generate key
    final key = _generateKey(detected.value);

    // Simple case: context.t('key')
    return "context.t('$key')";
  }

  String _generateInterpolatedReplacement(
    StringInterpolation node,
    DetectedString detected,
  ) {
    // Extract interpolation expressions and build params map
    final params = <String, String>{};
    final templateParts = <String>[];

    for (final element in node.elements) {
      if (element is InterpolationString) {
        templateParts.add(element.value);
      } else if (element is InterpolationExpression) {
        final placeholder = _extractPlaceholderName(element);
        final expression = element.expression.toString();

        templateParts.add('{$placeholder}');
        params[placeholder] = expression;
      }
    }

    final template = templateParts.join('');
    final key = _generateKey(template);

    // Build params map string
    if (params.isEmpty) {
      return "context.t('$key')";
    }

    final paramsStr = params.entries
        .map((e) => "'${e.key}': ${e.value}")
        .join(', ');

    return "context.t('$key', params: {$paramsStr})";
  }

  String? _generatePluralReplacement(
    StringLiteral node,
    DetectedString detected,
  ) {
    // For plural patterns, we need to analyze the string interpolation
    // Pattern: '$count item${count == 1 ? '' : 's'}'
    // We need to extract: count variable, singular suffix, plural suffix

    if (node is! StringInterpolation) {
      return null; // Plural patterns must have interpolation
    }

    String? countVar;
    // ignore: unused_local_variable
    String? singularSuffix;
    // ignore: unused_local_variable
    String? pluralSuffix;
    final baseParts = <String>[];

    // Analyze interpolation elements
    for (final element in node.elements) {
      if (element is InterpolationString) {
        baseParts.add(element.value);
      } else if (element is InterpolationExpression) {
        final expr = element.expression;

        // Check if this is a conditional expression (the plural part)
        if (expr is ConditionalExpression) {
          final condition = expr.condition.toString();

          // Extract count variable: "count == 1" or "count != 1"
          final match = RegExp(r'(\w+)\s*[=!]=\s*1').firstMatch(condition);
          if (match != null) {
            countVar = match.group(1);

            // Extract singular and plural forms
            final thenExpr = expr.thenExpression.toString();
            final elseExpr = expr.elseExpression.toString();

            // Remove quotes if present
            singularSuffix = thenExpr.replaceAll("'", '').replaceAll('"', '');
            pluralSuffix = elseExpr.replaceAll("'", '').replaceAll('"', '');
          }
        } else if (countVar == null) {
          // This might be the count variable itself
          final exprStr = expr.toString();
          if (!exprStr.contains('==') && !exprStr.contains('!=')) {
            countVar = exprStr;
            baseParts.add('{count}');
          }
        }
      }
    }

    if (countVar == null) {
      return null; // Can't determine count variable
    }

    // Build singular and plural forms
    final base = baseParts.join('');
    // TODO: Use these for proper JSON generation
    // final singular = base + (singularSuffix ?? '');
    // final plural = base + (pluralSuffix ?? '');

    // Generate a key for the plural
    final key = _generatePluralKey(base);

    return "context.tn('$key', count: $countVar)";
  }

  String _generateKey(String value) {
    if (config.keyStrategy == 'msgid') {
      // Use the string itself as the key (escape single quotes)
      return value.replaceAll("'", "\\'");
    } else {
      // Generate a stable ID
      return _generateStableId(value);
    }
  }

  String _generatePluralKey(String value) {
    // For plurals, generate a semantic key
    // e.g., "item" or "file_count" based on the string content
    final cleaned = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return '${cleaned}_count';
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

  String _extractPlaceholderName(InterpolationExpression expr) {
    final code = expr.expression.toString();

    // Simple variable: name
    if (expr.expression is SimpleIdentifier) {
      return code;
    }

    // Property access: user.name → name
    if (code.contains('.')) {
      return code.split('.').last;
    }

    // Complex expression: sanitize
    return code.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  String _getStringValue(StringLiteral node) {
    if (node is SimpleStringLiteral) {
      return node.value;
    } else if (node is StringInterpolation) {
      final buffer = StringBuffer();
      for (final element in node.elements) {
        if (element is InterpolationString) {
          buffer.write(element.value);
        } else if (element is InterpolationExpression) {
          buffer.write('{${_extractPlaceholderName(element)}}');
        }
      }
      return buffer.toString();
    }
    return '';
  }
}
