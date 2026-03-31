import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Replicated helper: Extract {placeholder} names from a string.
Set<String> extractPlaceholders(String text) {
  final pattern = RegExp(r'\{(\w+)\}');
  return pattern.allMatches(text).map((m) => m.group(1)!).toSet();
}

/// Replicated helper: Load all translation files for a locale.
Future<Map<String, dynamic>> loadLocaleTranslations(
  String basePath,
  String locale,
) async {
  final localeDir = Directory(p.join(basePath, locale));
  final merged = <String, dynamic>{};

  if (!localeDir.existsSync()) {
    return merged;
  }

  await for (final entity in localeDir.list()) {
    if (entity is File && entity.path.endsWith('.json')) {
      try {
        final content = await entity.readAsString();
        final Map<String, dynamic> data = json.decode(content);
        merged.addAll(data);
      } catch (_) {
        // Skip invalid JSON files gracefully
      }
    }
  }

  return merged;
}

/// Replicated helper: Check placeholder parity between reference and target.
List<String> checkPlaceholderParity(
  Map<String, dynamic> reference,
  Map<String, dynamic> target,
) {
  final errors = <String>[];

  for (final key in reference.keys) {
    if (!target.containsKey(key)) continue;

    final refValue = reference[key];
    final targetValue = target[key];

    if (refValue is String && targetValue is String) {
      final refPlaceholders = extractPlaceholders(refValue);
      final targetPlaceholders = extractPlaceholders(targetValue);

      if (!refPlaceholders.every((p) => targetPlaceholders.contains(p))) {
        errors.add('$key: placeholders mismatch');
      }
    }
  }

  return errors;
}

void main() {
  // ---------------------------------------------------------------
  // extractPlaceholders
  // ---------------------------------------------------------------
  group('extractPlaceholders', () {
    test('extracts single placeholder', () {
      final result = extractPlaceholders('Hello, {name}!');
      expect(result, equals({'name'}));
    });

    test('extracts multiple placeholders', () {
      final result = extractPlaceholders('{firstName} {lastName}');
      expect(result, containsAll(['firstName', 'lastName']));
      expect(result.length, 2);
    });

    test('returns empty set for no placeholders', () {
      final result = extractPlaceholders('Hello, world!');
      expect(result, isEmpty);
    });

    test('extracts count placeholder', () {
      final result = extractPlaceholders('{count} items remaining');
      expect(result, contains('count'));
    });
  });

  // ---------------------------------------------------------------
  // loadLocaleTranslations (filesystem-based)
  // ---------------------------------------------------------------
  group('loadLocaleTranslations', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('helpers_test_');
    });

    tearDown(() {
      if (tmpDir.existsSync()) {
        tmpDir.deleteSync(recursive: true);
      }
    });

    test('loads and merges JSON files from locale directory', () async {
      // Create locale directory with 2 JSON files
      final localeDir = Directory(p.join(tmpDir.path, 'en'));
      localeDir.createSync(recursive: true);

      File(p.join(localeDir.path, 'core.json')).writeAsStringSync(
        json.encode({'hello': 'Hello', 'bye': 'Goodbye'}),
      );
      File(p.join(localeDir.path, 'auth.json')).writeAsStringSync(
        json.encode({'login': 'Login', 'logout': 'Logout'}),
      );

      final result = await loadLocaleTranslations(tmpDir.path, 'en');
      expect(result, hasLength(4));
      expect(result['hello'], 'Hello');
      expect(result['login'], 'Login');
    });

    test('returns empty for non-existent directory', () async {
      final result = await loadLocaleTranslations(tmpDir.path, 'zz');
      expect(result, isEmpty);
    });

    test('skips invalid JSON files gracefully', () async {
      final localeDir = Directory(p.join(tmpDir.path, 'en'));
      localeDir.createSync(recursive: true);

      File(p.join(localeDir.path, 'good.json')).writeAsStringSync(
        json.encode({'key': 'value'}),
      );
      File(p.join(localeDir.path, 'bad.json')).writeAsStringSync(
        'NOT VALID JSON {{{',
      );

      final result = await loadLocaleTranslations(tmpDir.path, 'en');
      expect(result, equals({'key': 'value'}));
    });
  });

  // ---------------------------------------------------------------
  // checkPlaceholderParity
  // ---------------------------------------------------------------
  group('checkPlaceholderParity', () {
    test('returns empty for matching placeholders', () {
      final ref = {'greeting': 'Hello {name}!'};
      final target = {'greeting': 'Hallo {name}!'};
      expect(checkPlaceholderParity(ref, target), isEmpty);
    });

    test('detects missing placeholder in target', () {
      final ref = {'greeting': 'Hello {name}!'};
      final target = {'greeting': 'Hallo!'};
      final errors = checkPlaceholderParity(ref, target);
      expect(errors, hasLength(1));
      expect(errors.first, contains('greeting'));
    });

    test('skips keys not in target', () {
      final ref = {'greeting': 'Hello {name}!'};
      final target = <String, dynamic>{};
      expect(checkPlaceholderParity(ref, target), isEmpty);
    });
  });
}
