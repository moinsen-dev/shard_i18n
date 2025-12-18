# Performance Optimization

This guide covers performance best practices for shard_i18n in production applications.

## Architecture Overview

shard_i18n is designed for performance:

```
┌─────────────────────────────────────────────────────┐
│                    Application                       │
├─────────────────────────────────────────────────────┤
│  context.t('key')  │  'key'.tx  │  context.tn(...)  │
├─────────────────────────────────────────────────────┤
│              ShardI18n (Singleton)                   │
│  ┌──────────────┐  ┌──────────────┐                 │
│  │ Translation  │  │  Plural      │                 │
│  │ Cache (O(1)) │  │  Rules       │                 │
│  └──────────────┘  └──────────────┘                 │
├─────────────────────────────────────────────────────┤
│           Shard Loader (Lazy Loading)                │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐       │
│  │ core   │ │ auth   │ │ home   │ │settings│       │
│  └────────┘ └────────┘ └────────┘ └────────┘       │
└─────────────────────────────────────────────────────┘
```

## Key Performance Characteristics

| Operation | Complexity | Notes |
|-----------|------------|-------|
| Translation lookup | O(1) | HashMap-based |
| Placeholder replacement | O(n) | n = placeholder count |
| Plural selection | O(1) | Direct rule evaluation |
| Locale switch | O(k) | k = shards to load |
| Initial load | O(s) | s = default shards |

## Optimization Strategies

### 1. Lazy Loading Shards

Only load translations when needed:

```dart
await ShardI18n.instance.init(
  supportedLocales: [const Locale('en'), const Locale('de')],
  defaultLocale: const Locale('en'),
  basePath: 'assets/i18n',
  // Only load core.json initially
  preloadShards: ['core'],
);
```

Load feature shards on demand:

```dart
// In feature module
class AuthFeature {
  Future<void> init() async {
    await ShardI18n.instance.loadShard('auth');
  }
}
```

### 2. Shard Organization

Organize shards by feature usage patterns:

```
assets/i18n/en/
├── core.json        # Always loaded (common UI)
├── auth.json        # Loaded on auth screens
├── onboarding.json  # Loaded once, then unloaded
├── settings.json    # Loaded on settings screens
└── errors.json      # Loaded on demand
```

**Guidelines:**
- `core.json`: < 100 keys (navigation, common buttons)
- Feature shards: 50-200 keys each
- Total per locale: No practical limit

### 3. Preload Critical Paths

Preload shards for critical user flows:

```dart
// During splash screen
Future<void> preloadCriticalTranslations() async {
  await Future.wait([
    ShardI18n.instance.loadShard('core'),
    ShardI18n.instance.loadShard('auth'),
  ]);
}
```

### 4. Avoid Repeated Lookups

Cache frequently used translations:

```dart
// ✗ Bad - repeated lookups
Widget build(BuildContext context) {
  return Column(
    children: List.generate(100, (i) =>
      Text(context.t('Item')), // 100 lookups
    ),
  );
}

// ✓ Good - single lookup
Widget build(BuildContext context) {
  final itemLabel = context.t('Item');
  return Column(
    children: List.generate(100, (i) =>
      Text(itemLabel), // 1 lookup
    ),
  );
}
```

### 5. Use String Extensions for Static Text

For static text without context:

```dart
// ✓ Slightly faster - no context lookup
final title = 'Settings'.tx;

// Also fine - minimal overhead
final title = context.t('Settings');
```

## Memory Management

### Unload Unused Shards

For memory-constrained apps:

```dart
// After leaving onboarding
ShardI18n.instance.unloadShard('onboarding');
```

### Monitor Memory Usage

```dart
void debugMemoryUsage() {
  final stats = ShardI18n.instance.getStats();
  print('Loaded shards: ${stats.loadedShards}');
  print('Total keys: ${stats.totalKeys}');
  print('Estimated memory: ${stats.estimatedMemoryBytes} bytes');
}
```

## Startup Optimization

