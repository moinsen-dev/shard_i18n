# BLoC Integration

This guide shows how to integrate shard_i18n with the BLoC pattern for state management.

## Overview

While shard_i18n works standalone with `AnimatedBuilder`, integrating with BLoC provides:

- Centralized locale state management
- Easy testing of locale changes
- Consistent state architecture across your app
- Better separation of concerns

## Setup

### 1. Add Dependencies

```yaml
dependencies:
  shard_i18n: ^0.3.0
  flutter_bloc: ^8.1.0
  equatable: ^2.0.5
```

### 2. Create Language State

```dart
// lib/bloc/language/language_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class LanguageState extends Equatable {
  final Locale locale;
  final bool isLoading;

  const LanguageState({
    required this.locale,
    this.isLoading = false,
  });

  factory LanguageState.initial() => const LanguageState(
        locale: Locale('en'),
      );

  LanguageState copyWith({
    Locale? locale,
    bool? isLoading,
  }) {
    return LanguageState(
      locale: locale ?? this.locale,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [locale, isLoading];
}
```

### 3. Create Language Cubit

```dart
// lib/bloc/language/language_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shard_i18n/shard_i18n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'language_state.dart';

class LanguageCubit extends Cubit<LanguageState> {
  static const _localeKey = 'app_locale';

  LanguageCubit() : super(LanguageState.initial());

  /// Initialize with saved or system locale
  Future<void> init() async {
    emit(state.copyWith(isLoading: true));

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);

      Locale locale;
      if (savedLocale != null) {
        locale = Locale(savedLocale);
      } else {
        // Use system locale if supported
        final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
        locale = _getSupportedLocale(systemLocale);
      }

      await ShardI18n.instance.setLocale(locale);
      emit(state.copyWith(locale: locale, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Change the current locale
  Future<void> changeLocale(Locale newLocale) async {
    if (state.locale == newLocale) return;

    emit(state.copyWith(isLoading: true));

    try {
      await ShardI18n.instance.setLocale(newLocale);

      // Persist selection
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, newLocale.languageCode);

      emit(state.copyWith(locale: newLocale, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Get supported locale or fallback to default
  Locale _getSupportedLocale(Locale systemLocale) {
    final supported = ShardI18n.instance.supportedLocales;
    final match = supported.firstWhere(
      (l) => l.languageCode == systemLocale.languageCode,
      orElse: () => const Locale('en'),
    );
    return match;
  }

  /// List of available locales for UI
  List<Locale> get availableLocales => ShardI18n.instance.supportedLocales;
}
```

### 4. Setup App

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shard_i18n/shard_i18n.dart';

import 'bloc/language/language_cubit.dart';
import 'bloc/language/language_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shard_i18n
  await ShardI18n.instance.init(
    supportedLocales: [
      const Locale('en'),
      const Locale('de'),
      const Locale('fr'),
    ],
    defaultLocale: const Locale('en'),
    basePath: 'assets/i18n',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LanguageCubit()..init(),
      child: BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, state) {
          return MaterialApp(
            locale: state.locale,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
```

## Usage

### Access Translations

Translations work the same way:

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('Home')),
      ),
      body: Center(
        child: Text(context.t('Welcome to our app!')),
      ),
    );
  }
}
```

### Change Locale

Use the cubit to change locale:

```dart
class LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LanguageCubit>();
    final state = context.watch<LanguageCubit>().state;

    return DropdownButton<Locale>(
      value: state.locale,
      items: cubit.availableLocales.map((locale) {
        return DropdownMenuItem(
          value: locale,
          child: Text(_getLanguageName(locale)),
        );
      }).toList(),
      onChanged: (locale) {
        if (locale != null) {
          cubit.changeLocale(locale);
        }
      },
    );
  }

  String _getLanguageName(Locale locale) {
    return switch (locale.languageCode) {
      'en' => 'English',
      'de' => 'Deutsch',
      'fr' => 'Français',
      _ => locale.languageCode,
    };
  }
}
```

### Show Loading State

```dart
BlocBuilder<LanguageCubit, LanguageState>(
  builder: (context, state) {
    if (state.isLoading) {
      return const CircularProgressIndicator();
    }
    return Text(context.t('Content loaded'));
  },
)
```

## Advanced Patterns

### Multiple Cubits

If you have multiple feature cubits, inject LanguageCubit at the root:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => LanguageCubit()..init()),
    BlocProvider(create: (_) => AuthCubit()),
    BlocProvider(create: (_) => ThemeCubit()),
  ],
  child: MyApp(),
)
```

### Locale-Aware Formatting

Create a formatting cubit that depends on locale:

```dart
class FormattingCubit extends Cubit<FormattingState> {
  final LanguageCubit languageCubit;
  late StreamSubscription _subscription;

  FormattingCubit(this.languageCubit) : super(FormattingState.initial()) {
    _subscription = languageCubit.stream.listen((langState) {
      _updateFormatters(langState.locale);
    });
  }

  void _updateFormatters(Locale locale) {
    emit(state.copyWith(
      dateFormat: DateFormat.yMMMd(locale.languageCode),
      numberFormat: NumberFormat.decimalPattern(locale.languageCode),
    ));
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
```

### Listening to Changes

React to locale changes in other cubits:

```dart
class ContentCubit extends Cubit<ContentState> {
  final LanguageCubit languageCubit;

  ContentCubit(this.languageCubit) : super(ContentState.initial()) {
    languageCubit.stream.listen((langState) {
      // Reload content for new locale
      loadContent(langState.locale);
    });
  }

  Future<void> loadContent(Locale locale) async {
    // Load locale-specific content from API
  }
}
```

## Testing

### Unit Testing the Cubit

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockShardI18n extends Mock implements ShardI18n {}

void main() {
  group('LanguageCubit', () {
    late LanguageCubit cubit;

    setUp(() {
      cubit = LanguageCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is English', () {
      expect(cubit.state.locale, const Locale('en'));
    });

    blocTest<LanguageCubit, LanguageState>(
      'emits new locale when changeLocale called',
      build: () => cubit,
      act: (cubit) => cubit.changeLocale(const Locale('de')),
      expect: () => [
        const LanguageState(locale: Locale('en'), isLoading: true),
        const LanguageState(locale: Locale('de'), isLoading: false),
      ],
    );
  });
}
```

### Widget Testing

```dart
testWidgets('displays translated text', (tester) async {
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => LanguageCubit(),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Text(context.t('Hello!')),
          ),
        ),
      ),
    ),
  );

  expect(find.text('Hello!'), findsOneWidget);
});
```

## Best Practices

### 1. Initialize Early

Initialize shard_i18n before creating the cubit:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ShardI18n.instance.init(...);  // First
  runApp(MyApp());  // Cubit created inside
}
```

### 2. Persist User Choice

Always save the user's locale preference:

```dart
await prefs.setString(_localeKey, newLocale.languageCode);
```

### 3. Handle Loading States

Show loading indicators during locale switches:

```dart
if (state.isLoading) {
  return const LoadingOverlay();
}
```

### 4. Avoid Direct ShardI18n Access

Use the cubit for all locale changes:

```dart
// ✓ Good
context.read<LanguageCubit>().changeLocale(locale);

// ✗ Avoid - bypasses state management
ShardI18n.instance.setLocale(locale);
```

## Example Repository

See the complete BLoC integration example:
- [example/lib/bloc/](https://github.com/moinsen-dev/shard_i18n/tree/develop/example/lib/bloc)
