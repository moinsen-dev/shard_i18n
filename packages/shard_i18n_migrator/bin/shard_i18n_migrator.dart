#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:args/args.dart';
import 'package:shard_i18n_migrator/shard_i18n_migrator.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('analyze')
    ..addCommand('migrate')
    ..addCommand('init');

  // Add global flags
  parser.addFlag(
    'help',
    abbr: 'h',
    negatable: false,
    help: 'Show usage information',
  );

  parser.addFlag(
    'verbose',
    abbr: 'v',
    negatable: false,
    help: 'Show verbose output',
  );

  // Analyze command options
  parser.commands['analyze']!.addOption(
    'path',
    abbr: 'p',
    defaultsTo: 'lib',
    help: 'Path to analyze (default: lib)',
  );

  // Migrate command options
  parser.commands['migrate']!
    ..addOption(
      'path',
      abbr: 'p',
      defaultsTo: 'lib',
      help: 'Path to migrate (default: lib)',
    )
    ..addFlag(
      'dry-run',
      negatable: false,
      help: 'Preview changes without modifying files',
    )
    ..addFlag(
      'auto',
      negatable: false,
      help: 'Non-interactive mode using config file',
    )
    ..addOption(
      'config',
      abbr: 'c',
      defaultsTo: 'migration_config.yaml',
      help: 'Path to configuration file',
    );

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool || results.command == null) {
      _printUsage(parser);
      exit(0);
    }

    final verbose = results['verbose'] as bool;
    final command = results.command!;

    switch (command.name) {
      case 'analyze':
        await _handleAnalyze(command, verbose);
        break;
      case 'migrate':
        await _handleMigrate(command, verbose);
        break;
      case 'init':
        await _handleInit(command, verbose);
        break;
      default:
        print('Unknown command: ${command.name}');
        _printUsage(parser);
        exit(1);
    }
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

Future<void> _handleAnalyze(ArgResults command, bool verbose) async {
  final path = command['path'] as String;
  print('Analyzing project at: $path');
  print('');

  final migrator = ShardI18nMigrator(verbose: verbose);
  final analysis = await migrator.analyze(path);

  print('Analysis Results:');
  print('─' * 60);
  print('Total string literals found: ${analysis.totalStrings}');
  print('Extractable UI strings: ${analysis.extractableStrings}');
  print('Technical/code strings: ${analysis.technicalStrings}');
  print('Ambiguous strings (require review): ${analysis.ambiguousStrings}');
  print('');
  print('Interpolation patterns detected: ${analysis.interpolationCount}');
  print('Plural patterns detected: ${analysis.pluralCount}');
  print('');
  print(
      'Average confidence score: ${analysis.averageConfidence.toStringAsFixed(1)}%');
  print('─' * 60);
  print('');

  if (analysis.ambiguousStrings > 0) {
    print('Run "shard_i18n_migrator migrate $path" for interactive migration');
  } else {
    print(
        'Run "shard_i18n_migrator migrate $path --auto" for automatic migration');
  }
}

Future<void> _handleMigrate(ArgResults command, bool verbose) async {
  final path = command['path'] as String;
  final dryRun = command['dry-run'] as bool;
  final auto = command['auto'] as bool;
  final configPath = command['config'] as String;

  print('${dryRun ? "Previewing" : "Starting"} migration for: $path');
  print('Mode: ${auto ? "Automatic" : "Interactive"}');
  if (dryRun) {
    print('DRY RUN - No files will be modified');
  }
  print('');

  final migrator = ShardI18nMigrator(verbose: verbose);

  MigrationConfig? config;
  if (File(configPath).existsSync()) {
    config = await MigrationConfig.load(configPath);
    print('Loaded configuration from: $configPath');
    print('');
  }

  final result = await migrator.migrate(
    path,
    config: config,
    dryRun: dryRun,
    interactive: !auto,
  );

  print('');
  print('Migration ${dryRun ? "Preview" : "Complete"}!');
  print('─' * 60);
  print('Files created:');
  for (final file in result.createdFiles) {
    print('  ✓ $file');
  }
  print('');
  print('Files modified:');
  for (final file in result.modifiedFiles) {
    print('  ✓ $file');
  }
  print('');
  print('Strings extracted: ${result.stringsExtracted}');
  print('JSON keys generated: ${result.jsonKeysGenerated}');
  print('─' * 60);

  if (!dryRun) {
    print('');
    print('Next steps:');
    print('1. Run: flutter pub get');
    print('2. Test: flutter run');
    print('3. Verify: dart run shard_i18n_cli verify');
    print('4. Translate: dart run shard_i18n_cli fill --to=de,fr,es');
  }
}

Future<void> _handleInit(ArgResults command, bool verbose) async {
  const configPath = 'migration_config.yaml';

  if (File(configPath).existsSync()) {
    print('Configuration file already exists: $configPath');
    print('Delete it first if you want to regenerate.');
    exit(1);
  }

  final config = MigrationConfig.createDefault();
  await config.save(configPath);

  print('Created configuration file: $configPath');
  print('');
  print('Edit this file to customize the migration process.');
  print('Then run: shard_i18n_migrator migrate');
}

void _printUsage(ArgParser parser) {
  print('Shard I18n Migrator - Automated Flutter app internationalization');
  print('');
  print('Usage: shard_i18n_migrator <command> [options]');
  print('');
  print('Commands:');
  print('  analyze    Analyze project and show migration preview');
  print('  migrate    Migrate project to use shard_i18n');
  print('  init       Create default migration configuration file');
  print('');
  print('Global options:');
  print(parser.usage);
}
