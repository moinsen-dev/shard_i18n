/// shard_i18n - Runtime, sharded, msgid-based i18n for Flutter
///
/// A tiny, production-ready internationalization layer for Flutter that:
/// - uses English msgid (or stable IDs) directly in code
/// - loads sharded JSON per locale to minimize merge conflicts
/// - supports dynamic language switching (BLoC-friendly)
/// - avoids code generation
/// - provides fallbacks, interpolation, and plurals
library;

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

/// Type definition for plural category resolver functions.
///
/// Returns a CLDR plural category ('zero', 'one', 'two', 'few', 'many', 'other')
/// based on the numeric value.
typedef PluralCategory = String Function(num n);

/// Main i18n manager class (singleton).
///
/// Handles loading of sharded translation files, locale switching,
/// and provides translation/pluralization methods.
///
/// Usage:
/// ```dart
/// // Bootstrap on app startup
/// await ShardI18n.instance.bootstrap(Locale('en'));
///
/// // Switch locale at runtime
/// await ShardI18n.instance.setLocale(Locale('de'));
///
/// // Access via context extensions
/// Text(context.t('Hello, {name}!', params: {'name': 'World'}))
/// Text(context.tn('items_count', count: 5))
/// ```
class ShardI18n extends ChangeNotifier {
  ShardI18n._();

  /// Singleton instance
  static final ShardI18n instance = ShardI18n._();

  /// Current active locale
  Locale _locale = const Locale('en');

  /// Merged translation dictionary for current locale
  Map<String, dynamic> _dict = {};

  /// Cache of loaded translation files by locale tag
  final Map<String, Map<String, dynamic>> _cache = {};

  /// Plural category resolvers by language code
  final Map<String, PluralCategory> _pluralRules = {};

  /// Cached list of supported locales (lazy-loaded)
  List<Locale>? _supportedLocales;

  /// Flag to track if bootstrap has been called
  bool _bootstrapped = false;

  /// Enable debug logging for missing translation keys
  bool debugLogMissingKeys = true;

  /// Set to track already-logged missing keys (prevent spam)
  final Set<String> _loggedMissingKeys = {};

  /// Get the current effective locale
  Locale get locale => _locale;

  /// Get list of supported locales discovered from assets.
  ///
  /// This is lazy-loaded from AssetManifest.json after bootstrap.
  List<Locale> get supportedLocales =>
      _supportedLocales ?? const [Locale('en')];

  /// Check if the instance has been bootstrapped
  bool get isBootstrapped => _bootstrapped;

  /// One-time bootstrap before runApp.
  ///
  /// Loads translation dictionaries for [initial] locale and installs
  /// default plural rules. Must be called before any translation methods.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await ShardI18n.instance.bootstrap(Locale('en'));
  ///   runApp(MyApp());
  /// }
  /// ```
  Future<void> bootstrap(Locale initial) async {
    if (_bootstrapped) {
      developer.log(
        'ShardI18n.bootstrap() called multiple times - ignoring',
        name: 'shard_i18n',
      );
      return;
    }

    _installDefaultPluralRules();
    _locale = initial;

    try {
      await _loadLocale(initial);
      await _discoverSupportedLocales();
      _bootstrapped = true;

      developer.log(
        'Bootstrapped with locale: ${_localeTag(initial)}, '
        'supported: ${supportedLocales.map(_localeTag).join(", ")}',
        name: 'shard_i18n',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Bootstrap failed',
        name: 'shard_i18n',
        error: e,
        stackTrace: stackTrace,
      );
      // Keep English as fallback
      _bootstrapped = true;
      _supportedLocales = const [Locale('en')];
    }
  }

