/// Output formatters for the extract command.
///
/// Supports three output formats:
/// - Text: Human-readable console output
/// - JSON: Machine-readable for CI integration
/// - Diff: Git-style +/- format
library;

import 'dart:convert';
import 'dart:io';

import 'extraction_result.dart';

/// Output format for the extract command.
enum OutputFormat {
  /// Human-readable text output.
  text,

  /// Machine-readable JSON output.
  json,

  /// Git-style diff output.
  diff,
}

/// Base class for extract reporters.
abstract class ExtractReporter {
  /// Generate output for the given comparison result.
  String format(
    ComparisonResult result,
    ExtractionResult extracted, {
    bool verbose = false,
  });

  /// Print output to stdout.
  void report(
    ComparisonResult result,
    ExtractionResult extracted, {
    bool verbose = false,
  }) {
    stdout.write(format(result, extracted, verbose: verbose));
  }

  /// Create a reporter for the given format.
  factory ExtractReporter.forFormat(OutputFormat format) {
    switch (format) {
      case OutputFormat.text:
        return TextReporter();
      case OutputFormat.json:
        return JsonReporter();
      case OutputFormat.diff:
        return DiffReporter();
    }
  }
}

/// Human-readable text output reporter.
class TextReporter implements ExtractReporter {
  @override
  String format(
    ComparisonResult result,
    ExtractionResult extracted, {
    bool verbose = false,
  }) {
    final buffer = StringBuffer();
    final stats = result.stats;

    // Header
    buffer.writeln('shard_i18n extract - Key Analysis Report');
    buffer.writeln('=' * 44);
    buffer.writeln();

    // Statistics
    buffer.writeln('Statistics:');
    buffer.writeln('  Files scanned:     ${stats.filesScanned}');
    buffer.writeln('  JSON files:        ${stats.jsonFilesLoaded}');
    buffer.writeln('  Keys in code:      ${stats.totalKeysInCode}');
    buffer.writeln('  Keys in JSON:      ${stats.totalKeysInJson}');
    buffer.writeln(
        '  Matched:           ${stats.matchedCount} (${stats.coveragePercent.toStringAsFixed(1)}%)');
    buffer.writeln('  Missing in JSON:   ${stats.missingCount}');
    buffer.writeln('  Orphaned in JSON:  ${stats.orphanedCount}');
    buffer.writeln();

    // Missing keys
    if (result.missingInJson.isNotEmpty) {
      buffer.writeln('Missing Keys (in code, not in JSON):');
      buffer.writeln('-' * 40);

      final sortedMissing = result.missingInJson.toList()..sort();
      for (final key in sortedMissing) {
        buffer.writeln('  + $key');

        // Find locations for this key
        final locations = extracted.keys.where((k) => k.key == key);
        for (final loc in locations.take(verbose ? 10 : 2)) {
          buffer.writeln('      ${loc.filePath}:${loc.line}');
          if (loc.snippet != null) {
            buffer.writeln('      ${loc.snippet}');
          }
        }
        if (!verbose && locations.length > 2) {
          buffer.writeln('      ... and ${locations.length - 2} more');
        }
        buffer.writeln();
      }
    }

    // Orphaned keys
    if (result.orphanedInJson.isNotEmpty) {
      buffer.writeln('Orphaned Keys (in JSON, not in code):');
      buffer.writeln('-' * 40);

      final sortedOrphaned = result.orphanedInJson.toList()..sort();
      for (final key in sortedOrphaned) {
        buffer.writeln('  - $key');
      }
      buffer.writeln();
    }

    // Placeholder mismatches
    if (result.placeholderMismatches.isNotEmpty) {
      buffer.writeln('Placeholder Mismatches:');
      buffer.writeln('-' * 40);

      for (final mismatch in result.placeholderMismatches.values) {
        buffer.writeln('  ~ ${mismatch.key}');
        buffer.writeln('      Code: {${mismatch.inCode.join('}, {')}}');
        buffer.writeln('      JSON: {${mismatch.inJson.join('}, {')}}');
        buffer.writeln();
      }
    }

    // Plural form issues
    if (result.pluralIssues.isNotEmpty) {
      buffer.writeln('Plural Form Issues:');
      buffer.writeln('-' * 40);

      for (final issue in result.pluralIssues.values) {
        buffer.writeln('  ! ${issue.key}');
        buffer.writeln('      ${issue.message}');
        if (issue.availableForms != null) {
          buffer.writeln('      Available forms: ${issue.availableForms}');
        }
        buffer.writeln();
      }
    }

    // Verbose: per-file breakdown
    if (verbose && extracted.byFile.isNotEmpty) {
      buffer.writeln('Per-File Breakdown:');
      buffer.writeln('-' * 40);

      final sortedFiles = extracted.byFile.keys.toList()..sort();
      for (final file in sortedFiles) {
        final keys = extracted.byFile[file]!;
        buffer.writeln('  $file (${keys.length} keys)');
        for (final key in keys) {
          final status = result.missingInJson.contains(key.key)
              ? '+'
              : result.matchedKeys.contains(key.key)
                  ? ' '
                  : '?';
          buffer.writeln('    [$status] ${key.key} (line ${key.line})');
        }
        buffer.writeln();
      }
    }

    // Summary
    if (result.hasDiscrepancies) {
      buffer.writeln('Run with --fix to auto-generate missing entries.');
      buffer.writeln('Run with --prune to remove orphaned keys.');
      buffer.writeln('Run with --verbose for per-file breakdown.');
    } else {
      buffer.writeln('All keys are in sync!');
    }

    return buffer.toString();
  }

