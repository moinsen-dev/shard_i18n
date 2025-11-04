shard_i18n — Runtime, Sharded, Msgid-based i18n for Flutter (no codegen)

A tiny, production-ready internationalization layer for Flutter that:
	•	uses English msgid (or stable IDs) directly in code,
	•	loads sharded JSON per locale to minimize merge conflicts,
	•	supports dynamic language switching (BLoC-friendly),
	•	avoids code generation,
	•	provides fallbacks, interpolation, and plurals,
	•	plays nicely with flutter_localizations (for dates, pickers, etc.),
	•	is easy to automate with AI translation scripts.

⸻

Why this package

Large teams often fight over one giant ARB/JSON file and slow codegen cycles. shard_i18n removes those bottlenecks:
	•	No codegen: pure runtime lookups (context.t('Sign in')).
	•	Sharded by feature: assets/i18n/<locale>/<feature>.json → fewer PR conflicts.
	•	Msgid ergonomics: readable English in code; auto-fallback if missing.
	•	Optional stable IDs: use auth.sign_in for volatile copy that changes often.
	•	BLoC-ready: a tiny LanguageCubit drives Locale; UI pulls strings via context.

⸻

Installation

# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.4
  shared_preferences: ^2.2.3

flutter:
  assets:
    - assets/i18n/

Optional (recommended) for built-in widget localizations:

localizationsDelegates: const [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],


⸻

Folder layout (sharded, low-conflict)

assets/i18n/
  en/
    core.json
    auth.json
    settings.json
  de/
    core.json
    auth.json
    settings.json
  tr/
    core.json
    auth.json
    settings.json
  ru/
    core.json

Example assets/i18n/en/auth.json (source/msgid):

{
  "Sign in": "Sign in",
  "Hello, {name}!": "Hello, {name}!",
  "items_count": { "one": "{count} item", "other": "{count} items" }
}

German assets/i18n/de/auth.json:

{
  "Sign in": "Anmelden",
  "Hello, {name}!": "Hallo, {name}!",
  "items_count": { "one": "{count} Artikel", "other": "{count} Artikel" }
}

Turkish assets/i18n/tr/auth.json:

{
  "Sign in": "Giriş yap",
  "Hello, {name}!": "Merhaba, {name}!",
  "items_count": { "one": "{count} öğe", "other": "{count} öğe" }
}

Russian (multi-plural) assets/i18n/ru/core.json:

{
  "items_count": {
    "one": "{count} предмет",
    "few": "{count} предмета",
    "many": "{count} предметов",
    "other": "{count} предмета"
  }
}

Msgid vs. stable IDs: use msgid (natural English) by default; switch to stable IDs like auth.sign_in when the English wording is volatile. The lookup works for both.

⸻

Quick start (app wiring)

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shard_i18n/shard_i18n.dart';        // package import
import 'language_cubit.dart';                       // see below

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initial = await LanguageCubit.loadInitial();
  await ShardI18n.instance.bootstrap(initial);     // pre-load current locale

  runApp(
    BlocProvider(
      create: (_) => LanguageCubit(initial),
      child: const AppRoot(),
    ),
  );
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LanguageCubit>().state;

    return AnimatedBuilder(
      animation: ShardI18n.instance, // rebuild when dictionary changes
      builder: (_, __) {
        return MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: ShardI18n.instance.supportedLocales, // auto-discovered
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('Hello, {name}!', params: {'name': 'Uli'}))),
      body: Center(child: Text(context.tn('items_count', count: 3))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showLanguagePicker(context),
        child: const Icon(Icons.language),
      ),
    );
  }
}


⸻

Public API

1) BuildContext extensions

extension I18nX on BuildContext {
  /// Translate by msgid or stable ID.
  String t(String key, {Map<String, Object?> params = const {}});

  /// Pluralize with locale-aware rules.
  String tn(String key, {required num count, Map<String, Object?> params = const {}});
}

2) ShardI18n singleton

class ShardI18n extends ChangeNotifier {
  static final ShardI18n instance = ShardI18n._();

  /// Current effective locale.
  Locale get locale;

  /// Locales discovered from assets: assets/i18n/<locale>/
  List<Locale> get supportedLocales;

  /// One-time boot before runApp; loads dictionaries for [initial].
  Future<void> bootstrap(Locale initial);

