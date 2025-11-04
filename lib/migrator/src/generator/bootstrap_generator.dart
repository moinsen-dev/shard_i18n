import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../config/migration_config.dart';

/// Generates bootstrap code and configuration
class BootstrapGenerator {
  final MigrationConfig config;
  final bool verbose;
  late final Logger _logger;

  final List<String> createdFiles = [];
  final List<String> modifiedFiles = [];

  BootstrapGenerator({
    required this.config,
    required this.verbose,
  }) {
    _logger = Logger(
      printer: SimplePrinter(colors: false),
      level: verbose ? Level.debug : Level.info,
    );
  }

  /// Generate bootstrap code and update configuration
  Future<void> generate({
    required String projectPath,
    required bool dryRun,
  }) async {
    _log('Generating bootstrap code');

    // 1. Update pubspec.yaml
    await _updatePubspec(projectPath, dryRun);

    // 2. Generate LanguageCubit
    await _generateLanguageCubit(projectPath, dryRun);

    // 3. Update main.dart
    await _updateMainDart(projectPath, dryRun);
  }

  Future<void> _updatePubspec(String projectPath, bool dryRun) async {
    final pubspecPath = path.join(projectPath, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);

    if (!pubspecFile.existsSync()) {
      _log('Warning: pubspec.yaml not found');
      return;
    }

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content) as Map;

    // Check if shard_i18n is already in dependencies
    final dependencies = yaml['dependencies'] as Map? ?? {};
    if (dependencies.containsKey('shard_i18n')) {
      _log('shard_i18n already in dependencies');
      return;
    }

    // Prepare updates
    final updates = StringBuffer(content);

    // Add shard_i18n dependency (simple approach: append to dependencies section)
    if (!content.contains('shard_i18n:')) {
      // Find dependencies section and add shard_i18n
      final dependenciesIndex = content.indexOf('dependencies:');
      if (dependenciesIndex != -1) {
        // Find next section or end of dependencies
        final nextLine = content.indexOf('\n', dependenciesIndex);
        updates.clear();
        updates.write(content.substring(0, nextLine + 1));
        updates.writeln('  shard_i18n: ^0.1.0  # Added by migrator');
        updates.write(content.substring(nextLine + 1));
      }
    }

    // Add assets
    if (!content.contains('assets/i18n/')) {
      // Find flutter section
      if (!content.contains('flutter:')) {
        updates.writeln();
        updates.writeln('flutter:');
        updates.writeln('  assets:');
        updates.writeln('    - assets/i18n/${config.sourceLocale}/');
      } else {
        // Add to existing flutter section
        final flutterIndex = content.indexOf('flutter:');
        if (!content.contains('assets:', flutterIndex)) {
          final nextLine = content.indexOf('\n', flutterIndex);
          updates.clear();
          updates.write(content.substring(0, nextLine + 1));
          updates.writeln('  assets:');
          updates.writeln('    - assets/i18n/${config.sourceLocale}/');
          updates.write(content.substring(nextLine + 1));
        }
      }
    }

    if (dryRun) {
      _log('Would update: $pubspecPath');
    } else {
      await pubspecFile.writeAsString(updates.toString());
      _log('Updated: $pubspecPath');
      modifiedFiles.add(pubspecPath);
    }
  }

  Future<void> _generateLanguageCubit(String projectPath, bool dryRun) async {
    final cubitPath = path.join(projectPath, 'lib', 'language_cubit.dart');
    final cubitFile = File(cubitPath);

    if (cubitFile.existsSync()) {
      _log('LanguageCubit already exists, skipping');
      return;
    }

    final content = _languageCubitTemplate();

    if (dryRun) {
      _log('Would create: $cubitPath');
    } else {
      await cubitFile.writeAsString(content);
      _log('Created: $cubitPath');
      createdFiles.add(cubitPath);
    }
  }

  String _languageCubitTemplate() {
    return '''import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shard_i18n/shard_i18n.dart';

/// Cubit for managing app language/locale state
class LanguageCubit extends Cubit<Locale> {
  static const String _storageKey = 'selected_locale';

  LanguageCubit(super.initialLocale);

  /// Load initial locale from storage
  static Future<Locale> loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final localeTag = prefs.getString(_storageKey);

    if (localeTag != null) {
      final parts = localeTag.split('_');
      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      } else {
        return Locale(parts[0]);
      }
    }

    // Default to English
    return const Locale('en');
  }

  /// Change the app language
  Future<void> changeLanguage(Locale locale) async {
    // Switch locale in ShardI18n
    await ShardI18n.instance.switchLocale(locale);

    // Save to storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, locale.toString());

    // Emit new state
    emit(locale);
  }
}
''';
  }

  Future<void> _updateMainDart(String projectPath, bool dryRun) async {
    final mainPath = path.join(projectPath, 'lib', 'main.dart');
    final mainFile = File(mainPath);

    if (!mainFile.existsSync()) {
      _log('Warning: lib/main.dart not found');
      return;
    }

    final content = await mainFile.readAsString();

    // Check if already initialized
    if (content.contains('ShardI18n.init') || content.contains('shard_i18n')) {
      _log('main.dart already has shard_i18n initialization, skipping');
      return;
    }

    _log('Note: main.dart needs manual updates for shard_i18n initialization');
    _log('Please refer to the shard_i18n documentation for setup instructions');
    _log('Required changes:');
    _log('  1. Add ShardI18n.init() in main()');
    _log('  2. Wrap app with BlocProvider<LanguageCubit>');
    _log('  3. Add BlocBuilder to react to locale changes');

    // For now, we don't auto-modify main.dart as it's too complex
    // and could break the user's existing setup
  }

  void _log(String message) {
    _logger.i(message);
  }
}
