/// Result of analyzing a project for i18n migration
class AnalysisResult {
  /// Total number of string literals found
  final int totalStrings;

  /// Number of strings classified as extractable UI text
  final int extractableStrings;

  /// Number of strings classified as technical/code strings
  final int technicalStrings;

  /// Number of strings that are ambiguous and require manual review
  final int ambiguousStrings;

  /// Number of interpolation patterns detected ($var, ${expr})
  final int interpolationCount;

  /// Number of plural patterns detected (ternary, if/else with count)
  final int pluralCount;

  /// Average confidence score across all extractable strings (0-100)
  final double averageConfidence;

  /// List of files analyzed
  final List<String> filesAnalyzed;

  /// Detailed string breakdown by file
  final Map<String, FileAnalysis> fileBreakdown;

  const AnalysisResult({
    required this.totalStrings,
    required this.extractableStrings,
    required this.technicalStrings,
    required this.ambiguousStrings,
    required this.interpolationCount,
    required this.pluralCount,
    required this.averageConfidence,
    required this.filesAnalyzed,
    required this.fileBreakdown,
  });

  /// Create an empty analysis result
  factory AnalysisResult.empty() {
    return const AnalysisResult(
      totalStrings: 0,
      extractableStrings: 0,
      technicalStrings: 0,
      ambiguousStrings: 0,
      interpolationCount: 0,
      pluralCount: 0,
      averageConfidence: 0.0,
      filesAnalyzed: [],
      fileBreakdown: {},
    );
  }
}

/// Analysis result for a single file
class FileAnalysis {
  /// Path to the file
  final String filePath;

  /// Strings found in this file
  final List<DetectedString> strings;

  const FileAnalysis({
    required this.filePath,
    required this.strings,
  });
}

/// A detected string literal with metadata
class DetectedString {
  /// The string value
  final String value;

  /// Line number in source file
  final int line;

  /// Column number in source file
  final int column;

  /// Confidence score (0-100) that this is a UI string
  final int confidence;

  /// Classification category
  final StringCategory category;

  /// Context where the string was found (e.g., 'Text widget', 'AppBar title')
  final String context;

  /// Whether this string has interpolation
  final bool hasInterpolation;

  /// Whether this is part of a plural pattern
  final bool isPlural;

  /// Raw code snippet showing usage
  final String snippet;

  const DetectedString({
    required this.value,
    required this.line,
    required this.column,
    required this.confidence,
    required this.category,
    required this.context,
    required this.hasInterpolation,
    required this.isPlural,
    required this.snippet,
  });
}

/// Category classification for strings
enum StringCategory {
  /// High-confidence UI text (e.g., in Text widgets)
  uiText,

  /// Likely UI text based on linguistic analysis
  likelyUi,

  /// Ambiguous - could be UI or technical
  ambiguous,

  /// Technical string (e.g., keys, URLs, paths)
  technical,

  /// Debug/logging strings
  debug,
}
