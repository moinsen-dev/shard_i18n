# Sharded Files

shard_i18n organizes translations into **sharded** JSON files by feature, preventing merge conflicts in team environments.

## The Problem

With a single translation file per locale:

```
assets/i18n/
  en.json     # 500+ keys
  de.json
```

**Problems:**
- Multiple developers editing the same file = merge conflicts
- Large files are hard to navigate
- No clear ownership of translations

## The Solution

Shard translations by feature:

```
assets/i18n/
  en/
    core.json        # App-wide strings (welcome, buttons)
    auth.json        # Login, signup, password
    settings.json    # Preferences, account
    checkout.json    # Cart, payment, orders
  de/
    core.json
    auth.json
    settings.json
    checkout.json
```

**Benefits:**
- Each feature team owns their translations
- Parallel development without conflicts
- Easier to find and update translations
- Smaller, focused files

## Directory Structure

### Basic Structure

```
assets/
  i18n/
    en/                    # English (source locale)
      core.json            # App-wide strings
      auth.json            # Authentication
    de/                    # German
      core.json
      auth.json
    fr/                    # French
      core.json
      auth.json
```

### Feature-Based Sharding

Align shards with your app's feature structure:

```
lib/
  features/
    auth/
    checkout/
    profile/
    settings/

assets/
  i18n/
    en/
      auth.json        # Maps to lib/features/auth/
      checkout.json    # Maps to lib/features/checkout/
      profile.json     # Maps to lib/features/profile/
      settings.json    # Maps to lib/features/settings/
      core.json        # Shared/common strings
```

### Module-Based Sharding

For larger apps with modules:

```
assets/
  i18n/
    en/
      core.json              # Shared across modules
      onboarding.json        # Onboarding module
      dashboard.json         # Dashboard module
      reporting.json         # Reporting module
      admin.json             # Admin module
```

## JSON File Format

Each shard is a flat JSON object:

```json
{
  "Sign in": "Sign in",
  "Sign up": "Sign up",
  "Forgot password?": "Forgot password?",
  "Email": "Email",
  "Password": "Password",
  "Remember me": "Remember me"
}
```

Plurals use nested objects:

```json
{
  "items_count": {
    "one": "{count} item",
    "other": "{count} items"
  }
}
```

## Loading Behavior

shard_i18n automatically:

1. Discovers all `.json` files in the locale directory
2. Merges them into a single translation dictionary
3. Handles key collisions (last file wins)

```dart
// All of these work, regardless of which shard contains the key:
context.t('Sign in')         // From auth.json
context.t('Settings')        // From settings.json
context.t('Welcome')         // From core.json
```

## Naming Conventions

### File Naming

Use lowercase with underscores or hyphens:

```
Good:
  auth.json
  user_profile.json
  checkout-flow.json

Avoid:
  Auth.json
  UserProfile.json
  CHECKOUT.json
```

### Key Naming

Within shards, use consistent key naming:

```json
{
  "Sign in": "Sign in",
  "sign_in_button": "Sign In",
  "auth.sign_in": "Sign In"
}
```

Pick one style and stick to it.

## Best Practices

### 1. Keep core.json Small

Only include truly shared strings:

```json
{
  "OK": "OK",
  "Cancel": "Cancel",
  "Save": "Save",
  "Delete": "Delete",
  "Loading...": "Loading...",
  "Error": "Error"
}
```

### 2. One Shard Per Feature

```
auth.json       → Login, signup, password reset
profile.json    → User profile, avatar, bio
settings.json   → Preferences, notifications
```

### 3. Don't Over-Shard

Too many small files create overhead:

```
Bad:
  login-button.json
  login-form.json
  login-errors.json

Good:
  auth.json  # Contains all auth-related strings
```

### 4. Document Ownership

Add comments or maintain a mapping:

```yaml
# TRANSLATIONS.yaml
auth.json: "@auth-team"
checkout.json: "@commerce-team"
settings.json: "@platform-team"
core.json: "@all"
```

## Asset Configuration

Register all shards in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/i18n/en/
    - assets/i18n/de/
    - assets/i18n/fr/
```

The trailing `/` includes all files in the directory.

## Migration from Single File

1. Create feature directories
2. Split the large file by feature
3. Update `pubspec.yaml`
4. Test thoroughly

The CLI can help identify which keys belong to which feature based on usage in code.
