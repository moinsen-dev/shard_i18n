/// Result of a migration operation
class MigrationResult {
  /// Files that were created during migration
  final List<String> createdFiles;

  /// Files that were modified during migration
  final List<String> modifiedFiles;

  /// Number of strings that were extracted
  final int stringsExtracted;

  /// Number of JSON keys generated
  final int jsonKeysGenerated;

  /// Number of imports added
  final int importsAdded;

  /// Warnings encountered during migration
  final List<MigrationWarning> warnings;

  /// Errors encountered during migration
  final List<MigrationError> errors;

  /// Whether the migration was successful
  final bool success;

  const MigrationResult({
    required this.createdFiles,
    required this.modifiedFiles,
    required this.stringsExtracted,
    required this.jsonKeysGenerated,
    required this.importsAdded,
    required this.warnings,
    required this.errors,
    required this.success,
  });

  /// Create an empty migration result
  factory MigrationResult.empty() {
    return const MigrationResult(
      createdFiles: [],
      modifiedFiles: [],
      stringsExtracted: 0,
      jsonKeysGenerated: 0,
      importsAdded: 0,
      warnings: [],
      errors: [],
      success: true,
    );
  }

  /// Create a failed migration result
  factory MigrationResult.failed(List<MigrationError> errors) {
    return MigrationResult(
      createdFiles: const [],
      modifiedFiles: const [],
      stringsExtracted: 0,
      jsonKeysGenerated: 0,
      importsAdded: 0,
      warnings: const [],
      errors: errors,
      success: false,
    );
  }
}

/// Warning encountered during migration
class MigrationWarning {
  /// Warning message
  final String message;

  /// File where warning occurred
  final String? filePath;

  /// Line number where warning occurred
  final int? line;

  const MigrationWarning({
    required this.message,
    this.filePath,
    this.line,
  });

  @override
  String toString() {
    if (filePath != null && line != null) {
      return '$filePath:$line - $message';
    } else if (filePath != null) {
      return '$filePath - $message';
    }
    return message;
  }
}

/// Error encountered during migration
class MigrationError {
  /// Error message
  final String message;

  /// File where error occurred
  final String? filePath;

  /// Line number where error occurred
  final int? line;

  /// Stack trace if available
  final StackTrace? stackTrace;

  const MigrationError({
    required this.message,
    this.filePath,
    this.line,
    this.stackTrace,
  });

  @override
  String toString() {
    if (filePath != null && line != null) {
      return '$filePath:$line - $message';
    } else if (filePath != null) {
      return '$filePath - $message';
    }
    return message;
  }
}
