#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'package:shard_i18n/cli/src/extract/extract.dart';

const String version = '0.3.0';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Display this help message',
    )
    ..addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Display version information',
    )
    ..addCommand(
      'verify',
      ArgParser()..addOption(
        'path',
        abbr: 'p',
        defaultsTo: 'assets/i18n',
        help: 'Path to i18n assets directory',
      ),
    )
    ..addCommand(
      'fill',
      ArgParser()
        ..addOption('from', defaultsTo: 'en', help: 'Source locale (e.g., en)')
        ..addOption(
          'to',
          help: 'Target locales (comma-separated, e.g., de,tr,fr)',
        )
        ..addOption(
          'provider',
          allowed: ['deepl', 'openai'],
          defaultsTo: 'openai',
          help: 'Translation provider',
        )
        ..addOption('key', help: 'API key for translation provider')
        ..addOption(
          'path',
          abbr: 'p',
          defaultsTo: 'assets/i18n',
          help: 'Path to i18n assets directory',
        )
        ..addFlag(
          'dry-run',
          negatable: false,
          help: 'Show what would be translated without writing files',
        ),
    )
    ..addCommand(
      'extract',
      ArgParser()
        ..addOption(
          'path',
          abbr: 'p',
          defaultsTo: 'lib/',
          help: 'Source directory to scan for i18n usage',
        )
        ..addOption(
          'i18n',
          abbr: 'i',
          defaultsTo: 'assets/i18n',
          help: 'Path to i18n assets directory',
        )
        ..addOption(
          'format',
          abbr: 'f',
          allowed: ['text', 'json', 'diff'],
          defaultsTo: 'text',
          help: 'Output format (text, json, diff)',
        )
        ..addOption(
          'locale',
          abbr: 'l',
          defaultsTo: 'en',
          help: 'Reference locale for comparison',
        )
        ..addFlag(
          'fix',
          negatable: false,
          help: 'Auto-generate missing entries in reference locale JSON',
        )
        ..addFlag(
          'prune',
          negatable: false,
          help: 'Remove orphaned keys from JSON (not found in code)',
        )
        ..addFlag(
          'dry-run',
          negatable: false,
          help:
              'Preview changes without writing files (use with --fix/--prune)',
        )
        ..addFlag(
          'strict',
          negatable: false,
          help: 'Exit with code 1 on any discrepancy (for CI/CD)',
        )
        ..addFlag(
          'verbose',
          abbr: 'v',
          negatable: false,
          help: 'Show detailed per-file breakdown',
        ),
    );

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      printHelp(parser);
      exit(0);
    }

    if (results['version'] as bool) {
      print('shard_i18n CLI v$version');
      exit(0);
    }

    if (results.command == null) {
      print('Error: No command specified.\n');
      printHelp(parser);
      exit(1);
    }

    final command = results.command!;

    switch (command.name) {
      case 'verify':
        await runVerify(command);
        break;
      case 'fill':
        await runFill(command);
        break;
      case 'extract':
        final exitCode = await runExtract(command);
        exit(exitCode);
      default:
        print('Error: Unknown command "${command.name}"');
        exit(1);
    }
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

void printHelp(ArgParser parser) {
  print('''
shard_i18n CLI - Translation management tool

Usage: dart run shard_i18n_cli <command> [arguments]

Commands:
  verify    Verify translation consistency across locales
  fill      Fill missing translations using AI providers
  extract   Extract i18n keys from code and compare with JSON files

Global options:
${parser.usage}

Examples:
  # Verify translations
  dart run shard_i18n_cli verify

  # Fill missing German translations using OpenAI
  dart run shard_i18n_cli fill --from=en --to=de --provider=openai --key=\$OPENAI_API_KEY

  # Fill multiple locales
  dart run shard_i18n_cli fill --from=en --to=de,tr,fr --provider=openai --key=\$OPENAI_API_KEY

  # Extract keys from code and compare with JSON
  dart run shard_i18n_cli extract

  # Extract with JSON output for CI
  dart run shard_i18n_cli extract --format=json --strict

  # Auto-fix missing keys
  dart run shard_i18n_cli extract --fix

  # Preview auto-fix and prune changes
  dart run shard_i18n_cli extract --fix --prune --dry-run

For more information, visit: https://github.com/moinsen-dev/shard_i18n
''');
}