  /// Change locale at runtime. Hot-loads shards & notifies listeners.
  Future<void> setLocale(Locale locale);

  /// Low-level: translate & pluralize (used by context extensions).
  String translate(String key, {Map<String, Object?> params = const {}});
  String plural(String key, {required num count, Map<String, Object?> params = const {}});
}

3) LanguageCubit (example)

// lib/language_cubit.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shard_i18n/shard_i18n.dart';

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit(Locale initial) : super(initial);

  static const _k = 'app_locale';

  static Future<Locale> loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_k);
    if (saved != null && saved.isNotEmpty) {
      final p = saved.split('-');
      return p.length == 2 ? Locale(p[0], p[1]) : Locale(p[0]);
    }
    return WidgetsBinding.instance.platformDispatcher.locale; // device default
  }

  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;
    await ShardI18n.instance.setLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    final tag = locale.countryCode?.isNotEmpty == true
        ? '${locale.languageCode}-${locale.countryCode}'
        : locale.languageCode;
    await prefs.setString(_k, tag);
    emit(locale);
  }
}


⸻

How it works

Asset discovery & merge
	•	On bootstrap/setLocale, we scan AssetManifest.json for files matching:

assets/i18n/<langTag>/*.json    // e.g., de, de-DE, tr, ru


	•	We merge dictionaries in fallback order (highest priority last-write-wins):
	1.	language-country (e.g., de-DE)
	2.	language (e.g., de)
	3.	en (base)
	•	Lookups then resolve from the merged in-memory map.

Fallbacks
	•	t(key):
	•	if translation exists → interpolate & return
	•	else → return the msgid or stable ID as-is (dev-friendly)
	•	tn(key, count):
	•	choose plural form via locale rules (see below)
	•	try that form; fallback to other; fallback to msgid

Interpolation
	•	Named placeholders using {name} syntax:

"Hello, {name}!": "Hallo, {name}!"

context.t('Hello, {name}!', params: {'name': 'Uli'})



Plurals (CLDR-style)
	•	JSON plural object can include any of: zero, one, two, few, many, other.
	•	The package ships with a plural category resolver with EU-focused rules:
	•	one/other: en, de, nl, sv, no, da, fi, et, lv*, lt*, it, es, pt, tr, ro*, bg, el, hu…
	•	Slavic (ru, uk, sr, hr, bs): one/few/many/other
	•	Polish (pl): one/few/many/other
	•	Czech/Slovak (cs, sk): one/few/other
	•	(* languages with special zero/two/few cases configurable)

Start with the defaults; override or extend rules per locale via a public hook:

ShardI18n.instance.registerPluralRule('fr', (n) => n == 0 || n == 1 ? 'one' : 'other');


⸻

Conventions (to keep things tidy)
	•	No raw UI strings: Wrap literals with context.t(...) / context.tn(...).
	•	Shards by feature: Create core.json, auth.json, etc. per locale folder.
	•	Msgid default: Prefer msgids for readability; use stable IDs for strings expected to change frequently.
	•	Descriptions: (Optional) You can add a sibling meta file auth.meta.json to help translators (not used at runtime).

⸻

JSON schema (optional validation)

{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "shard_i18n translation shard",
  "type": "object",
  "additionalProperties": {
    "oneOf": [
      { "type": "string" },
      {
        "type": "object",
        "properties": {
          "zero":  { "type": "string" },
          "one":   { "type": "string" },
          "two":   { "type": "string" },
          "few":   { "type": "string" },
          "many":  { "type": "string" },
          "other": { "type": "string" }
        },
        "additionalProperties": false,
        "minProperties": 1
      }
    ]
  }
}


⸻

Testing
	•	Golden tests: pump widgets with a forced Locale('de') and assert text equals expected German strings.
	•	Unit tests: call ShardI18n.instance.bootstrap(Locale('tr')) and assert t/tn outputs.
	•	Missing keys: in debug mode, ShardI18n logs missing keys the first time they’re encountered. You can enable an option to write build/i18n_missing_<locale>.json for translators.

⸻

Performance
	•	Loads only current locale shards at startup/locale change.
	•	AssetManifest.json lookup is cached after first load.
	•	In-memory map lookups are O(1); interpolation is a simple regex replace.
	•	For very large apps, keep shards reasonably sized (e.g., <5–10k lines per shard) to minimize IO on locale switch.

⸻

Security & UX notes
	•	Translators should not edit Dart code—only JSON.
	•	Keep placeholders identical across locales (the package validates that used {name} exist in the string).
	•	Consider accessibility: some languages make labels longer; test overflow with maxLines/softWrap.

⸻

Optional CLI (AI-assist)

Ship a tiny dev-only CLI (example commands):

# Fill missing keys for locales using DeepL/Google/OpenAI
dart run shard_i18n_cli fill --from=en --to=de,tr,fr --provider=deepl --key=$DEEPL_KEY

# Verify consistency
dart run shard_i18n_cli verify
  - checks missing keys
  - checks placeholder parity
  - reports unused keys (if you enable usage tracking in dev)

The CLI scans assets/i18n/en/*.json, compares with target locales, and writes only missing entries (annotated with "_auto": true for human review).

⸻

Lints (highly recommended)
	•	Disallow raw UI strings: simple custom lint to flag Text('...') unless the literal is wrapped by context.t(...).
	•	Placeholder parity: dev-time assert that placeholders {x} used in a source entry exist in translations.

⸻

Migration tips
	•	From gen_l10n / easy_localization:
	•	Export your current locale files to assets/i18n/<locale>/core.json.
	•	Replace usages with context.t('msgid-or-id').
	•	Keep GlobalMaterialLocalizations etc. if you used them before.
	•	Mixed mode is fine: you can keep a subset of legacy screens on old i18n while moving new features to shards.

⸻

Roadmap
	•	Rich ICU support (select/gender) with ICU parser.
	•	Dev overlay to live-edit translations at runtime in debug.
	•	VS Code companion: shard creation, key jump, quick-fix for missing keys.
	•	Build-time reporting (CI) with nice diff.

⸻

Minimal implementation (package internals)

You can copy this into your package as a starting point; it’s intentionally compact.

// lib/shard_i18n.dart
library shard_i18n;

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

typedef PluralCategory = String Function(num n);

class ShardI18n extends ChangeNotifier {
  ShardI18n._();
  static final ShardI18n instance = ShardI18n._();

  Locale _locale = const Locale('en');
  Map<String, dynamic> _dict = {};
  final Map<String, Map<String, dynamic>> _cache = {};
  final Map<String, PluralCategory> _pluralRules = {};

  Locale get locale => _locale;

  List<Locale> get supportedLocales => _supportedLocales ??= _discoverSupportedLocales();
  List<Locale>? _supportedLocales;

  Future<void> bootstrap(Locale initial) async {
    _installDefaultPluralRules();
    _locale = initial;
    await _loadLocale(initial);
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await _loadLocale(locale);
    notifyListeners();
  }

  String translate(String key, {Map<String, Object?> params = const {}}) {
    final v = _dict[key];
    if (v is String) return _interp(v, params);
    return _interp(key, params); // fallback to msgid/stable ID
  }

  String plural(String key, {required num count, Map<String, Object?> params = const {}}) {
    final v = _dict[key];
    final p = {...params, 'count': count};
    if (v is Map<String, dynamic>) {
      final form = _pluralFormFor(_locale)(count);
      final template = (v[form] ?? v['other'])?.toString();
      if (template != null) return _interp(template, p);
    }
    return _interp(key, p);
  }

  void registerPluralRule(String langCode, PluralCategory rule) {
    _pluralRules[langCode] = rule;
  }

  // --- internals ---

  Future<void> _loadLocale(Locale locale) async {
    final tags = <String>{ _tag(locale), locale.languageCode, 'en' };
    final merged = <String, dynamic>{};
    for (final tag in tags.toList().reversed) {
      merged.addAll(await _loadTag(tag));
    }
    _dict = merged;
  }

  Future<Map<String, dynamic>> _loadTag(String tag) async {
    if (_cache.containsKey(tag)) return _cache[tag]!;
    final manifestRaw = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> files = json.decode(manifestRaw);
    final prefix = 'assets/i18n/$tag/';
    final paths = files.keys.where((p) => p.startsWith(prefix) && p.endsWith('.json'));
    final out = <String, dynamic>{};
    for (final p in paths) {
      final raw = await rootBundle.loadString(p);
      final map = json.decode(raw) as Map<String, dynamic>;
      out.addAll(map);
    }
    _cache[tag] = out;
    return out;
  }

  List<Locale> _discoverSupportedLocales() {
    // Best effort: parse manifest once; ignore errors if not available yet.
    try {
      // This synchronous approach relies on cache after bootstrap; for simplicity,
      // we return at least [en] if manifest isn't loaded yet.
    } catch (_) {}
    // Basic default; you can replace with async discovery and a setter.
    return const [Locale('en')];
  }

  String _interp(String s, Map<String, Object?> params) =>
      s.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
        final k = m.group(1)!;
        return (params[k] ?? m.group(0)!).toString();
      });

  String _tag(Locale l) =>
      (l.countryCode?.isNotEmpty ?? false)
          ? '${l.languageCode}-${l.countryCode}'
          : l.languageCode;

  PluralCategory _pluralFormFor(Locale l) =>
      _pluralRules[l.languageCode] ?? _pluralRules['default']!;

  void _installDefaultPluralRules() {
    if (_pluralRules.isNotEmpty) return;
    _pluralRules['default'] = (n) => n == 1 ? 'one' : 'other'; // most EU langs
    // Polish
    _pluralRules['pl'] = (n) {
      final i = n.abs().floor();
      final mod10 = i % 10, mod100 = i % 100;
      if (i == 1) return 'one';
      if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) return 'few';
      if (mod10 == 0 || (mod10 >= 5 && mod10 <= 9) || (mod100 >= 12 && mod100 <= 14)) return 'many';
      return 'other';
    };
    // Russian, Ukrainian, Serbian, Croatian, Bosnian
    for (final lc in ['ru','uk','sr','hr','bs']) {
      _pluralRules[lc] = (n) {
        final i = n.abs().floor();
        final mod10 = i % 10, mod100 = i % 100;
        if (mod10 == 1 && mod100 != 11) return 'one';
        if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) return 'few';
        if (mod10 == 0 || (mod10 >= 5 && mod10 <= 9) || (mod100 >= 11 && mod100 <= 14)) return 'many';
        return 'other';
      };
    }
    // Czech/Slovak
    for (final lc in ['cs','sk']) {
      _pluralRules[lc] = (n) => n == 1 ? 'one' : (n >= 2 && n <= 4) ? 'few' : 'other';
    }
    // Turkish (no plural distinction)
    _pluralRules['tr'] = (n) => 'other';
    // French tweak (treat 0 like other; common UX choice)
    _pluralRules['fr'] = (n) => n == 1 ? 'one' : 'other';
  }
}

// Context extensions
extension ShardI18nX on BuildContext {
  String t(String key, {Map<String, Object?> params = const {}}) =>
      ShardI18n.instance.translate(key, params: params);
  String tn(String key, {required num count, Map<String, Object?> params = const {}}) =>
      ShardI18n.instance.plural(key, count: count, params: params);
}

Note: _discoverSupportedLocales() is a stub above to keep the snippet short. In the real package, implement it by parsing AssetManifest.json once after bootstrap to collect assets/i18n/<locale>/... prefixes and convert to Locale objects.

⸻

Language picker helper

Future<void> showLanguagePicker(BuildContext context) async {
  final supported = ShardI18n.instance.supportedLocales;
  final current = context.read<LanguageCubit>().state;
  await showModalBottomSheet(
    context: context,
    builder: (_) => ListView(
      children: supported.map((loc) {
        final tag = loc.countryCode?.isNotEmpty == true
            ? '${loc.languageCode}-${loc.countryCode}'
            : loc.languageCode;
        return ListTile(
          title: Text(tag),
          trailing: current == loc ? const Icon(Icons.check) : null,
          onTap: () {
            context.read<LanguageCubit>().setLocale(loc);
            Navigator.pop(context);
          },
        );
      }).toList(),
    ),
  );
}


⸻

Contribution guide (short)
	•	Keep shards small and scoped (feature-based).
	•	Don’t rename msgids lightly; use stable IDs if the English copy is volatile.
	•	When adding placeholders, keep names consistent across locales.
	•	Add/adjust plural rules with registerPluralRule when introducing a new language family.

⸻

That’s the full, drop-in spec. If you want, I can also package this as a ready-to-publish lib/ with a README.md, a tiny CLI scaffold, and a couple of example shards so you can flutter create + paste and go.