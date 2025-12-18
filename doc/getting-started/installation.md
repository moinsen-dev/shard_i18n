# Installation

## Add Dependency

Add shard_i18n to your `pubspec.yaml`:

```yaml
dependencies:
  shard_i18n: ^0.3.0
```

Then run:

```bash
flutter pub get
```

## Configure Assets

Add the i18n assets directory to your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/i18n/en/
    - assets/i18n/de/
    # Add more locales as needed
```

## Create Translation Files

Create your translation files in the `assets/i18n/` directory:

```
assets/
  i18n/
    en/
      core.json       # App-wide strings
      auth.json       # Authentication feature
      settings.json   # Settings feature
    de/
      core.json
      auth.json
      settings.json
```

Example `assets/i18n/en/core.json`:

```json
{
  "Welcome": "Welcome",
  "Hello, {name}!": "Hello, {name}!",
  "items_count": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

## Optional Dependencies

For state management integration, you may want to add:

```yaml
dependencies:
  flutter_bloc: ^8.1.0        # For BLoC/Cubit pattern
  shared_preferences: ^2.0.0  # For persisting language choice
```

## CLI Tools

The CLI tools are included in the package. You can run them via:

```bash
# Verify translations
dart run shard_i18n_cli verify

# Extract keys from code
dart run shard_i18n_cli extract

# Fill missing translations with AI
dart run shard_i18n_cli fill --from=en --to=de --provider=openai --key=$OPENAI_API_KEY
```

## Next Steps

Continue to [Quick Start](quick-start.md) to set up your app.
