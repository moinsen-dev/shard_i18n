# shard_i18n

> Runtime, sharded, msgid-based internationalization for Flutter - no code generation required

**shard_i18n** is a production-ready i18n library for Flutter that provides:

- **Direct msgid usage** - Use natural English text directly in code: `context.t('Sign in')`
- **Sharded JSON files** - Organize translations by feature to prevent merge conflicts
- **Dynamic language switching** - Change language at runtime without app restart
- **CLDR-based pluralization** - Support for 25+ languages with proper plural forms
- **Interpolation** - Named parameters with `{placeholder}` syntax
- **Locale fallback chain** - Automatic fallback: `de-DE` → `de` → `en` → msgid

## Why shard_i18n?

| Feature | shard_i18n | gen_l10n | easy_localization |
|---------|------------|----------|-------------------|
| Code generation | None | Required | Optional |
| Merge conflicts | Minimal (sharded) | High | High |
| Runtime switching | Yes | No | Yes |
| Msgid-based | Yes | No | Optional |
| Plural rules | 25+ languages | Manual | 3rd party |
| CLI tools | Yes | No | No |

## Quick Example

```dart
// In your widget
Text(context.t('Hello, {name}!', params: {'name': 'World'}))

// Plurals
Text(context.tn('items_count', count: 5))

// String extensions (no context needed)
Text('Sign in'.tx)
```

## Getting Started

Ready to get started? Check out the [Installation Guide](getting-started/installation.md).

## CLI Tools

shard_i18n includes powerful CLI tools:

- **verify** - Check translation consistency across locales
- **fill** - Auto-translate missing keys using AI (OpenAI, DeepL)
- **extract** - Scan code for i18n usage and compare with JSON files

## Links

- [GitHub Repository](https://github.com/moinsen-dev/shard_i18n)
- [pub.dev Package](https://pub.dev/packages/shard_i18n)
- [Issue Tracker](https://github.com/moinsen-dev/shard_i18n/issues)