/// Verify command: Check translation consistency
Future<void> runVerify(ArgResults command) async {
  final basePath = command['path'] as String;
  final assetsDir = Directory(basePath);

  if (!assetsDir.existsSync()) {
    print('❌ Error: Directory "$basePath" does not exist');
    exit(1);
  }

  print('🔍 Verifying translations in: $basePath\n');

  // Discover all locales
  final locales = <String>[];
  await for (final entity in assetsDir.list()) {
    if (entity is Directory) {
      final localeName = p.basename(entity.path);
      if (RegExp(r'^[a-z]{2}(-[A-Z]{2})?$').hasMatch(localeName)) {
        locales.add(localeName);
      }
    }
  }

  if (locales.isEmpty) {
    print('❌ No locale directories found in $basePath');
    exit(1);
  }

  print('📁 Found locales: ${locales.join(", ")}\n');

  // Load all translations
  final translations = <String, Map<String, dynamic>>{};
  for (final locale in locales) {
    translations[locale] = await loadLocaleTranslations(basePath, locale);
  }

  // Use first locale as reference (typically 'en')
  final referenceLocale = locales.first;
  final referenceKeys = translations[referenceLocale]!.keys.toSet();

  print(
    '📊 Reference locale: $referenceLocale (${referenceKeys.length} keys)\n',
  );

  var hasErrors = false;

  // Check each locale
  for (final locale in locales.skip(1)) {
    final localeKeys = translations[locale]!.keys.toSet();
    final missing = referenceKeys.difference(localeKeys);
    final extra = localeKeys.difference(referenceKeys);

    print('  $locale:');

    if (missing.isEmpty && extra.isEmpty) {
      print('    ✅ All keys present (${localeKeys.length} keys)');
    } else {
      hasErrors = true;

      if (missing.isNotEmpty) {
        print('    ⚠️  Missing ${missing.length} key(s):');
        for (final key in missing.take(5)) {
          print('       - $key');
        }
        if (missing.length > 5) {
          print('       ... and ${missing.length - 5} more');
        }
      }

      if (extra.isNotEmpty) {
        print('    ⚠️  Extra ${extra.length} key(s):');
        for (final key in extra.take(5)) {
          print('       - $key');
        }
        if (extra.length > 5) {
          print('       ... and ${extra.length - 5} more');
        }
      }
    }

    // Check placeholder parity
    final placeholderErrors = checkPlaceholderParity(
      translations[referenceLocale]!,
      translations[locale]!,
    );

    if (placeholderErrors.isNotEmpty) {
      hasErrors = true;
      print('    ⚠️  Placeholder mismatches:');
      for (final error in placeholderErrors.take(3)) {
        print('       - $error');
      }
      if (placeholderErrors.length > 3) {
        print('       ... and ${placeholderErrors.length - 3} more');
      }
    }

    print('');
  }

  if (hasErrors) {
    print('❌ Verification failed with errors');
    exit(1);
  } else {
    print('✅ All translations verified successfully!');
  }
}

/// Fill command: Translate missing keys using AI
Future<void> runFill(ArgResults command) async {
  final basePath = command['path'] as String;
  final sourceLocale = command['from'] as String;
  final targetLocalesStr = command['to'] as String?;
  final provider = command['provider'] as String;
  final apiKey = command['key'] as String?;
  final dryRun = command['dry-run'] as bool;

  if (targetLocalesStr == null || targetLocalesStr.isEmpty) {
    print('❌ Error: --to parameter is required');
    exit(1);
  }

  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Error: --key parameter is required (API key)');
    exit(1);
  }

  final targetLocales = targetLocalesStr
      .split(',')
      .map((s) => s.trim())
      .toList();
  final assetsDir = Directory(basePath);

  if (!assetsDir.existsSync()) {
    print('❌ Error: Directory "$basePath" does not exist');
    exit(1);
  }

  print('🤖 Filling translations using $provider');
  print('   Source: $sourceLocale');
  print('   Targets: ${targetLocales.join(", ")}');
  if (dryRun) {
    print('   Mode: DRY RUN (no files will be modified)');
  }
  print('');

  // Load source translations
  final sourceTranslations = await loadLocaleTranslations(
    basePath,
    sourceLocale,
  );

  if (sourceTranslations.isEmpty) {
    print('❌ No translations found for source locale: $sourceLocale');
    exit(1);
  }

  // Process each target locale
  for (final targetLocale in targetLocales) {
    print('📝 Processing $targetLocale...');

    final targetTranslations = await loadLocaleTranslations(
      basePath,
      targetLocale,
    );
    final missing = <String, dynamic>{};

    // Find missing keys
    for (final entry in sourceTranslations.entries) {
      if (!targetTranslations.containsKey(entry.key)) {
        missing[entry.key] = entry.value;
      }
    }

    if (missing.isEmpty) {
      print('   ✅ No missing keys\n');
      continue;
    }

    print('   Found ${missing.length} missing key(s)');

    if (!dryRun) {
      // Translate missing keys
      final translated = await translateBatch(
        missing,
        sourceLocale,
        targetLocale,
        provider,
        apiKey,
      );

      // Write translated keys to files
      await writeTranslations(basePath, targetLocale, translated);

      print('   ✅ Added ${translated.length} translation(s)\n');
    } else {
      print(
        '   (DRY RUN) Would translate: ${missing.keys.take(5).join(", ")}${missing.length > 5 ? ", ..." : ""}\n',
      );
    }
  }

  print('✅ Fill operation completed!');
}