  /// Change locale at runtime.
  ///
  /// Hot-loads translation shards for the new locale and notifies listeners.
  /// Rebuilds all widgets listening to ShardI18n via AnimatedBuilder.
  ///
  /// Example:
  /// ```dart
  /// await ShardI18n.instance.setLocale(Locale('de'));
  /// ```
  Future<void> setLocale(Locale locale) async {
    if (!_bootstrapped) {
      throw StateError(
        'ShardI18n.setLocale() called before bootstrap(). '
        'Call bootstrap() first in main().',
      );
    }

    if (_locale == locale) {
      developer.log(
        'Locale already set to ${_localeTag(locale)}',
        name: 'shard_i18n',
      );
      return;
    }

    try {
      final oldLocale = _locale;
      _locale = locale;
      await _loadLocale(locale);

      developer.log(
        'Locale changed: ${_localeTag(oldLocale)} → ${_localeTag(locale)}',
        name: 'shard_i18n',
      );

      notifyListeners();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to switch locale to ${_localeTag(locale)}',
        name: 'shard_i18n',
        error: e,
        stackTrace: stackTrace,
      );
      // Keep previous locale on error
      rethrow;
    }
  }

  /// Translate a key using current locale.
  ///
  /// Supports named interpolation with {placeholder} syntax.
  /// Falls back to the key itself (msgid) if translation not found.
  ///
  /// Example:
  /// ```dart
  /// translate('Hello, {name}!', params: {'name': 'Alice'})
  /// // Returns: 'Hello, Alice!' (if translated) or 'Hello, {name}!' (fallback)
  /// ```
  String translate(String key, {Map<String, Object?> params = const {}}) {
    final value = _dict[key];

    if (value is String) {
      return _interpolate(value, params);
    }

    // Fallback to msgid/stable ID
    if (debugLogMissingKeys && !_loggedMissingKeys.contains(key)) {
      developer.log(
        'Missing translation: "$key" for locale ${_localeTag(_locale)}',
        name: 'shard_i18n',
        level: 900, // INFO level
      );
      _loggedMissingKeys.add(key);
    }

    return _interpolate(key, params);
  }

  /// Pluralize a key based on count using CLDR plural rules.
  ///
  /// The translation should be a JSON object with plural forms:
  /// ```json
  /// {
  ///   "items_count": {
  ///     "one": "{count} item",
  ///     "other": "{count} items"
  ///   }
  /// }
  /// ```
  ///
  /// Automatically includes 'count' in interpolation params.
  ///
  /// Example:
  /// ```dart
  /// plural('items_count', count: 1)  // → "1 item"
  /// plural('items_count', count: 5)  // → "5 items"
  /// ```
  String plural(
    String key, {
    required num count,
    Map<String, Object?> params = const {},
  }) {
    final value = _dict[key];
    final mergedParams = {...params, 'count': count};

    if (value is Map<String, dynamic>) {
      final pluralForm = _pluralFormFor(_locale)(count);

      // Try the specific plural form first, then 'other', then null
      final template = (value[pluralForm] ?? value['other'])?.toString();

      if (template != null) {
        return _interpolate(template, mergedParams);
      }
    }

    // Fallback to msgid/stable ID
    if (debugLogMissingKeys && !_loggedMissingKeys.contains(key)) {
      developer.log(
        'Missing plural translation: "$key" for locale ${_localeTag(_locale)}',
        name: 'shard_i18n',
        level: 900,
      );
      _loggedMissingKeys.add(key);
    }

    return _interpolate(key, mergedParams);
  }

  /// Register a custom plural rule for a language code.
  ///
  /// Overrides the default plural category resolver for the given language.
  ///
  /// Example:
  /// ```dart
  /// ShardI18n.instance.registerPluralRule('fr', (n) {
  ///   return n == 0 || n == 1 ? 'one' : 'other';
  /// });
  /// ```
  void registerPluralRule(String langCode, PluralCategory rule) {
    _pluralRules[langCode] = rule;
    developer.log(
      'Registered custom plural rule for: $langCode',
      name: 'shard_i18n',
    );
  }

  /// Clear the translation cache.
  ///
  /// Useful for testing or forcing a reload of assets.
  void clearCache() {
    _cache.clear();
    _loggedMissingKeys.clear();
    developer.log('Translation cache cleared', name: 'shard_i18n');
  }

  // ==================== INTERNAL METHODS ====================

  /// Load and merge translations for a specific locale.
  ///
  /// Implements fallback chain:
  /// 1. Locale with country code (e.g., 'de-DE')
  /// 2. Locale language only (e.g., 'de')
  /// 3. English ('en') as ultimate fallback
  ///
  /// Later entries in the merge chain override earlier ones (last-write-wins).
  Future<void> _loadLocale(Locale locale) async {
    final tags = <String>{_localeTag(locale), locale.languageCode, 'en'};

    final merged = <String, dynamic>{};

    // Merge in reverse order so later tags override earlier ones
    for (final tag in tags.toList().reversed) {
      try {
        final translations = await _loadTag(tag);
        merged.addAll(translations);
      } catch (e) {
        // Non-critical: tag might not exist (e.g., no en-US if only en exists)
        developer.log(
          'Could not load translations for tag: $tag (${e.toString()})',
          name: 'shard_i18n',
          level: 900,
        );
      }
    }

    _dict = merged;
  }

  /// Load all JSON files for a specific locale tag.
  ///
  /// Scans AssetManifest.json for files matching:
  /// `assets/i18n/<tag>/*.json`
  ///
  /// Results are cached to avoid repeated asset loading.
  Future<Map<String, dynamic>> _loadTag(String tag) async {
    // Check cache first
    if (_cache.containsKey(tag)) {
      return _cache[tag]!;
    }

    try {
      // Load asset manifest
      final manifestRaw = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestFiles = json.decode(manifestRaw);

      // Find all JSON files for this locale tag
      final prefix = 'assets/i18n/$tag/';
      final paths = manifestFiles.keys
          .where((p) => p.startsWith(prefix) && p.endsWith('.json'))
          .toList();

      if (paths.isEmpty) {
        developer.log(
          'No translation files found for: $tag',
          name: 'shard_i18n',
          level: 900,
        );
      }

      // Load and merge all files for this tag
      final merged = <String, dynamic>{};
      for (final path in paths) {
        try {
          final raw = await rootBundle.loadString(path);
          final Map<String, dynamic> data = json.decode(raw);
          merged.addAll(data);
        } catch (e) {
          developer.log(
            'Failed to load translation file: $path',
            name: 'shard_i18n',
            error: e,
          );
        }
      }

      // Cache the result
      _cache[tag] = merged;
      return merged;
    } catch (e) {
      developer.log('Error loading tag: $tag', name: 'shard_i18n', error: e);
      // Return empty map on error
      return {};
    }
  }

  /// Discover supported locales from AssetManifest.json.
  ///
  /// Parses manifest to find all unique locale folders under assets/i18n/
  Future<void> _discoverSupportedLocales() async {
    try {
      final manifestRaw = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestFiles = json.decode(manifestRaw);

      // Extract unique locale tags from paths like: assets/i18n/<locale>/*.json
      final locales = <Locale>{};
      final pattern = RegExp(r'assets/i18n/([a-z]{2}(?:-[A-Z]{2})?)/');

      for (final path in manifestFiles.keys) {
        final match = pattern.firstMatch(path);
        if (match != null) {
          final tag = match.group(1)!;
          locales.add(_parseLocaleTag(tag));
        }
      }

      _supportedLocales = locales.toList()
        ..sort((a, b) {
          return a.languageCode.compareTo(b.languageCode);
        });

      if (_supportedLocales!.isEmpty) {
        // Fallback to English if no assets found
        _supportedLocales = const [Locale('en')];
      }
    } catch (e) {
      developer.log(
        'Failed to discover supported locales',
        name: 'shard_i18n',
        error: e,
      );
      // Fallback to English
      _supportedLocales = const [Locale('en')];
    }
  }

  /// Interpolate {placeholder} values in a string.
  ///
  /// Replaces all {name} patterns with corresponding values from params.
  /// Leaves placeholder unchanged if param not found.
  ///
  /// Example:
  /// ```dart
  /// _interpolate('Hello, {name}!', {'name': 'Alice'})
  /// // → 'Hello, Alice!'
  /// ```
  String _interpolate(String template, Map<String, Object?> params) {
    if (params.isEmpty) return template;

    return template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (match) {
      final key = match.group(1)!;
      final value = params[key];

      if (value == null) {
        // Keep placeholder if param not provided
        return match.group(0)!;
      }

      return value.toString();
    });
  }

  /// Convert a Locale to a tag string (e.g., 'en', 'de-DE')
  String _localeTag(Locale locale) {
    return (locale.countryCode?.isNotEmpty ?? false)
        ? '${locale.languageCode}-${locale.countryCode}'
        : locale.languageCode;
  }

  /// Parse a locale tag string into a Locale object
  Locale _parseLocaleTag(String tag) {
    final parts = tag.split('-');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }

  /// Get the plural category resolver for a locale
  PluralCategory _pluralFormFor(Locale locale) {
    return _pluralRules[locale.languageCode] ?? _pluralRules['default']!;
  }

  /// Install default CLDR-style plural rules for common languages.
  ///
  /// Covers most EU languages with proper one/few/many/other categorization.
  void _installDefaultPluralRules() {
    if (_pluralRules.isNotEmpty) return;

    // Default rule for most languages (English, German, Dutch, Spanish, etc.)
    // one: n == 1, other: everything else
    _pluralRules['default'] = (n) => n == 1 ? 'one' : 'other';

    // Polish: complex rules with one/few/many/other
    _pluralRules['pl'] = (n) {
      final i = n.abs().floor();
      final mod10 = i % 10;
      final mod100 = i % 100;

      if (i == 1) return 'one';
      if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
        return 'few';
      }
      if (mod10 == 0 ||
          (mod10 >= 5 && mod10 <= 9) ||
          (mod100 >= 12 && mod100 <= 14)) {
        return 'many';
      }
      return 'other';
    };

    // Slavic languages: Russian, Ukrainian, Serbian, Croatian, Bosnian
    // one/few/many/other distinction
    String slavicRule(num n) {
      final i = n.abs().floor();
      final mod10 = i % 10;
      final mod100 = i % 100;

      if (mod10 == 1 && mod100 != 11) return 'one';
      if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
        return 'few';
      }
      if (mod10 == 0 ||
          (mod10 >= 5 && mod10 <= 9) ||
          (mod100 >= 11 && mod100 <= 14)) {
        return 'many';
      }
      return 'other';
    }

    for (final lang in ['ru', 'uk', 'sr', 'hr', 'bs']) {
      _pluralRules[lang] = slavicRule;
    }

    // Czech and Slovak: one/few/other
    String czechRule(num n) {
      if (n == 1) return 'one';
      if (n >= 2 && n <= 4) return 'few';
      return 'other';
    }

    for (final lang in ['cs', 'sk']) {
      _pluralRules[lang] = czechRule;
    }

    // Turkish: no plural distinction (always 'other')
    _pluralRules['tr'] = (n) => 'other';

    // French: treat 0 and 1 as singular
    _pluralRules['fr'] = (n) => (n == 0 || n == 1) ? 'one' : 'other';

    // Romanian: special rules for one/few/other
    _pluralRules['ro'] = (n) {
      final i = n.abs().floor();
      if (i == 1) return 'one';
      if (n == 0 || (i % 100 >= 1 && i % 100 <= 19)) return 'few';
      return 'other';
    };

    // Lithuanian: complex rules
    _pluralRules['lt'] = (n) {
      final mod10 = n % 10;
      final mod100 = n % 100;

      if (mod10 == 1 && !(mod100 >= 11 && mod100 <= 19)) return 'one';
      if (mod10 >= 2 && mod10 <= 9 && !(mod100 >= 11 && mod100 <= 19)) {
        return 'few';
      }
      return 'other';
    };

    // Latvian: special zero/one/other
    _pluralRules['lv'] = (n) {
      if (n == 0) return 'zero';
      if (n % 10 == 1 && n % 100 != 11) return 'one';
      return 'other';
    };
  }
}

// ==================== CONTEXT EXTENSIONS ====================

/// BuildContext extensions for convenient i18n access.
///
/// Provides shorthand methods to access ShardI18n translation methods
/// directly from BuildContext.
extension ShardI18nX on BuildContext {
  /// Translate a key with optional interpolation parameters.
  ///
  /// Example:
  /// ```dart
  /// Text(context.t('Hello, {name}!', params: {'name': 'World'}))
  /// ```
  String t(String key, {Map<String, Object?> params = const {}}) {
    return ShardI18n.instance.translate(key, params: params);
  }

  /// Pluralize a key based on count.
  ///
  /// Example:
  /// ```dart
  /// Text(context.tn('items_count', count: items.length))
  /// ```
  String tn(
    String key, {
    required num count,
    Map<String, Object?> params = const {},
  }) {
    return ShardI18n.instance.plural(key, count: count, params: params);
  }
}
