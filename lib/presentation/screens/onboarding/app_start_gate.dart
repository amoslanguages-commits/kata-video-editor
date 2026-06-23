import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nle_editor/presentation/providers/polish_providers.dart';
import 'package:nle_editor/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:nle_editor/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:nle_editor/presentation/widgets/polish/premium_loading_state.dart';

class AppStartGate extends ConsumerWidget {
  const AppStartGate({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(hasSeenOnboardingProvider);

    return onboarding.when(
      data: (seen) {
        if (seen) {
          return const DashboardScreen();
        }

        return OnboardingScreen(
          onDone: () {
            ref.invalidate(hasSeenOnboardingProvider);
          },
        );
      },
      loading: () => const Scaffold(
        body: PremiumLoadingState(
          title: 'Preparing editor...',
          message: 'Loading local settings and project workspace.',
        ),
      ),
      error: (_, __) => const DashboardScreen(),
    );
  }
}