  @override
  void report(
    ComparisonResult result,
    ExtractionResult extracted, {
    bool verbose = false,
  }) {
    stdout.write(format(result, extracted, verbose: verbose));
  }
}

/// Machine-readable JSON output reporter.
class JsonReporter implements ExtractReporter {
  @override
  String format(
    ComparisonResult result,
    ExtractionResult extracted, {
    bool verbose = false,
  }) {
    final output = <String, dynamic>{
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'statistics': {
        'filesScanned': result.stats.filesScanned,
        'jsonFilesLoaded': result.stats.jsonFilesLoaded,
        'keysInCode': result.stats.totalKeysInCode,
        'keysInJson': result.stats.totalKeysInJson,
        'matched': result.stats.matchedCount,
        'coveragePercent': double.parse(
          result.stats.coveragePercent.toStringAsFixed(2),
        ),
        'missingCount': result.stats.missingCount,
        'orphanedCount': result.stats.orphanedCount,
      },
      'missing': result.missingInJson.map((key) {
        final locations = extracted.keys
            .where((k) => k.key == key)
            .map((k) => {
                  'file': k.filePath,
                  'line': k.line,
                  'callType': k.callType.name,
                  if (k.snippet != null) 'snippet': k.snippet,
                })
            .toList();

        return {
          'key': key,
          'locations': locations,
          'placeholders': extracted.placeholdersByKey[key]?.toList() ?? [],
          'isPlural': extracted.pluralKeys.contains(key),
        };
      }).toList(),
      'orphaned': result.orphanedInJson.toList()..sort(),
      'placeholderMismatches': result.placeholderMismatches.map(
        (key, mismatch) => MapEntry(key, {
          'inCode': mismatch.inCode.toList(),
          'inJson': mismatch.inJson.toList(),
        }),
      ),
      'pluralIssues': result.pluralIssues.map(
        (key, issue) => MapEntry(key, {
          'message': issue.message,
          'missingPluralForms': issue.missingPluralForms,
          if (issue.availableForms != null)
            'availableForms': issue.availableForms!.toList(),
        }),
      ),
      'hasDiscrepancies': result.hasDiscrepancies,
    };

    // Add verbose per-file breakdown
    if (verbose) {
      output['byFile'] = extracted.byFile.map(
        (file, keys) => MapEntry(
          file,
          keys
              .map((k) => {
                    'key': k.key,
                    'line': k.line,
                    'callType': k.callType.name,
                    'isPlural': k.isPlural,
                  })
              .toList(),
        ),
      );
    }

    const encoder = JsonEncoder.withIndent('  ');
    return '${encoder.convert(output)}\n';
  }

  @override
  void report(
    ComparisonResult result,
    ExtractionResult extracted, {
    bool verbose = false,
  }) {
    stdout.write(format(result, extracted, verbose: verbose));
  }
}

/// Git-style diff output reporter.
class DiffReporter implements ExtractReporter {
  @override
  String format(
    ComparisonResult result,
    ExtractionResult extracted, {
    bool verbose = false,
  }) {
    final buffer = StringBuffer();

    // Header comment
    buffer.writeln('# shard_i18n extract diff');
    buffer.writeln('# Generated: ${DateTime.now().toUtc().toIso8601String()}');
    buffer.writeln('# Keys in code: ${result.stats.totalKeysInCode}');
    buffer.writeln('# Keys in JSON: ${result.stats.totalKeysInJson}');
    buffer.writeln('# Coverage: ${result.stats.coveragePercent.toStringAsFixed(1)}%');
    buffer.writeln();

    // Missing keys (to add)
    if (result.missingInJson.isNotEmpty) {
      buffer.writeln('# Missing in JSON (need to add):');
      final sortedMissing = result.missingInJson.toList()..sort();
      for (final key in sortedMissing) {
        final locations = extracted.keys.where((k) => k.key == key);
        final firstLoc = locations.isNotEmpty ? locations.first : null;
        final comment = firstLoc != null
            ? ' # ${firstLoc.filePath}:${firstLoc.line}'
            : '';
        buffer.writeln('+ $key$comment');
      }
      buffer.writeln();
    }

    // Orphaned keys (to remove)
    if (result.orphanedInJson.isNotEmpty) {
      buffer.writeln('# Orphaned in JSON (can remove):');
      final sortedOrphaned = result.orphanedInJson.toList()..sort();
      for (final key in sortedOrphaned) {
        buffer.writeln('- $key');
      }
      buffer.writeln();
    }

    // Placeholder mismatches (need attention)
    if (result.placeholderMismatches.isNotEmpty) {
      buffer.writeln('# Placeholder mismatches (need attention):');
      for (final mismatch in result.placeholderMismatches.values) {
        buffer.writeln(
            '~ ${mismatch.key} # code:{${mismatch.inCode.join(',')}} json:{${mismatch.inJson.join(',')}}');
      }
      buffer.writeln();
    }

    // Plural issues
    if (result.pluralIssues.isNotEmpty) {
      buffer.writeln('# Plural form issues:');
      for (final issue in result.pluralIssues.values) {
        buffer.writeln('! ${issue.key} # ${issue.message}');
      }
      buffer.writeln();
    }

    // Summary
    if (!result.hasDiscrepancies) {
      buffer.writeln('# All keys are in sync!');
    }

    return buffer.toString();
  }

  @override
  void report(
    ComparisonResult result,
    ExtractionResult extracted, {
    bool verbose = false,
  }) {
    stdout.write(format(result, extracted, verbose: verbose));
  }
}