### Minimize Initial Load

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load minimal translations first
  await ShardI18n.instance.init(
    preloadShards: ['core'], // Only essential
  );

  runApp(const MyApp());

  // Load remaining shards in background
  _loadRemainingShards();
}

Future<void> _loadRemainingShards() async {
  await Future.delayed(const Duration(milliseconds: 500));
  await ShardI18n.instance.loadShard('home');
}
```

### Parallel Loading

Load multiple shards concurrently:

```dart
await Future.wait([
  ShardI18n.instance.loadShard('auth'),
  ShardI18n.instance.loadShard('home'),
  ShardI18n.instance.loadShard('settings'),
]);
```

## Locale Switching

### Preload Next Locale

For smooth locale switching:

```dart
Future<void> switchLocale(Locale newLocale) async {
  // Preload in background
  await ShardI18n.instance.preloadLocale(newLocale);

  // Switch is instant
  await ShardI18n.instance.setLocale(newLocale);
}
```

### Cache Multiple Locales

For apps requiring instant switching:

```dart
await ShardI18n.instance.init(
  cacheLocales: ['en', 'de'], // Keep both in memory
);
```

## Measurement & Profiling

### Measure Load Times

```dart
Future<void> measureInit() async {
  final stopwatch = Stopwatch()..start();

  await ShardI18n.instance.init(...);

  stopwatch.stop();
  print('Init time: ${stopwatch.elapsedMilliseconds}ms');
}
```

### Profile Translation Lookups

```dart
void profileTranslations(BuildContext context) {
  final iterations = 10000;
  final stopwatch = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    context.t('Hello');
  }

  stopwatch.stop();
  final perLookup = stopwatch.elapsedMicroseconds / iterations;
  print('Average lookup: ${perLookup}µs');
}
```

### Expected Performance

On modern devices:

| Operation | Expected Time |
|-----------|---------------|
| Simple lookup | < 1µs |
| With 1 placeholder | < 5µs |
| With 3 placeholders | < 10µs |
| Plural lookup | < 5µs |
| Shard load (50 keys) | < 10ms |
| Locale switch | < 50ms |

## Best Practices

### 1. Keep Translations Short

Long translations take more memory:

```json
// ✓ Good
{
  "Welcome": "Welcome"
}

// ✗ Avoid very long inline text
{
  "Terms": "This is a very long terms and conditions text that goes on and on..."
}
```

For long text, consider loading from separate assets.

### 2. Minimize Placeholder Count

Each placeholder adds processing overhead:

```json
// ✓ Good - 2 placeholders
{
  "Welcome, {name}!": "Welcome, {name}! You have {count} notifications."
}

// ✗ Avoid - 5+ placeholders
{
  "stats": "{name} has {posts} posts, {likes} likes, {comments} comments, and {followers} followers."
}
```

### 3. Use Constants for Repeated Keys

```dart
// lib/l10n/keys.dart
class L10nKeys {
  static const welcome = 'Welcome';
  static const save = 'Save';
  static const cancel = 'Cancel';
}

// Usage
Text(context.t(L10nKeys.save));
```

### 4. Profile Before Optimizing

Don't optimize prematurely. Measure first:

```dart
// Add to debug builds
assert(() {
  ShardI18n.instance.enableProfiling();
  return true;
}());
```

### 5. Consider Bundle Size

JSON files add to app bundle size:

| Keys | Approximate Size (uncompressed) |
|------|--------------------------------|
| 100 | ~5 KB |
| 500 | ~25 KB |
| 1000 | ~50 KB |

Compression typically reduces this by 60-70%.

## Troubleshooting Performance

### Slow Startup

1. Check shard count and sizes
2. Reduce `preloadShards`
3. Profile with DevTools

### Slow Locale Switch

1. Preload target locale
2. Check network (if loading remotely)
3. Consider caching multiple locales

### Memory Issues

1. Unload unused shards
2. Split large shards
3. Check for duplicate keys across shards

### Jank During Translation

1. Avoid lookups in build methods of list items
2. Cache translations for repeated use
3. Profile with DevTools Performance tab
