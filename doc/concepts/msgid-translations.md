# Msgid-Based Translations

shard_i18n uses a **msgid-based** approach to internationalization, inspired by GNU gettext.

## What is Msgid?

In msgid-based i18n, you use the actual English text as the key:

```dart
// The English text IS the key
context.t('Sign in')
context.t('Welcome to our app')
context.t('Hello, {name}!')
```

This differs from key-based approaches:

```dart
// Key-based (NOT msgid)
context.t('auth.sign_in')
context.t('home.welcome_message')
context.t('greeting.hello_name')
```

## Why Msgid?

### Advantages

1. **Self-documenting code** - You can read the code and understand what it says
2. **Fallback behavior** - If translation is missing, the English text displays
3. **Easier reviews** - Code reviewers see the actual text
4. **Less indirection** - No need to look up keys in translation files

### Trade-offs

1. **Longer keys** - Keys can be verbose for long strings
2. **Copy changes** - If English text changes, all translations need updating
3. **Typo sensitivity** - Typos in code won't match JSON keys

## Best Practices

### Use Natural Text for UI

```dart
// Good: Natural English as msgid
context.t('Sign in')
context.t('Your order has been placed')
context.t('No items in cart')

// Avoid: Abbreviated or unclear text
context.t('sig_in')
context.t('ord_placed')
context.t('no_itms')
```

### Use Stable IDs for Volatile Copy

When the English text is likely to change frequently, use stable IDs:

```dart
// Marketing copy that changes often
context.t('home.hero_headline')
context.t('promo.black_friday_banner')

// Legal text managed by lawyers
context.t('legal.terms_of_service')
context.t('legal.privacy_policy')
```

### JSON Structure

Both styles work in the same JSON files:

```json
{
  "Sign in": "Sign in",
  "Welcome to our app": "Welcome to our app",
  "home.hero_headline": "The Best App Ever!",
  "legal.terms_of_service": "By using this app, you agree to..."
}
```

## Fallback Behavior

When a translation is missing, shard_i18n returns the msgid itself:

```dart
// If "New Feature" is not in German JSON:
context.t('New Feature')  // Returns "New Feature" (the msgid)
```

This provides graceful degradation:
- App doesn't crash
- Users see English text (better than nothing)
- Debug logs show missing keys

## Migration Path

You can mix both approaches during migration:

```dart
// Old key-based (keep working)
context.t('common.submit')

// New msgid-based
context.t('Submit')
```

Both will work simultaneously, allowing gradual migration.

## Comparison

| Aspect | Msgid-based | Key-based |
|--------|-------------|-----------|
| Code readability | High | Medium |
| Key length | Variable | Short |
| Copy changes | Update all | Update one |
| Missing translation | Shows English | Shows key |
| Typo impact | Silent failure | Silent failure |
| Refactoring | Find & replace | Safe |

## When to Use Which

**Use msgid (natural text):**
- UI labels and buttons
- Error messages
- Help text
- Stable copy

**Use stable IDs:**
- Marketing copy
- Legal text
- A/B test variants
- Frequently changing content
