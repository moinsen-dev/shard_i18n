import 'package:interact/interact.dart' as interact;

import '../config/migration_config.dart';
import '../models/analysis_result.dart';

/// Handles interactive prompting for ambiguous strings
class UserPrompter {
  final MigrationConfig config;
  final Set<String> _skipPatterns = {};

  UserPrompter({required this.config});

  /// Ask user if a string should be extracted
  bool shouldExtractString(DetectedString detectedString) {
    // Check if user already said to skip similar patterns
    if (_skipPatterns.contains(detectedString.context)) {
      return false;
    }

    // Show information about the string
    print('');
    print('Found: "${detectedString.value}"');
    print('Context: ${detectedString.context}');
    print('Confidence: ${detectedString.confidence}%');
    print('Snippet: ${_truncate(detectedString.snippet, 60)}');
    print('');

    // Create prompt
    final choice = interact.Select(
      prompt: 'Extract this string?',
      options: ['Yes', 'No', 'Skip all similar'],
    ).interact();

    switch (choice) {
      case 0: // Yes
        return true;
      case 1: // No
        return false;
      case 2: // Skip all similar
        _skipPatterns.add(detectedString.context);
        return false;
      default:
        return false;
    }
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
}
