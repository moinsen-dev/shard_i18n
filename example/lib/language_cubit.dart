import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shard_i18n/shard_i18n.dart';

/// Cubit for managing the application's language/locale state.
///
/// Persists the user's language choice to SharedPreferences and
/// coordinates with ShardI18n for translation loading.
///
/// Usage:
/// ```dart
/// // In main.dart:
/// final initial = await LanguageCubit.loadInitial();
/// await ShardI18n.instance.bootstrap(initial);
/// runApp(
///   BlocProvider(
///     create: (_) => LanguageCubit(initial),
///     child: MyApp(),
///   ),
/// );
///
/// // In widgets:
/// final locale = context.watch<LanguageCubit>().state;
/// context.read<LanguageCubit>().setLocale(Locale('de'));
/// ```
class LanguageCubit extends Cubit<Locale> {
  LanguageCubit(super.initialLocale);

  /// SharedPreferences key for storing locale preference
  static const _preferenceKey = 'app_locale';

  /// Load the initial locale from SharedPreferences or device default.
  ///
  /// Call this before runApp() to determine which locale to bootstrap with.
  ///
  /// Returns:
  /// - Saved locale from SharedPreferences if available
  /// - Device/system locale otherwise
  static Future<Locale> loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_preferenceKey);

    if (saved != null && saved.isNotEmpty) {
      // Parse saved locale tag (e.g., 'en', 'de', 'de-DE')
      final parts = saved.split('-');
      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      }
      return Locale(parts[0]);
    }

    // Fallback to device locale
    return WidgetsBinding.instance.platformDispatcher.locale;
  }

  /// Change the application locale.
  ///
  /// Updates ShardI18n, saves preference to SharedPreferences,
  /// and emits new state to rebuild listeners.
  Future<void> setLocale(Locale locale) async {
    if (state == locale) return;

    // Update ShardI18n (loads translations)
    await ShardI18n.instance.setLocale(locale);

    // Persist to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final tag = _localeToTag(locale);
    await prefs.setString(_preferenceKey, tag);

    // Emit new state
    emit(locale);
  }

  /// Convert a Locale to a storage tag string
  String _localeToTag(Locale locale) {
    return (locale.countryCode?.isNotEmpty ?? false)
        ? '${locale.languageCode}-${locale.countryCode}'
        : locale.languageCode;
  }
}
