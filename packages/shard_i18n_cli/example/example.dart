/// Example showing shard_i18n_cli usage.
///
/// The CLI is invoked from the terminal. Common commands:
///
/// ```shell
/// # Verify translation consistency across locales
/// dart run shard_i18n_cli verify --path=assets/i18n
///
/// # Extract i18n keys from source code and compare with JSON
/// dart run shard_i18n_cli extract --path=lib/ --i18n=assets/i18n
///
/// # Auto-fix missing keys in reference locale
/// dart run shard_i18n_cli extract --fix
///
/// # Remove orphaned keys not found in code
/// dart run shard_i18n_cli extract --prune
///
/// # Fill missing translations using OpenAI
/// dart run shard_i18n_cli fill --from=en --to=de,fr --provider=openai --key=$OPENAI_API_KEY
///
/// # Analyze project for migration candidates
/// dart run shard_i18n_cli analyze --path=lib
///
/// # Run interactive migration to shard_i18n
/// dart run shard_i18n_cli migrate --path=lib
///
/// # Preview migration without modifying files
/// dart run shard_i18n_cli migrate --path=lib --dry-run
/// ```
library;
