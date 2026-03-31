# shard_i18n_cli

CLI tools for [shard_i18n](https://pub.dev/packages/shard_i18n) — verify, fill, extract, and migrate translations.

## Commands

```bash
dart run shard_i18n_cli verify          # Check translation consistency
dart run shard_i18n_cli fill            # Auto-translate missing keys (OpenAI/DeepL)
dart run shard_i18n_cli extract         # Extract i18n keys from code, compare with JSON
dart run shard_i18n_cli analyze lib/    # Analyze project for migration
dart run shard_i18n_cli migrate lib/    # Migrate project to shard_i18n
dart run shard_i18n_cli init            # Create migration config file
```

See the [main package documentation](https://github.com/moinsen-dev/shard_i18n) for full usage details.
