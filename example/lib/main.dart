import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shard_i18n/shard_i18n.dart';

import 'language_cubit.dart';
import 'language_picker.dart';
import 'onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load initial locale from SharedPreferences or device default
  final initialLocale = await LanguageCubit.loadInitial();

  // Bootstrap ShardI18n with initial locale (pre-loads translations)
  await ShardI18n.instance.bootstrap(initialLocale);

  runApp(
    BlocProvider(
      create: (_) => LanguageCubit(initialLocale),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch locale changes from LanguageCubit
    final locale = context.watch<LanguageCubit>().state;

    // Wrap MaterialApp in AnimatedBuilder to rebuild when translations change
    return AnimatedBuilder(
      animation: ShardI18n.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'shard_i18n Example',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          // Set current locale
          locale: locale,
          // Provide built-in Flutter localizations (date pickers, etc.)
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Use discovered locales from ShardI18n
          supportedLocales: ShardI18n.instance.supportedLocales,
          home: const HomePage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _itemCount = 0;

  void _incrementCounter() {
    setState(() {
      _itemCount++;
    });
  }

  void _resetCounter() {
    setState(() {
      _itemCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userName = 'World';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Demonstrate msgid translation with interpolation
        title: Text(context.t('Hello, {name}!', params: {'name': userName})),
        actions: [
          // Current locale display
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                ShardI18n.instance.locale.languageCode.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Example card with various translation features
            Card(
              margin: const EdgeInsets.all(24.0),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.translate,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    // Simple translation
                    Text(
                      context.t('Welcome to shard_i18n'),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Translation with description/context
                    Text(
                      context.t('A runtime, sharded i18n solution for Flutter'),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const Divider(height: 32),
                    // Demonstration of pluralization
                    Text(
                      context.tn('items_count', count: _itemCount),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _incrementCounter,
                          icon: const Icon(Icons.add),
                          label: Text(context.t('Add item')),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _itemCount > 0 ? _resetCounter : null,
                          icon: const Icon(Icons.refresh),
                          label: Text(context.t('Reset')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Feature showcase
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('Features'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(icon: Icons.code, text: context.t('No code generation')),
                  _FeatureItem(icon: Icons.folder, text: context.t('Sharded translations')),
                  _FeatureItem(icon: Icons.language, text: context.t('Dynamic locale switching')),
                  _FeatureItem(icon: Icons.text_fields, text: context.t('Msgid-based lookups')),
                  const SizedBox(height: 16),
                  // Learn More button
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      label: Text(context.t('Learn More')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLanguagePicker(context),
        icon: const Icon(Icons.language),
        label: Text(context.t('Change Language')),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
