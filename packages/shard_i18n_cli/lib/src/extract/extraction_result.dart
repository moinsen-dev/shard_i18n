/// Data models for the extract command.
///
/// These models represent the results of scanning source code for i18n usage
/// and comparing with JSON translation files.
library;

/// The type of i18n API call detected in source code.
enum I18nCallType {
  /// `context.t('key')` or `context.t('key', params: {...})`
  contextT,

  /// `context.tn('key', count: n)`
  contextTn,

  /// `'key'.tx` (getter)
  stringTx,

  /// `'key'.t({...})`
  stringT,

  /// `'key'.tn(count: n)`
  stringTn,
}

/// Represents a single extracted i18n key from source code.
class ExtractedKey {
  /// The msgid/key string.
  final String key;

  /// Source file path where this key was found.
  final String filePath;

  /// Line number in the source file.
  final int line;

  /// Column number in the source file.
  final int column;

  /// Type of i18n API call used.
  final I18nCallType callType;

  /// Detected placeholders in the key (e.g., `{name}` -> `name`).
  final Set<String> placeholders;

  /// True if this is a plural call (tn).
  final bool isPlural;

  /// Code snippet for context.
  final String? snippet;

  const ExtractedKey({
    required this.key,
    required this.filePath,
    required this.line,
    required this.column,
    required this.callType,
    this.placeholders = const {},
    this.isPlural = false,
    this.snippet,
  });

  @override
  String toString() => 'ExtractedKey($key at $filePath:$line)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtractedKey &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          filePath == other.filePath &&
          line == other.line;

  @override
  int get hashCode => Object.hash(key, filePath, line);
}

/// Result of scanning source files for i18n keys.
class ExtractionResult {
  /// All extracted keys with their locations.
  final List<ExtractedKey> keys;

  /// Keys grouped by file path.
  final Map<String, List<ExtractedKey>> byFile;

  /// Unique key strings (deduplicated).
  final Set<String> uniqueKeys;

  /// Keys that are used with plural calls (tn).
  final Set<String> pluralKeys;

  /// Placeholders detected for each key.
  final Map<String, Set<String>> placeholdersByKey;

  /// Number of files scanned.
  final int filesScanned;

  /// Duration of the scan operation.
  final Duration scanDuration;

  /// Errors encountered during scanning.
  final List<ScanError> errors;

  const ExtractionResult({
    required this.keys,
    required this.byFile,
    required this.uniqueKeys,
    required this.pluralKeys,
    required this.placeholdersByKey,
    required this.filesScanned,
    required this.scanDuration,
    this.errors = const [],
  });

  /// Create an empty result.
  factory ExtractionResult.empty() => const ExtractionResult(
    keys: [],
    byFile: {},
    uniqueKeys: {},
    pluralKeys: {},
    placeholdersByKey: {},
    filesScanned: 0,
    scanDuration: Duration.zero,
  );
}

/// An error encountered during source file scanning.
class ScanError {
  /// File path where the error occurred.
  final String filePath;

  /// Error message.
  final String message;

  /// Whether this is a warning (non-fatal) or error (fatal).
  final bool isWarning;

  const ScanError({
    required this.filePath,
    required this.message,
    this.isWarning = false,
  });

  @override
  String toString() =>
      '${isWarning ? "Warning" : "Error"} in $filePath: $message';
}

/// Result of comparing code keys against JSON translation files.
class ComparisonResult {
  /// Keys found in code but missing from JSON files.
  final Set<String> missingInJson;

  /// Keys in JSON files but not found in code (orphaned).
  final Set<String> orphanedInJson;

  /// Keys present in both code and JSON.
  final Set<String> matchedKeys;

  /// Placeholder mismatches between code and JSON.
  final Map<String, PlaceholderMismatch> placeholderMismatches;

  /// Issues with plural form definitions.
  final Map<String, PluralFormIssue> pluralIssues;

  /// Summary statistics.
  final Statistics stats;

  const ComparisonResult({
    required this.missingInJson,
    required this.orphanedInJson,
    required this.matchedKeys,
    required this.placeholderMismatches,
    required this.pluralIssues,
    required this.stats,
  });

  /// Returns true if there are any discrepancies.
  bool get hasDiscrepancies =>
      missingInJson.isNotEmpty ||
      orphanedInJson.isNotEmpty ||
      placeholderMismatches.isNotEmpty ||
      pluralIssues.isNotEmpty;
}

/// Mismatch between placeholders in code vs JSON.
class PlaceholderMismatch {
  /// Key with the mismatch.
  final String key;

  /// Placeholders found in code.
  final Set<String> inCode;

  /// Placeholders found in JSON.
  final Set<String> inJson;

  const PlaceholderMismatch({
    required this.key,
    required this.inCode,
    required this.inJson,
  });

  /// Placeholders in code but missing from JSON.
  Set<String> get missingInJson => inCode.difference(inJson);

  /// Placeholders in JSON but not used in code.
  Set<String> get extraInJson => inJson.difference(inCode);

  @override
  String toString() => 'PlaceholderMismatch($key: code=$inCode, json=$inJson)';
}

/// Issue with plural form definition.
class PluralFormIssue {
  /// Key with the issue.
  final String key;

  /// Description of the issue.
  final String message;

  /// Whether the key is used as plural in code but not defined as plural in JSON.
  final bool missingPluralForms;

  /// Available plural forms in JSON (if any).
  final Set<String>? availableForms;

  const PluralFormIssue({
    required this.key,
    required this.message,
    this.missingPluralForms = false,
    this.availableForms,
  });

  @override
  String toString() => 'PluralFormIssue($key: $message)';
}

/// Summary statistics for the comparison.
class Statistics {
  /// Total unique keys found in code.
  final int totalKeysInCode;

  /// Total keys found in JSON files.
  final int totalKeysInJson;

  /// Keys that matched (in both code and JSON).
  final int matchedCount;

  /// Keys missing from JSON.
  final int missingCount;

  /// Keys orphaned in JSON (not in code).
  final int orphanedCount;

  /// Number of files scanned.
  final int filesScanned;

  /// Number of JSON files loaded.
  final int jsonFilesLoaded;

  const Statistics({
    required this.totalKeysInCode,
    required this.totalKeysInJson,
    required this.matchedCount,
    required this.missingCount,
    required this.orphanedCount,
    required this.filesScanned,
    required this.jsonFilesLoaded,
  });

  /// Coverage percentage (matched / total in code).
  double get coveragePercent =>
      totalKeysInCode > 0 ? (matchedCount / totalKeysInCode) * 100 : 100.0;
}

/// Result of an auto-fix operation.
class FixResult {
  /// Files that were modified.
  final List<String> filesModified;

  /// Number of keys added.
  final int keysAdded;

  /// Number of keys removed (pruned).
  final int keysRemoved;

  /// Warnings generated during fix.
  final List<String> warnings;

  /// Whether this was a dry run (no actual changes).
  final bool isDryRun;

  const FixResult({
    required this.filesModified,
    required this.keysAdded,
    required this.keysRemoved,
    this.warnings = const [],
    this.isDryRun = false,
  });

  /// Returns true if any changes were made (or would be made in dry run).
  bool get hasChanges => keysAdded > 0 || keysRemoved > 0;
}