/// Load all translation files for a locale
Future<Map<String, dynamic>> loadLocaleTranslations(
  String basePath,
  String locale,
) async {
  final localeDir = Directory(p.join(basePath, locale));
  final merged = <String, dynamic>{};

  if (!localeDir.existsSync()) {
    return merged;
  }

  await for (final entity in localeDir.list()) {
    if (entity is File && entity.path.endsWith('.json')) {
      try {
        final content = await entity.readAsString();
        final Map<String, dynamic> data = json.decode(content);
        merged.addAll(data);
      } catch (e) {
        print('⚠️  Warning: Could not read ${entity.path}: $e');
      }
    }
  }

  return merged;
}

/// Check placeholder parity between reference and target translations
List<String> checkPlaceholderParity(
  Map<String, dynamic> reference,
  Map<String, dynamic> target,
) {
  final errors = <String>[];

  for (final key in reference.keys) {
    if (!target.containsKey(key)) continue;

    final refValue = reference[key];
    final targetValue = target[key];

    if (refValue is String && targetValue is String) {
      final refPlaceholders = extractPlaceholders(refValue);
      final targetPlaceholders = extractPlaceholders(targetValue);

      if (!refPlaceholders.every((p) => targetPlaceholders.contains(p))) {
        errors.add('$key: placeholders mismatch');
      }
    }
  }

  return errors;
}

/// Extract {placeholder} names from a string
Set<String> extractPlaceholders(String text) {
  final pattern = RegExp(r'\{(\w+)\}');
  return pattern.allMatches(text).map((m) => m.group(1)!).toSet();
}

/// Translate a batch of keys using an AI provider
Future<Map<String, dynamic>> translateBatch(
  Map<String, dynamic> keys,
  String sourceLocale,
  String targetLocale,
  String provider,
  String apiKey,
) async {
  final translated = <String, dynamic>{};

  print('   🔄 Translating ${keys.length} key(s)...');

  for (final entry in keys.entries) {
    if (entry.value is String) {
      // Simple string translation
      final translatedText = await translateText(
        entry.value as String,
        sourceLocale,
        targetLocale,
        provider,
        apiKey,
      );
      translated[entry.key] = translatedText;
    } else if (entry.value is Map) {
      // Plural forms - translate each form
      final pluralForms = <String, String>{};
      for (final pluralEntry in (entry.value as Map).entries) {
        final form = pluralEntry.key as String;
        final text = pluralEntry.value as String;
        pluralForms[form] = await translateText(
          text,
          sourceLocale,
          targetLocale,
          provider,
          apiKey,
        );
      }
      translated[entry.key] = pluralForms;
    }

    // Rate limiting
    await Future.delayed(const Duration(milliseconds: 100));
  }

  return translated;
}

/// Translate a single text using the specified provider
Future<String> translateText(
  String text,
  String sourceLocale,
  String targetLocale,
  String provider,
  String apiKey,
) async {
  try {
    switch (provider) {
      case 'openai':
        return await translateWithOpenAI(
          text,
          sourceLocale,
          targetLocale,
          apiKey,
        );
      case 'deepl':
        return await translateWithDeepL(
          text,
          sourceLocale,
          targetLocale,
          apiKey,
        );
      default:
        throw ArgumentError('Unknown provider: $provider');
    }
  } catch (e) {
    print('   ⚠️  Translation error for "$text": $e');
    return text; // Return original on error
  }
}

/// Translate using OpenAI API
Future<String> translateWithOpenAI(
  String text,
  String sourceLocale,
  String targetLocale,
  String apiKey,
) async {
  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: json.encode({
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a professional translator. Translate the given text from $sourceLocale to $targetLocale. '
              'Preserve any {placeholders} exactly as they appear. Return only the translated text without explanations.',
        },
        {'role': 'user', 'content': text},
      ],
      'temperature': 0.3,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(
      'OpenAI API error: ${response.statusCode} ${response.body}',
    );
  }

  final data = json.decode(response.body);
  return data['choices'][0]['message']['content'].trim();
}

