import 'package:flutter/material.dart';
import 'package:shard_i18n/shard_i18n.dart';

import 'language_picker.dart';

/// Onboarding screen demonstrating shard_i18n features
///
/// Shows a multi-page introduction to the package with:
/// - Feature highlights
/// - Code examples
/// - Benefits explanation
/// - Separate onboarding.json translation files per locale
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _skipOnboarding() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in AnimatedBuilder to rebuild when language changes
    return AnimatedBuilder(
      animation: ShardI18n.instance,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Top bar with language selector and skip button
                Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Language selector button
                  IconButton(
                    onPressed: () => showLanguagePicker(context),
                    icon: const Icon(Icons.language),
                    tooltip: context.t('Change Language'),
                    iconSize: 28,
                  ),
                  // Current language indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      ShardI18n.instance.locale.languageCode.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  // Skip button
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(context.t('Skip')),
                  ),
                ],
              ),
            ),

            // Page view
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _OnboardingPage(
                    icon: Icons.rocket_launch,
                    iconColor: Colors.blue,
                    title: context.t('Welcome to shard_i18n'),
                    description: context.t('onboarding_welcome_description'),
                    features: [
                      context.t('onboarding_feature_no_codegen'),
                      context.t('onboarding_feature_runtime'),
                      context.t('onboarding_feature_sharded'),
                    ],
                  ),
                  _OnboardingPage(
                    icon: Icons.translate,
                    iconColor: Colors.green,
                    title: context.t('Simple & Readable'),
                    description: context.t('onboarding_simple_description'),
                    codeExample: '''context.t('Hello, {name}!',
  params: {'name': 'World'})

context.tn('items_count',
  count: 5)''',
                  ),
                  _OnboardingPage(
                    icon: Icons.folder_outlined,
                    iconColor: Colors.orange,
                    title: context.t('Sharded Translations'),
                    description: context.t('onboarding_sharded_description'),
                    features: [
                      context.t('onboarding_benefit_conflicts'),
                      context.t('onboarding_benefit_loading'),
                      context.t('onboarding_benefit_maintenance'),
                    ],
                  ),
                  _OnboardingPage(
                    icon: Icons.check_circle,
                    iconColor: Colors.purple,
                    title: context.t('Ready to Go!'),
                    description: context.t('onboarding_ready_description'),
                    isLastPage: true,
                  ),
                ],
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: _currentPage == index ? 24.0 : 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
              ),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    _currentPage < 3
                        ? context.t('Next')
                        : context.t('Get Started'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.features,
    this.codeExample,
    this.isLastPage = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<String>? features;
  final String? codeExample;
  final bool isLastPage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 80,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Features list
          if (features != null) ...[
            ...features!.map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: iconColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Code example
          if (codeExample != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                codeExample!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ),
          ],

          // Last page extra content
          if (isLastPage) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.t('onboarding_tip'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
