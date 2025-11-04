import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../models/analysis_result.dart';

/// Analyzes a Flutter project to find translatable strings
class ProjectAnalyzer {
  final bool verbose;

  const ProjectAnalyzer({this.verbose = false});

  /// Analyze a list of Dart files
  Future<AnalysisResult> analyze(List<String> filePaths) async {
    final Map<String, FileAnalysis> fileBreakdown = {};
    int totalStrings = 0;
    int extractableStrings = 0;
    int technicalStrings = 0;
    int ambiguousStrings = 0;
    int interpolationCount = 0;
    int pluralCount = 0;
    double totalConfidence = 0.0;

    for (final filePath in filePaths) {
      _log('Analyzing: $filePath');

      try {
        final content = await File(filePath).readAsString();
        final parseResult =
            parseString(content: content, throwIfDiagnostics: false);

        final visitor = StringDetectorVisitor(filePath);
        parseResult.unit.accept(visitor);

        final detectedStrings = visitor.detectedStrings;

        if (detectedStrings.isNotEmpty) {
          fileBreakdown[filePath] = FileAnalysis(
            filePath: filePath,
            strings: detectedStrings,
          );

          totalStrings += detectedStrings.length;

          for (final str in detectedStrings) {
            totalConfidence += str.confidence;

            switch (str.category) {
              case StringCategory.uiText:
              case StringCategory.likelyUi:
                extractableStrings++;
                break;
              case StringCategory.ambiguous:
                ambiguousStrings++;
                break;
              case StringCategory.technical:
              case StringCategory.debug:
                technicalStrings++;
                break;
            }

            if (str.hasInterpolation) {
              interpolationCount++;
            }

            if (str.isPlural) {
              pluralCount++;
            }
          }
        }
      } catch (e) {
        _log('Error analyzing $filePath: $e');
      }
    }

    return AnalysisResult(
      totalStrings: totalStrings,
      extractableStrings: extractableStrings,
      technicalStrings: technicalStrings,
      ambiguousStrings: ambiguousStrings,
      interpolationCount: interpolationCount,
      pluralCount: pluralCount,
      averageConfidence:
          totalStrings > 0 ? totalConfidence / totalStrings : 0.0,
      filesAnalyzed: filePaths,
      fileBreakdown: fileBreakdown,
    );
  }

  void _log(String message) {
    if (verbose) print('[ProjectAnalyzer] $message');
  }
}

