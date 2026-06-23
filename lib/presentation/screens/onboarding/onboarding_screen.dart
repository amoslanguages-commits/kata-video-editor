import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/core/copy/app_copy.dart';
import 'package:nle_editor/core/theme/app_theme.dart';
import 'package:nle_editor/core/ui/premium_ui_tokens.dart';
import 'package:nle_editor/presentation/providers/polish_providers.dart';
import 'package:nle_editor/presentation/widgets/polish/premium_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone;

  const OnboardingScreen({
    super.key,
    required this.onDone,
  });

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();

  int _page = 0;

  static const _pages = [
    _OnboardingPageData(
      icon: Icons.movie_creation_rounded,
      title: AppCopy.onboardingTitle1,
      body: AppCopy.onboardingBody1,
    ),
    _OnboardingPageData(
      icon: Icons.offline_bolt_rounded,
      title: AppCopy.onboardingTitle2,
      body: AppCopy.onboardingBody2,
    ),
    _OnboardingPageData(
      icon: Icons.speed_rounded,
      title: AppCopy.onboardingTitle3,
      body: AppCopy.onboardingBody3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PremiumSpacing.xl),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _page = index);
                    ref.read(hapticServiceProvider).selection();
                  },
                  itemBuilder: (context, index) {
                    return _OnboardingPage(data: _pages[index]);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: PremiumMotion.normal,
                      curve: PremiumMotion.curve,
                      width: i == _page ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppTheme.accentPrimary
                            : AppTheme.textMuted.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(PremiumRadius.pill),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: PremiumSpacing.xl),
              PremiumButton(
                label: isLast ? AppCopy.getStarted : AppCopy.continueText,
                icon: isLast
                    ? Icons.rocket_launch_rounded
                    : Icons.arrow_forward_rounded,
                expanded: true,
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: PremiumMotion.normal,
                      curve: PremiumMotion.curve,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finish() async {
    await ref.read(hapticServiceProvider).success();
    await ref.read(onboardingStateServiceProvider).markOnboardingSeen();
    widget.onDone();
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PremiumSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.86, end: 1),
            duration: PremiumMotion.slow,
            curve: PremiumMotion.entranceCurve,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 154,
              height: 154,
              decoration: BoxDecoration(
                gradient: PremiumGradients.hero,
                borderRadius: BorderRadius.circular(44),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: PremiumShadows.glow(AppTheme.accentPrimary),
              ),
              child: Icon(
                data.icon,
                size: 74,
                color: AppTheme.accentPrimary,
              ),
            ),
          ),
          const SizedBox(height: PremiumSpacing.section),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 32,
              height: 1.05,
            ),
          ),
          const SizedBox(height: PremiumSpacing.md),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });
}
