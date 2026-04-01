// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:shard_i18n/shard_i18n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bootstrap with initial locale before runApp
  await ShardI18n.instance.bootstrap(const Locale('en'));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild when locale changes
    return AnimatedBuilder(
      animation: ShardI18n.instance,
      builder: (context, _) {
        return MaterialApp(
          locale: ShardI18n.instance.locale,
          supportedLocales: ShardI18n.instance.supportedLocales,
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Simple translation via context extension
        title: Text(context.t('Hello, {name}!', params: {'name': 'World'})),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pluralization
            Text(context.tn('items_count', count: 5)),

            // String extensions (no context needed)
            Text('Welcome'.tx),
            Text('Hello, {name}!'.t({'name': 'Flutter'})),
            Text('items_count'.tn(count: 1)),

            // Switch locale at runtime
            ElevatedButton(
              onPressed: () async {
                await ShardI18n.instance.setLocale(const Locale('de'));
              },
              child: Text(context.t('Switch to German')),
            ),
          ],
        ),
      ),
    );
  }
}
