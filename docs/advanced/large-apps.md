# Large Application Guide

This guide covers strategies for using shard_i18n in large-scale Flutter applications.

## Scaling Challenges

Large apps face unique i18n challenges:

| Challenge | Impact | Solution |
|-----------|--------|----------|
| Many translation keys | Memory, load time | Sharding |
| Multiple teams | Merge conflicts | Feature-based shards |
| Many locales | Bundle size, sync | CI automation |
| Dynamic content | Runtime updates | API integration |
| White-labeling | Multiple brands | Multi-tenant setup |

## Project Structure

### Monorepo with Packages

```
my_app/
├── packages/
│   ├── core/
│   │   └── assets/i18n/
│   │       └── en/core.json
│   ├── auth/
│   │   └── assets/i18n/
│   │       └── en/auth.json
│   ├── payments/
│   │   └── assets/i18n/
│   │       └── en/payments.json
│   └── shared_ui/
│       └── assets/i18n/
│           └── en/ui.json
└── app/
    └── lib/main.dart
```

### Feature-Based Structure

```
lib/
├── features/
│   ├── auth/
│   │   ├── i18n/
│   │   │   └── auth_keys.dart
│   │   └── presentation/
│   ├── home/
│   │   ├── i18n/
│   │   │   └── home_keys.dart
│   │   └── presentation/
│   └── settings/
│       ├── i18n/
│       │   └── settings_keys.dart
│       └── presentation/
└── assets/i18n/
    ├── en/
    │   ├── core.json
    │   ├── auth.json
    │   ├── home.json
    │   └── settings.json
    └── de/...
```

## Team Workflow

### Assigning Ownership

Each team owns their translation files:

```yaml
# CODEOWNERS
assets/i18n/*/auth.json    @auth-team
assets/i18n/*/payments.json @payments-team
assets/i18n/*/home.json    @home-team
assets/i18n/*/core.json    @platform-team
```

### Preventing Merge Conflicts

1. **Separate files per team**: No shared JSON files
2. **Key prefixes**: `auth.login.title` vs `home.welcome.title`
3. **Automated sorting**: Sort keys alphabetically in CI

```bash
# Sort JSON keys alphabetically
jq -S '.' assets/i18n/en/auth.json > temp.json && mv temp.json assets/i18n/en/auth.json
```

### Pull Request Workflow

```yaml
# .github/workflows/i18n-pr.yml
name: i18n PR Check

on: pull_request

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check only owned files changed
        run: |
          CHANGED=$(git diff --name-only origin/main)
          # Verify team ownership based on CODEOWNERS

      - name: Validate JSON format
        run: |
          for file in $(find assets/i18n -name "*.json"); do
            jq . "$file" > /dev/null || exit 1
          done

      - name: Check for key collisions
        run: dart run shard_i18n_cli extract --strict
```

## Key Management

### Key Constants per Feature

```dart
// lib/features/auth/i18n/auth_keys.dart
abstract class AuthKeys {
  static const login = 'Sign In';
  static const logout = 'Sign Out';
  static const email = 'Email';
  static const password = 'Password';
  static const forgotPassword = 'Forgot Password?';
  static const signUp = 'Create Account';
}

// Usage
Text(context.t(AuthKeys.login));
```

### Generated Key Classes

For large projects, generate key classes from JSON:

```bash
# generate_keys.dart
dart run tool/generate_keys.dart
```

```dart
// Generated: lib/generated/l10n_keys.g.dart
abstract class L10nKeys {
  // From core.json
  static const ok = 'OK';
  static const cancel = 'Cancel';

  // From auth.json
  static const authLogin = 'Sign In';
  static const authLogout = 'Sign Out';
}
```

### Key Naming Convention

```
[feature].[screen].[element].[state]

Examples:
auth.login.button.default
auth.login.button.loading
auth.login.error.invalidEmail
home.feed.empty.title
home.feed.empty.description
```

## Multi-Tenant / White-Label

### Brand-Specific Translations

```
assets/i18n/
├── base/
│   └── en/core.json
├── brand_a/
│   └── en/core.json  # Overrides
└── brand_b/
    └── en/core.json  # Overrides
```

```dart
void main() async {
  final brand = getBrandFromConfig(); // 'brand_a'

  await ShardI18n.instance.init(
    basePath: 'assets/i18n/$brand',
    fallbackPath: 'assets/i18n/base', // Fallback to base
  );
}
```

### Runtime Brand Switching

```dart
class BrandManager {
  Future<void> switchBrand(String brandId) async {
    await ShardI18n.instance.reloadFromPath(
      'assets/i18n/$brandId',
    );
  }
}
```

## Modular Loading

### Lazy Module Loading

```dart
// Feature module that loads its own translations
class PaymentsModule {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    await ShardI18n.instance.loadShard('payments');
    _initialized = true;
  }
}

// Usage in router
GoRoute(
  path: '/payments',
  builder: (context, state) {
    return FutureBuilder(
      future: PaymentsModule.ensureInitialized(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingScreen();
        }
        return const PaymentsScreen();
      },
    );
  },
)
```

