import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shard_i18n_cli/src/extract/extraction_result.dart';
import 'package:shard_i18n_cli/src/extract/i18n_key_extractor.dart';
import 'package:shard_i18n_cli/src/extract/json_comparator.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------
  // I18nKeyExtractor
  // ---------------------------------------------------------------
  group('I18nKeyExtractor', () {
    late Directory tmpDir;
    late I18nKeyExtractor extractor;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('extract_test_');
      extractor = I18nKeyExtractor();
    });

    tearDown(() {
      if (tmpDir.existsSync()) {
        tmpDir.deleteSync(recursive: true);
      }
    });

    /// Helper to write a Dart file and extract keys from it.
    Future<ExtractionResult> extractFromSource(String source) async {
      final file = File(p.join(tmpDir.path, 'test_file.dart'));
      file.writeAsStringSync(source);
      return extractor.extract([file.path]);
    }

    test('extracts context.t() calls', () async {
      final result = await extractFromSource('''
void build(BuildContext context) {
  final text = context.t('hello_world');
}
''');
      expect(result.uniqueKeys, contains('hello_world'));
      expect(result.keys.first.callType, I18nCallType.contextT);
      expect(result.keys.first.isPlural, isFalse);
    });

    test('extracts context.tn() calls and marks as plural', () async {
      final result = await extractFromSource('''
void build(BuildContext context) {
  final text = context.tn('item_count', count: 5);
}
''');
      expect(result.uniqueKeys, contains('item_count'));
      expect(result.pluralKeys, contains('item_count'));
      expect(result.keys.first.callType, I18nCallType.contextTn);
      expect(result.keys.first.isPlural, isTrue);
    });

    test("extracts 'key'.tx getter", () async {
      final result = await extractFromSource('''
void build(BuildContext context) {
  final text = 'app_title'.tx;
}
''');
      expect(result.uniqueKeys, contains('app_title'));
      expect(result.keys.first.callType, I18nCallType.stringTx);
    });

    test("extracts 'key'.t({...}) string extension", () async {
      final result = await extractFromSource('''
void build(BuildContext context) {
  final text = 'greeting'.t({'name': 'World'});
}
''');
      expect(result.uniqueKeys, contains('greeting'));
      expect(result.keys.first.callType, I18nCallType.stringT);
    });

    test("extracts 'key'.tn(count: n) string extension", () async {
      final result = await extractFromSource('''
void build(BuildContext context) {
  final text = 'items'.tn(count: 3);
}
''');
      expect(result.uniqueKeys, contains('items'));
      expect(result.pluralKeys, contains('items'));
      expect(result.keys.first.callType, I18nCallType.stringTn);
    });

    test('deduplicates keys across files', () async {
      final file1 = File(p.join(tmpDir.path, 'file1.dart'));
      file1.writeAsStringSync('''
void a(BuildContext context) { context.t('shared_key'); }
''');
      final file2 = File(p.join(tmpDir.path, 'file2.dart'));
      file2.writeAsStringSync('''
void b(BuildContext context) { context.t('shared_key'); }
''');

      final result = await extractor.extract([file1.path, file2.path]);
      // keys list has both occurrences
      expect(result.keys.where((k) => k.key == 'shared_key').length, 2);
      // uniqueKeys is deduplicated
      expect(result.uniqueKeys.where((k) => k == 'shared_key').length, 1);
    });

    test('ignores string interpolation keys', () async {
      final result = await extractFromSource(r'''
void build(BuildContext context) {
  final key = 'dynamic';
  final text = context.t('prefix_${key}');
}
''');
      // Interpolated strings are not extractable
      expect(result.uniqueKeys, isEmpty);
    });

    test('extracts placeholders from key string', () async {
      final result = await extractFromSource('''
void build(BuildContext context) {
  final text = context.t('hello_{name}');
}
''');
      expect(result.uniqueKeys, contains('hello_{name}'));
      expect(result.placeholdersByKey['hello_{name}'], contains('name'));
    });
  });

  // ---------------------------------------------------------------
  // JsonComparator
  // ---------------------------------------------------------------
  group('JsonComparator', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('comparator_test_');
    });

    tearDown(() {
      if (tmpDir.existsSync()) {
        tmpDir.deleteSync(recursive: true);
      }
    });

    /// Helper to create a JSON locale file.
    void writeJson(String locale, String filename, Map<String, dynamic> data) {
      final dir = Directory(p.join(tmpDir.path, locale));
      dir.createSync(recursive: true);
      File(p.join(dir.path, filename)).writeAsStringSync(json.encode(data));
    }

    test('detects missing keys (key in code but not JSON)', () async {
      writeJson('en', 'core.json', {'existing_key': 'value'});

      final comparator = JsonComparator(
        i18nPath: tmpDir.path,
        referenceLocale: 'en',
      );

      final extracted = ExtractionResult(
        keys: [
          ExtractedKey(
            key: 'existing_key',
            filePath: 'a.dart',
            line: 1,
            column: 1,
            callType: I18nCallType.contextT,
          ),
          ExtractedKey(
            key: 'missing_key',
            filePath: 'a.dart',
            line: 2,
            column: 1,
            callType: I18nCallType.contextT,
          ),
        ],
        byFile: {},
        uniqueKeys: {'existing_key', 'missing_key'},
        pluralKeys: {},
        placeholdersByKey: {},
        filesScanned: 1,
        scanDuration: Duration.zero,
      );

      final result = await comparator.compare(extracted);
      expect(result.missingInJson, contains('missing_key'));
      expect(result.missingInJson, isNot(contains('existing_key')));
    });

    test('detects orphaned keys (key in JSON but not code)', () async {
      writeJson('en', 'core.json', {
        'used_key': 'Used',
        'orphaned_key': 'Orphaned',
      });

      final comparator = JsonComparator(
        i18nPath: tmpDir.path,
        referenceLocale: 'en',
      );

      final extracted = ExtractionResult(
        keys: [
          ExtractedKey(
            key: 'used_key',
            filePath: 'a.dart',
            line: 1,
            column: 1,
            callType: I18nCallType.contextT,
          ),
        ],
        byFile: {},
        uniqueKeys: {'used_key'},
        pluralKeys: {},
        placeholdersByKey: {},
        filesScanned: 1,
        scanDuration: Duration.zero,
      );

      final result = await comparator.compare(extracted);
      expect(result.orphanedInJson, contains('orphaned_key'));
      expect(result.orphanedInJson, isNot(contains('used_key')));
    });

    test(
      'detects plural form issues (tn used but JSON value is not a map)',
      () async {
        writeJson('en', 'core.json', {'item_count': 'Not a plural map'});

        final comparator = JsonComparator(
          i18nPath: tmpDir.path,
          referenceLocale: 'en',
        );

        final extracted = ExtractionResult(
          keys: [
            ExtractedKey(
              key: 'item_count',
              filePath: 'a.dart',
              line: 1,
              column: 1,
              callType: I18nCallType.contextTn,
              isPlural: true,
            ),
          ],
          byFile: {},
          uniqueKeys: {'item_count'},
          pluralKeys: {'item_count'},
          placeholdersByKey: {},
          filesScanned: 1,
          scanDuration: Duration.zero,
        );

        final result = await comparator.compare(extracted);
        expect(result.pluralIssues, contains('item_count'));
        expect(result.pluralIssues['item_count']!.missingPluralForms, isTrue);
      },
    );

    test('no plural issue when JSON value is a proper plural map', () async {
      writeJson('en', 'core.json', {
        'item_count': {'one': '1 item', 'other': '{count} items'},
      });

      final comparator = JsonComparator(
        i18nPath: tmpDir.path,
        referenceLocale: 'en',
      );

      final extracted = ExtractionResult(
        keys: [
          ExtractedKey(
            key: 'item_count',
            filePath: 'a.dart',
            line: 1,
            column: 1,
            callType: I18nCallType.contextTn,
            isPlural: true,
          ),
        ],
        byFile: {},
        uniqueKeys: {'item_count'},
        pluralKeys: {'item_count'},
        placeholdersByKey: {},
        filesScanned: 1,
        scanDuration: Duration.zero,
      );

      final result = await comparator.compare(extracted);
      expect(result.pluralIssues, isEmpty);
    });
  });
}