/// Translate using DeepL API
Future<String> translateWithDeepL(
  String text,
  String sourceLocale,
  String targetLocale,
  String apiKey,
) async {
  // Convert locale codes to DeepL format (e.g., 'en' -> 'EN', 'de' -> 'DE')
  final sourceLang = sourceLocale.substring(0, 2).toUpperCase();
  final targetLang = targetLocale.substring(0, 2).toUpperCase();

  final response = await http.post(
    Uri.parse('https://api-free.deepl.com/v2/translate'),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'auth_key': apiKey,
      'text': text,
      'source_lang': sourceLang,
      'target_lang': targetLang,
    },
  );

  if (response.statusCode != 200) {
    throw Exception('DeepL API error: ${response.statusCode} ${response.body}');
  }

  final data = json.decode(response.body);
  return data['translations'][0]['text'];
}

/// Write translated keys back to locale files
Future<void> writeTranslations(
  String basePath,
  String locale,
  Map<String, dynamic> translations,
) async {
  // Group translations by feature (would require metadata, for now write to core.json)
  final targetFile = File(p.join(basePath, locale, 'core.json'));

  // Create directory if it doesn't exist
  await targetFile.parent.create(recursive: true);

  // Load existing translations
  Map<String, dynamic> existing = {};
  if (await targetFile.exists()) {
    final content = await targetFile.readAsString();
    existing = json.decode(content);
  }

  // Merge with new translations
  existing.addAll(translations);

  // Write back with pretty formatting
  final encoder = const JsonEncoder.withIndent('  ');
  await targetFile.writeAsString(encoder.convert(existing));
}

/// Extract command: Scan code for i18n keys and compare with JSON
Future<int> runExtract(ArgResults command) async {
  final sourcePath = command['path'] as String;
  final i18nPath = command['i18n'] as String;
  final formatStr = command['format'] as String;
  final locale = command['locale'] as String;
  final fix = command['fix'] as bool;
  final prune = command['prune'] as bool;
  final dryRun = command['dry-run'] as bool;
  final strict = command['strict'] as bool;
  final verbose = command['verbose'] as bool;

  // Validate source path
  final sourceDir = Directory(sourcePath);
  if (!sourceDir.existsSync()) {
    print('Error: Source directory "$sourcePath" does not exist');
    return 1;
  }

  // Validate i18n path
  final i18nDir = Directory(i18nPath);
  if (!i18nDir.existsSync()) {
    print('Error: i18n directory "$i18nPath" does not exist');
    return 1;
  }

  // Parse output format
  final format = switch (formatStr) {
    'json' => OutputFormat.json,
    'diff' => OutputFormat.diff,
    _ => OutputFormat.text,
  };

  // Only show header for text format
  if (format == OutputFormat.text) {
    print('Scanning source files in: $sourcePath');
    print('Comparing with JSON in: $i18nPath/$locale/\n');
  }

  // Find all Dart files
  final dartFiles = await findDartFiles(
    sourcePath,
    exclude: ['generated', '.g.dart', '.freezed.dart'],
  );

  if (dartFiles.isEmpty) {
    print('No Dart files found in $sourcePath');
    return 0;
  }

  // Extract keys from source code
  final extractor = I18nKeyExtractor(
    verbose: verbose,
    onLog: verbose ? print : null,
  );
  final extracted = await extractor.extract(dartFiles);

  // Compare with JSON
  final comparator = JsonComparator(
    i18nPath: i18nPath,
    referenceLocale: locale,
    onLog: verbose ? print : null,
  );

  ComparisonResult comparison;
  try {
    comparison = await comparator.compare(extracted);
  } catch (e) {
    print('Error comparing with JSON: $e');
    return 1;
  }

  // Report results
  final reporter = ExtractReporter.forFormat(format);
  reporter.report(comparison, extracted, verbose: verbose);

  // Handle fix and prune
  if (fix || prune) {
    final fixer = AutoFixer(
      i18nPath: i18nPath,
      referenceLocale: locale,
      dryRun: dryRun,
      onLog: print,
    );

    final result = await fixer.fixAndPrune(
      comparison,
      extracted,
      fix: fix,
      prune: prune,
    );

    if (result.hasChanges) {
      print('');
      if (dryRun) {
        print('[DRY RUN] Would modify ${result.filesModified.length} file(s):');
        print('  Keys to add: ${result.keysAdded}');
        print('  Keys to remove: ${result.keysRemoved}');
      } else {
        print('Modified ${result.filesModified.length} file(s):');
        print('  Keys added: ${result.keysAdded}');
        print('  Keys removed: ${result.keysRemoved}');
      }
    }

    for (final warning in result.warnings) {
      print('Warning: $warning');
    }
  }

  // Return exit code based on strict mode
  if (strict && comparison.hasDiscrepancies) {
    return 1;
  }

  return 0;
}
