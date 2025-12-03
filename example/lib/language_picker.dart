import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shard_i18n/shard_i18n.dart';

import 'language_cubit.dart';

/// Language names mapped by locale code
const Map<String, String> _languageNames = {
  'en': 'English',
  'de': 'Deutsch',
  'tr': 'Türkçe',
  'ru': 'Русский',
};

/// Show a modal bottom sheet for selecting the application language.
///
/// Displays all supported locales discovered by ShardI18n with native
/// language names. Updates LanguageCubit when a new language is selected.
///
/// Example:
/// ```dart
/// FloatingActionButton(
///   onPressed: () => showLanguagePicker(context),
///   child: Icon(Icons.language),
/// )
/// ```
Future<void> showLanguagePicker(BuildContext context) async {
  final supported = ShardI18n.instance.supportedLocales;
  final current = context.read<LanguageCubit>().state;

  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (bottomSheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                context.t('Select Language'),
                style: Theme.of(
                  bottomSheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            // Language list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: supported.length,
                itemBuilder: (listContext, index) {
                  final locale = supported[index];
                  final tag = _localeToTag(locale);
                  final languageName =
                      _languageNames[locale.languageCode] ?? tag;
                  final isSelected = current == locale;

                  return ListTile(
                    leading: Icon(
                      Icons.language,
                      color: isSelected
                          ? Theme.of(listContext).colorScheme.primary
                          : Colors.grey,
                    ),
                    title: Text(
                      languageName,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      tag.toUpperCase(),
                      style: Theme.of(listContext).textTheme.bodySmall,
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(listContext).colorScheme.primary,
                          )
                        : null,
                    onTap: () async {
                      // Close bottom sheet
                      Navigator.pop(bottomSheetContext);

                      // Update locale if different
                      if (!isSelected) {
                        await context.read<LanguageCubit>().setLocale(locale);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// Convert a Locale to a display tag
String _localeToTag(Locale locale) {
  return (locale.countryCode?.isNotEmpty ?? false)
      ? '${locale.languageCode}-${locale.countryCode}'
      : locale.languageCode;
}