### Deferred Loading with Code Splitting

```dart
import 'package:my_app/features/analytics/analytics_module.dart'
    deferred as analytics;

Future<void> loadAnalytics() async {
  await analytics.loadLibrary();
  await ShardI18n.instance.loadShard('analytics');
}
```

## Remote Translations

### Fetch from API

```dart
class RemoteTranslationLoader {
  final ApiClient _client;

  Future<void> loadRemoteTranslations(Locale locale) async {
    final translations = await _client.getTranslations(
      locale: locale.languageCode,
      version: appVersion,
    );

    await ShardI18n.instance.loadFromMap(
      locale,
      translations,
    );
  }
}
```

### Caching Strategy

```dart
class CachedTranslationLoader {
  final SharedPreferences _prefs;
  final ApiClient _client;

  Future<void> loadTranslations(Locale locale) async {
    // Try cache first
    final cached = _prefs.getString('translations_${locale.languageCode}');
    if (cached != null) {
      final data = json.decode(cached);
      await ShardI18n.instance.loadFromMap(locale, data);
    }

    // Fetch updates in background
    _fetchAndCache(locale);
  }

  Future<void> _fetchAndCache(Locale locale) async {
    try {
      final data = await _client.getTranslations(locale.languageCode);
      await _prefs.setString(
        'translations_${locale.languageCode}',
        json.encode(data),
      );
      await ShardI18n.instance.loadFromMap(locale, data);
    } catch (e) {
      // Use cached version on failure
    }
  }
}
```

## CI/CD for Large Projects

### Matrix Testing

```yaml
jobs:
  i18n:
    strategy:
      matrix:
        locale: [en, de, fr, es, ja, zh]
    runs-on: ubuntu-latest
    steps:
      - name: Verify locale ${{ matrix.locale }}
        run: |
          dart run shard_i18n_cli verify --locale=${{ matrix.locale }}
```

### Automated Translation Sync

```yaml
name: Translation Sync

on:
  push:
    paths:
      - 'assets/i18n/en/**'

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Translate to all locales
        run: |
          for locale in de fr es ja zh ko; do
            dart run shard_i18n_cli fill \
              --from=en \
              --to=$locale \
              --provider=openai \
              --key=${{ secrets.OPENAI_API_KEY }}
          done

      - name: Create PR
        uses: peter-evans/create-pull-request@v5
        with:
          title: 'chore(i18n): sync translations'
          branch: i18n-sync
```

### Translation Coverage Dashboard

```yaml
- name: Generate coverage report
  run: |
    dart run shard_i18n_cli extract --format=json > coverage.json

- name: Upload to dashboard
  run: |
    curl -X POST https://dashboard.example.com/i18n \
      -H "Authorization: Bearer $TOKEN" \
      -d @coverage.json
```

## Testing at Scale

### Parameterized Locale Tests

```dart
void main() {
  final testLocales = ['en', 'de', 'fr', 'es', 'ja', 'zh'];

  for (final localeCode in testLocales) {
    group('Locale: $localeCode', () {
      setUpAll(() async {
        await ShardI18n.instance.setLocale(Locale(localeCode));
      });

      testWidgets('home screen renders', (tester) async {
        await tester.pumpWidget(const MyApp());
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('no overflow in UI', (tester) async {
        await tester.pumpWidget(const MyApp());
        expect(tester.takeException(), isNull);
      });
    });
  }
}
```

### Visual Regression per Locale

```dart
testGoldens('login screen - all locales', (tester) async {
  for (final locale in supportedLocales) {
    await ShardI18n.instance.setLocale(locale);
    await tester.pumpWidget(const LoginScreen());
    await screenMatchesGolden(tester, 'login_${locale.languageCode}');
  }
});
```

## Monitoring

### Translation Analytics

```dart
class TranslationAnalytics {
  void trackMissingKey(String key, String locale) {
    analytics.logEvent('missing_translation', {
      'key': key,
      'locale': locale,
      'screen': currentRoute,
    });
  }
}

// In ShardI18n fallback handler
ShardI18n.instance.onMissingTranslation = (key, locale) {
  TranslationAnalytics().trackMissingKey(key, locale);
};
```

### Error Tracking

```dart
ShardI18n.instance.onError = (error, stackTrace) {
  Sentry.captureException(error, stackTrace: stackTrace);
};
```

## Best Practices Summary

1. **Shard by feature/team** - Avoid monolithic translation files
2. **Use key constants** - Type-safe, refactorable keys
3. **Automate everything** - CI checks, translation sync, formatting
4. **Lazy load** - Only load what's needed
5. **Monitor production** - Track missing keys and errors
6. **Test all locales** - Automated visual regression
7. **Document conventions** - Shared team guidelines
8. **Version translations** - Track changes over time
