import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shard_i18n/shard_i18n.dart';

void main() {
  // ==================== Singleton ====================
  group('Singleton', () {
    setUp(() => ShardI18n.instance.resetForTesting());

    test('instance is not null', () {
      expect(ShardI18n.instance, isNotNull);
    });

    test('always returns same instance', () {
      final a = ShardI18n.instance;
      final b = ShardI18n.instance;
      expect(a, same(b));
    });
  });

  // ==================== Bootstrap ====================
  group('Bootstrap', () {
    setUp(() => ShardI18n.instance.resetForTesting());

    test('isBootstrapped is false before bootstrap', () {
      expect(ShardI18n.instance.isBootstrapped, isFalse);
    });

    test('setLocale throws StateError before bootstrap', () {
      expect(
        () => ShardI18n.instance.setLocale(const Locale('de')),
        throwsStateError,
      );
    });

    test('loadTranslationsForTesting sets bootstrapped flag', () {
      ShardI18n.instance.loadTranslationsForTesting({}, const Locale('en'));
      expect(ShardI18n.instance.isBootstrapped, isTrue);
    });
  });

  // ==================== Translate ====================
  group('Translate', () {
    setUp(() {
      ShardI18n.instance.resetForTesting();
      ShardI18n.instance.loadTranslationsForTesting({
        'Hello': 'Hallo',
        'Hello, {name}!': 'Hallo, {name}!',
        'Welcome {first} {last}': 'Willkommen {first} {last}',
        'Greeting {who}': 'Gruss {who}',
      }, const Locale('de'));
    });

    test('returns translated string when key exists', () {
      expect(ShardI18n.instance.translate('Hello'), equals('Hallo'));
    });

    test('falls back to msgid for missing key', () {
      expect(
        ShardI18n.instance.translate('Unknown key'),
        equals('Unknown key'),
      );
    });

    test('interpolates single param', () {
      expect(
        ShardI18n.instance.translate(
          'Hello, {name}!',
          params: {'name': 'World'},
        ),
        equals('Hallo, World!'),
      );
    });

    test('interpolates multiple params', () {
      expect(
        ShardI18n.instance.translate(
          'Welcome {first} {last}',
          params: {'first': 'John', 'last': 'Doe'},
        ),
        equals('Willkommen John Doe'),
      );
    });

    test('keeps placeholder when param missing or null', () {
      // Missing param entirely
      expect(
        ShardI18n.instance.translate('Greeting {who}'),
        equals('Gruss {who}'),
      );

      // Param explicitly null
      expect(
        ShardI18n.instance.translate('Greeting {who}', params: {'who': null}),
        equals('Gruss {who}'),
      );
    });
  });

  // ==================== Plurals — English ====================
  group('Plurals — English', () {
    setUp(() {
      ShardI18n.instance.resetForTesting();
      ShardI18n.instance.loadTranslationsForTesting({
        'items': {
          'one': '{count} item',
          'other': '{count} items',
        },
      }, const Locale('en'));
    });

    test('count 1 returns one form', () {
      expect(
        ShardI18n.instance.plural('items', count: 1),
        equals('1 item'),
      );
    });

    test('count 0 returns other form', () {
      expect(
        ShardI18n.instance.plural('items', count: 0),
        equals('0 items'),
      );
    });

    test('count 5 returns other form', () {
      expect(
        ShardI18n.instance.plural('items', count: 5),
        equals('5 items'),
      );
    });
  });

  // ==================== Plurals — Slavic/Russian ====================
  group('Plurals — Slavic/Russian', () {
    setUp(() {
      ShardI18n.instance.resetForTesting();
      ShardI18n.instance.loadTranslationsForTesting({
        'items': {
          'one': '{count} предмет',
          'few': '{count} предмета',
          'many': '{count} предметов',
          'other': '{count} предметов',
        },
      }, const Locale('ru'));
    });

    test('1 returns one form', () {
      expect(
        ShardI18n.instance.plural('items', count: 1),
        equals('1 предмет'),
      );
    });

    test('2 returns few form', () {
      expect(
        ShardI18n.instance.plural('items', count: 2),
        equals('2 предмета'),
      );
    });

    test('5 returns many form', () {
      expect(
        ShardI18n.instance.plural('items', count: 5),
        equals('5 предметов'),
      );
    });

    test('21 returns one form', () {
      expect(
        ShardI18n.instance.plural('items', count: 21),
        equals('21 предмет'),
      );
    });

    test('11 returns many form', () {
      expect(
        ShardI18n.instance.plural('items', count: 11),
        equals('11 предметов'),
      );
    });
  });

  // ==================== Plurals — Czech ====================
  group('Plurals — Czech', () {
    setUp(() {
      ShardI18n.instance.resetForTesting();
      ShardI18n.instance.loadTranslationsForTesting({
        'items': {
          'one': '{count} položka',
          'few': '{count} položky',
          'other': '{count} položek',
        },
      }, const Locale('cs'));
    });

    test('1 returns one form', () {
      expect(
        ShardI18n.instance.plural('items', count: 1),
        equals('1 položka'),
      );
    });

    test('3 returns few form', () {
      expect(
        ShardI18n.instance.plural('items', count: 3),
        equals('3 položky'),
      );
    });

    test('5 returns other form', () {
      expect(
        ShardI18n.instance.plural('items', count: 5),
        equals('5 položek'),
      );
    });
  });

  // ==================== Plurals — Turkish ====================
  group('Plurals — Turkish', () {
    setUp(() {
      ShardI18n.instance.resetForTesting();
      ShardI18n.instance.loadTranslationsForTesting({
        'items': {
          'other': '{count} öğe',
        },
      }, const Locale('tr'));
    });

    test('always returns other form', () {
      expect(
        ShardI18n.instance.plural('items', count: 1),
        equals('1 öğe'),
      );
      expect(
        ShardI18n.instance.plural('items', count: 5),
        equals('5 öğe'),
      );
    });
  });

  // ==================== Plurals — French ====================
  group('Plurals — French', () {
    setUp(() {
      ShardI18n.instance.resetForTesting();
      ShardI18n.instance.loadTranslationsForTesting({
        'items': {
          'one': '{count} élément',
          'other': '{count} éléments',
        },
      }, const Locale('fr'));
    });

    test('0 returns one form (French treats 0 as singular)', () {
      expect(
        ShardI18n.instance.plural('items', count: 0),
        equals('0 élément'),
      );
    });

    test('1 returns one form', () {
      expect(
        ShardI18n.instance.plural('items', count: 1),
        equals('1 élément'),
      );
    });

    test('2 returns other form', () {
      expect(
        ShardI18n.instance.plural('items', count: 2),
        equals('2 éléments'),
      );
    });
  });

  // ==================== Plurals — Custom Rule ====================
  group('Plurals — Custom Rule', () {
    setUp(() {
      ShardI18n.instance.resetForTesting();
      ShardI18n.instance.loadTranslationsForTesting({
        'items': {
          'one': '{count} thing',
          'other': '{count} things',
        },
      }, const Locale('en'));
    });

    test('registerPluralRule overrides default', () {
      // Override English rule so everything is "other"
      ShardI18n.instance.registerPluralRule('en', (n) => 'other');
      expect(
        ShardI18n.instance.plural('items', count: 1),
        equals('1 things'),
      );
    });
  });

  // ==================== Plurals — Fallback ====================
  group('Plurals — Fallback', () {
    setUp(() => ShardI18n.instance.resetForTesting());

    test('falls back to other when specific form missing', () {
      ShardI18n.instance.loadTranslationsForTesting({
        'items': {
          'other': '{count} items (fallback)',
        },
      }, const Locale('en'));

      // English count=1 wants "one" but only "other" exists
      expect(
        ShardI18n.instance.plural('items', count: 1),
        equals('1 items (fallback)'),
      );
    });

    test('falls back to msgid for missing plural key', () {
      ShardI18n.instance.loadTranslationsForTesting({}, const Locale('en'));

      expect(
        ShardI18n.instance.plural('missing_key', count: 3),
        equals('missing_key'),
      );
    });
  });

  // ==================== Cache ====================
  group('Cache', () {
    setUp(() => ShardI18n.instance.resetForTesting());

    test('clearCache does not throw', () {
      expect(() => ShardI18n.instance.clearCache(), returnsNormally);
    });

    test('clearCache resets logged missing keys', () {
      ShardI18n.instance.loadTranslationsForTesting({}, const Locale('en'));
      ShardI18n.instance.debugLogMissingKeys = true;

      // Trigger a missing key to be logged
      ShardI18n.instance.translate('some_missing_key');

      // Clear cache should reset the logged missing keys set
      ShardI18n.instance.clearCache();

      // After clear, the same key should be loggable again (no exception)
      expect(
        () => ShardI18n.instance.translate('some_missing_key'),
        returnsNormally,
      );

      // Clean up
      ShardI18n.instance.debugLogMissingKeys = false;
    });
  });

  // ==================== String Extensions ====================
  group('String Extensions', () {
    setUp(() {
      ShardI18n.instance.resetForTesting();
      ShardI18n.instance.loadTranslationsForTesting({
        'Hello': 'Hola',
        'Hi {name}': 'Hola {name}',
        'apples': {
          'one': '{count} manzana',
          'other': '{count} manzanas',
        },
      }, const Locale('es'));
    });

    test('.tx translates', () {
      expect('Hello'.tx, equals('Hola'));
    });

    test('.t() with params interpolates', () {
      expect(
        'Hi {name}'.t({'name': 'Mundo'}),
        equals('Hola Mundo'),
      );
    });

    test('.tn() pluralizes', () {
      // Spanish uses default plural rule (1=one, else=other)
      expect('apples'.tn(count: 1), equals('1 manzana'));
      expect('apples'.tn(count: 3), equals('3 manzanas'));
    });
  });

  // ==================== resetForTesting ====================
  group('resetForTesting', () {
    test('resets bootstrapped flag', () {
      ShardI18n.instance.loadTranslationsForTesting({}, const Locale('de'));
      expect(ShardI18n.instance.isBootstrapped, isTrue);

      ShardI18n.instance.resetForTesting();
      expect(ShardI18n.instance.isBootstrapped, isFalse);
    });

    test('resets locale to en', () {
      ShardI18n.instance.loadTranslationsForTesting({}, const Locale('fr'));
      expect(ShardI18n.instance.locale.languageCode, equals('fr'));

      ShardI18n.instance.resetForTesting();
      expect(ShardI18n.instance.locale.languageCode, equals('en'));
    });
  });

  // ==================== debugLogMissingKeys ====================
  group('debugLogMissingKeys', () {
    setUp(() {
      ShardI18n.instance.resetForTesting();
      ShardI18n.instance.debugLogMissingKeys = false;
    });

    test('defaults to false', () {
      expect(ShardI18n.instance.debugLogMissingKeys, isFalse);
    });

    test('can be set to true', () {
      ShardI18n.instance.debugLogMissingKeys = true;
      expect(ShardI18n.instance.debugLogMissingKeys, isTrue);
    });
  });

  // ==================== Locale ====================
  group('Locale', () {
    setUp(() => ShardI18n.instance.resetForTesting());

    test('default locale is en', () {
      expect(ShardI18n.instance.locale.languageCode, equals('en'));
    });

    test('supportedLocales defaults to [en]', () {
      final locales = ShardI18n.instance.supportedLocales;
      expect(locales, hasLength(1));
      expect(locales.first.languageCode, equals('en'));
    });
  });
}
