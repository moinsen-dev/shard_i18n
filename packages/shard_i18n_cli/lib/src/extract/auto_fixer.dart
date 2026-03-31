/// Auto-fixer for generating missing JSON entries and pruning orphaned keys.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'extraction_result.dart';
import 'json_comparator.dart';

/// Fixes discrepancies between code and JSON translation files.
class AutoFixer {
  /// Path to i18n assets directory.
  final String i18nPath;

  /// Reference locale to fix.
  final String referenceLocale;

  /// Whether this is a dry run (no actual changes).
  final bool dryRun;

  /// Callback for logging messages.
  final void Function(String message)? onLog;

  AutoFixer({
    required this.i18nPath,
    this.referenceLocale = 'en',
    this.dryRun = false,
    this.onLog,
  });

  /// Fix missing keys by generating entries in JSON files.
  Future<FixResult> fix(
    ComparisonResult comparison,
    ExtractionResult extracted,
  ) async {
    final filesModified = <String>{};
    final warnings = <String>[];
    var keysAdded = 0;

    if (comparison.missingInJson.isEmpty) {
      _log('No missing keys to add.');
      return FixResult(
        filesModified: [],
        keysAdded: 0,
        keysRemoved: 0,
        isDryRun: dryRun,
      );
    }

    // Group missing keys by target shard file
    final keysByShard = <String, Map<String, dynamic>>{};
    final comparator = JsonComparator(
      i18nPath: i18nPath,
      referenceLocale: referenceLocale,
    );

    for (final key in comparison.missingInJson) {
      // Find the source file for this key to determine shard
      final keyLocations = extracted.keys.where((k) => k.key == key);
      final sourceFile = keyLocations.isNotEmpty
          ? keyLocations.first.filePath
          : null;
      final shard = comparator.detectShard(key, sourceFile);

      keysByShard.putIfAbsent(shard, () => {});

      // Generate the value
      if (extracted.pluralKeys.contains(key)) {
        // Generate plural form structure
        keysByShard[shard]![key] = _generatePluralTemplate(key, extracted);
      } else {
        // Simple string: msgid = value
        keysByShard[shard]![key] = key;
      }
    }

    // Write to each shard file
    for (final entry in keysByShard.entries) {
      final shardFile = entry.key;
      final newKeys = entry.value;
      final targetPath = p.join(i18nPath, referenceLocale, shardFile);

      try {
        await _mergeIntoFile(targetPath, newKeys);
        filesModified.add(targetPath);
        keysAdded += newKeys.length;
        _log(
          '${dryRun ? "[DRY RUN] Would add" : "Added"} ${newKeys.length} key(s) to $shardFile',
        );
      } catch (e) {
        warnings.add('Could not write to $targetPath: $e');
      }
    }

    return FixResult(
      filesModified: filesModified.toList(),
      keysAdded: keysAdded,
      keysRemoved: 0,
      warnings: warnings,
      isDryRun: dryRun,
    );
  }

  /// Prune orphaned keys from JSON files.
  Future<FixResult> prune(ComparisonResult comparison) async {
    final filesModified = <String>{};
    final warnings = <String>[];
    var keysRemoved = 0;

    if (comparison.orphanedInJson.isEmpty) {
      _log('No orphaned keys to remove.');
      return FixResult(
        filesModified: [],
        keysAdded: 0,
        keysRemoved: 0,
        isDryRun: dryRun,
      );
    }

    // Load all JSON files and remove orphaned keys
    final localeDir = Directory(p.join(i18nPath, referenceLocale));
    if (!await localeDir.exists()) {
      warnings.add('Locale directory not found: ${localeDir.path}');
      return FixResult(
        filesModified: [],
        keysAdded: 0,
        keysRemoved: 0,
        warnings: warnings,
        isDryRun: dryRun,
      );
    }

    await for (final entity in localeDir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;

      try {
        final content = await entity.readAsString();
        final Map<String, dynamic> data = json.decode(content);

        // Find keys to remove from this file
        final keysToRemove = data.keys
            .where((k) => comparison.orphanedInJson.contains(k))
            .toList();

        if (keysToRemove.isEmpty) continue;

        // Remove orphaned keys
        for (final key in keysToRemove) {
          data.remove(key);
        }

        if (!dryRun) {
          const encoder = JsonEncoder.withIndent('  ');
          await entity.writeAsString('${encoder.convert(data)}\n');
        }

        filesModified.add(entity.path);
        keysRemoved += keysToRemove.length;
        _log(
          '${dryRun ? "[DRY RUN] Would remove" : "Removed"} ${keysToRemove.length} key(s) from ${p.basename(entity.path)}',
        );
      } catch (e) {
        warnings.add('Could not process ${entity.path}: $e');
      }
    }

    return FixResult(
      filesModified: filesModified.toList(),
      keysAdded: 0,
      keysRemoved: keysRemoved,
      warnings: warnings,
      isDryRun: dryRun,
    );
  }

  /// Fix and prune in a single operation.
  Future<FixResult> fixAndPrune(
    ComparisonResult comparison,
    ExtractionResult extracted, {
    bool fix = true,
    bool prune = true,
  }) async {
    final filesModified = <String>{};
    final warnings = <String>[];
    var keysAdded = 0;
    var keysRemoved = 0;

    if (fix) {
      final fixResult = await this.fix(comparison, extracted);
      filesModified.addAll(fixResult.filesModified);
      keysAdded = fixResult.keysAdded;
      warnings.addAll(fixResult.warnings);
    }

    if (prune) {
      final pruneResult = await this.prune(comparison);
      filesModified.addAll(pruneResult.filesModified);
      keysRemoved = pruneResult.keysRemoved;
      warnings.addAll(pruneResult.warnings);
    }

    return FixResult(
      filesModified: filesModified.toList(),
      keysAdded: keysAdded,
      keysRemoved: keysRemoved,
      warnings: warnings,
      isDryRun: dryRun,
    );
  }

  /// Generate plural template for a key.
  Map<String, String> _generatePluralTemplate(
    String key,
    ExtractionResult extracted,
  ) {
    // Get placeholders for this key
    final placeholders = extracted.placeholdersByKey[key] ?? {};

    // Check if 'count' is in placeholders
    final hasCount = placeholders.contains('count');

    // Generate template with {count} if not already present
    String template = key;
    if (!hasCount && !key.contains('{count}')) {
      // For a clean plural, we might want to generate something like:
      // "1 item" / "n items" but we don't know the word
      // So we just use the key with {count} prefix/suffix as hint
      template = '{count} $key';
    }

    return {'one': template, 'other': template};
  }

  /// Merge new keys into an existing JSON file.
  Future<void> _mergeIntoFile(
    String targetPath,
    Map<String, dynamic> newKeys,
  ) async {
    final file = File(targetPath);
    Map<String, dynamic> existing = {};

    // Create directory if needed
    await file.parent.create(recursive: true);

    // Load existing content
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.trim().isNotEmpty) {
        existing = json.decode(content);
      }
    }

    // Merge new keys
    existing.addAll(newKeys);

    // Sort keys alphabetically
    final sorted = Map.fromEntries(
      existing.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // Write back
    if (!dryRun) {
      const encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString('${encoder.convert(sorted)}\n');
    }
  }

  void _log(String message) {
    onLog?.call(message);
  }
}