/// AST visitor that detects string literals and classifies them
class StringDetectorVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final List<DetectedString> detectedStrings = [];

  StringDetectorVisitor(this.filePath);

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _processStringLiteral(node);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _processStringLiteral(node);
    // Don't visit children - they're part of this interpolation
    // This prevents child InterpolationString elements from being
    // processed separately, which was causing the plural bug
  }

  void _processStringLiteral(StringLiteral node) {
    final value = _getStringValue(node);
    if (value.isEmpty) {
      return;
    }

    // Get context and classify
    final context = _getContext(node);
    final confidence = _calculateConfidence(node, value, context);
    final category = _categorize(confidence);
    final hasInterpolation = _hasInterpolation(node);
    final isPlural = _isPluralPattern(node);
    final snippet = _getSnippet(node);

    detectedStrings.add(DetectedString(
      value: value,
      line: node.offset, // Simplified; should get line from parse result
      column: node.offset,
      confidence: confidence,
      category: category,
      context: context,
      hasInterpolation: hasInterpolation,
      isPlural: isPlural,
      snippet: snippet,
    ));
  }

  /// Extract the actual string value
  String _getStringValue(StringLiteral node) {
    if (node is SimpleStringLiteral) {
      return node.value;
    } else if (node is StringInterpolation) {
      // For interpolated strings, reconstruct template
      final buffer = StringBuffer();
      for (final element in node.elements) {
        if (element is InterpolationString) {
          buffer.write(element.value);
        } else if (element is InterpolationExpression) {
          // Use placeholder notation
          buffer.write('{${_extractPlaceholderName(element)}}');
        }
      }
      return buffer.toString();
    }
    return '';
  }

  /// Extract placeholder name from interpolation expression
  String _extractPlaceholderName(InterpolationExpression expr) {
    final code = expr.expression.toString();

    // Simple variable: $name → name
    if (expr.expression is SimpleIdentifier) {
      return expr.expression.toString();
    }

    // Property access: user.name → name
    if (code.contains('.')) {
      return code.split('.').last;
    }

    // Complex expression: sanitize
    return code.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  /// Get the context where this string appears
  String _getContext(StringLiteral node) {
    AstNode? parent = node.parent;

    // Walk up the tree to find meaningful context
    while (parent != null) {
      // Check for widget constructors
      if (parent is InstanceCreationExpression) {
        final widgetName = parent.constructorName.type.toString();

        // Check if this is a Text widget
        if (widgetName == 'Text') {
          return 'Text widget';
        }

        // Check for common UI widgets
        if (_isUIWidget(widgetName)) {
          return '$widgetName widget';
        }
      }

      // Check for named arguments (hint, tooltip, label, etc.)
      if (parent is NamedExpression) {
        final paramName = parent.name.label.name;
        if (_isUIParameter(paramName)) {
          return '$paramName parameter';
        }
      }

      // Check for method calls
      if (parent is MethodInvocation) {
        final methodName = parent.methodName.name;
        if (_isDebugMethod(methodName)) {
          return 'debug/$methodName';
        }
      }

      parent = parent.parent;
    }

    return 'unknown';
  }

  /// Calculate confidence score (0-100)
  int _calculateConfidence(StringLiteral node, String value, String context) {
    int score = 50; // Base score

    // Context-based scoring (strongest signal)
    if (context == 'Text widget') {
      score = 95;
    } else if (context.contains('widget')) {
      score = 90;
    } else if (_isUIParameter(context)) {
      score = 90;
    } else if (context.startsWith('debug/')) {
      score = 10;
    }

    // Linguistic analysis
    if (_hasMultipleWords(value)) {
      score += 10;
    }

    if (_startsWithCapital(value)) {
      score += 5;
    }

    if (_containsNaturalLanguage(value)) {
      score += 10;
    }

    // Technical patterns (negative signals)
    if (_isSnakeCase(value)) {
      score -= 30;
    }

    if (_isCamelCase(value)) {
      score -= 25;
    }

    if (_containsUrl(value)) {
      score -= 40;
    }

    if (_isAllUppercase(value) || _isAllLowercase(value)) {
      score -= 20;
    }

    // Clamp to 0-100
    return score.clamp(0, 100);
  }

  StringCategory _categorize(int confidence) {
    if (confidence >= 80) return StringCategory.uiText;
    if (confidence >= 60) return StringCategory.likelyUi;
    if (confidence >= 40) return StringCategory.ambiguous;
    return StringCategory.technical;
  }

  bool _hasInterpolation(StringLiteral node) {
    return node is StringInterpolation;
  }

  bool _isPluralPattern(StringLiteral node) {
    // For StringInterpolation, check CHILDREN for conditional expressions
    if (node is StringInterpolation) {
      for (final element in node.elements) {
        if (element is InterpolationExpression) {
          final expr = element.expression;
          if (expr is ConditionalExpression) {
            final condition = expr.condition.toString();
            if (condition.contains('== 1') ||
                condition.contains('!= 1') ||
                condition.contains('> 1') ||
                condition.contains('<= 1')) {
              return true;
            }
          }
        }
      }
    }

    // Also check parent nodes (for non-interpolated patterns)
    AstNode? parent = node.parent;
    while (parent != null) {
      if (parent is ConditionalExpression) {
        final condition = parent.condition.toString();
        if (condition.contains('== 1') ||
            condition.contains('!= 1') ||
            condition.contains('> 1') ||
            condition.contains('<= 1')) {
          return true;
        }
      }
      parent = parent.parent;
    }

    return false;
  }

  String _getSnippet(StringLiteral node) {
    // Get some context around the string
    return node.parent?.toString() ?? node.toString();
  }

  // Helper methods for classification

  bool _isUIWidget(String name) {
    const uiWidgets = {
      'AppBar',
      'Scaffold',
      'Container',
      'ElevatedButton',
      'TextButton',
      'OutlinedButton',
      'IconButton',
      'FloatingActionButton',
      'TextField',
      'TextFormField',
      'ListTile',
      'Card',
      'Dialog',
      'AlertDialog',
      'SnackBar',
      'Tooltip',
      'Chip',
      'Badge',
    };
    return uiWidgets.contains(name);
  }

  bool _isUIParameter(String name) {
    const uiParams = {
      'title',
      'subtitle',
      'label',
      'hint',
      'hintText',
      'labelText',
      'helperText',
      'errorText',
      'tooltip',
      'semanticLabel',
      'message',
    };
    return uiParams.contains(name);
  }

  bool _isDebugMethod(String name) {
    const debugMethods = {'debugPrint', 'print', 'log'};
    return debugMethods.contains(name);
  }

  bool _hasMultipleWords(String s) => s.trim().contains(' ');

  bool _startsWithCapital(String s) =>
      s.isNotEmpty && s[0] == s[0].toUpperCase();

  bool _containsNaturalLanguage(String s) {
    // Check for common English articles and pronouns
    final words = s.toLowerCase().split(' ');
    const naturalWords = {'the', 'a', 'an', 'you', 'your', 'is', 'are', 'to'};
    return words.any(naturalWords.contains);
  }

  bool _isSnakeCase(String s) => s.contains('_') && !s.contains(' ');

  bool _isCamelCase(String s) {
    if (s.contains(' ') || s.contains('_')) return false;
    return s != s.toLowerCase() && s != s.toUpperCase();
  }

  bool _containsUrl(String s) =>
      s.contains('://') || s.contains('www.') || s.contains('.com');

  bool _isAllUppercase(String s) => s == s.toUpperCase() && s.length > 1;

  bool _isAllLowercase(String s) => s == s.toLowerCase() && s.length > 1;
}
