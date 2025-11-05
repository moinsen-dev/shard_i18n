import 'package:flutter_test/flutter_test.dart';
import 'package:shard_i18n/shard_i18n.dart';

void main() {
  group('ShardI18n Core', () {
    test('singleton instance exists', () {
      expect(ShardI18n.instance, isNotNull);
      expect(ShardI18n.instance, same(ShardI18n.instance));
    });

    test('default locale is English', () {
      expect(ShardI18n.instance.locale.languageCode, equals('en'));
    });

    test('cache can be cleared', () {
      expect(() => ShardI18n.instance.clearCache(), returnsNormally);
    });
  });

  group('String Interpolation', () {
    test('interpolation works with simple params', () {
      final result = ShardI18n.instance.translate(
        'Hello, {name}!',
        params: {'name': 'World'},
      );
      expect(result, equals('Hello, World!'));
    });

    test('interpolation works with multiple params', () {
      final result = ShardI18n.instance.translate(
        'Hello, {firstName} {lastName}!',
        params: {'firstName': 'John', 'lastName': 'Doe'},
      );
      expect(result, equals('Hello, John Doe!'));
    });

    test('interpolation returns original text when params missing', () {
      final result = ShardI18n.instance.translate(
        'Hello, {name}!',
        params: {},
      );
      expect(result, equals('Hello, {name}!'));
    });

    test('interpolation works with numeric params', () {
      final result = ShardI18n.instance.translate(
        'You have {count} items',
        params: {'count': '5'},
      );
      expect(result, equals('You have 5 items'));
    });

    test('interpolation handles null values gracefully', () {
      final result = ShardI18n.instance.translate(
        'User: {username}',
        params: {'username': null},
      );
      // Should either keep placeholder or use empty string
      expect(result, isNotEmpty);
    });
  });

  group('Plural Rules', () {
    test('can register custom plural rule', () {
      expect(
        () => ShardI18n.instance.registerPluralRule('test', (n) => 'other'),
        returnsNormally,
      );
    });

    test('plural method works with fallback', () {
      // Without translations loaded, should return the key with count
      final result = ShardI18n.instance.plural(
        'items_count',
        count: 5,
      );
      expect(result, contains('items_count'));
    });
  });

  group('Supported Locales', () {
    test('supported locales is not null', () {
      expect(ShardI18n.instance.supportedLocales, isNotNull);
    });

    test('supported locales contains at least English', () {
      final locales = ShardI18n.instance.supportedLocales;
      expect(locales, isNotEmpty);
      expect(
        locales.any((l) => l.languageCode == 'en'),
        isTrue,
      );
    });
  });
}
