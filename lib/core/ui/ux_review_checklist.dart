class UxReviewChecklistItem {
  final String id;
  final String title;
  final String description;
  final String verificationSteps;

  const UxReviewChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    required this.verificationSteps,
  });
}

class UxReviewChecklistCatalog {
  UxReviewChecklistCatalog._();

  static const items = <UxReviewChecklistItem>[
    UxReviewChecklistItem(
      id: 'ui_tokens',
      title: 'Premium Spacing and Radius Tokens',
      description: 'Ensure widgets use PremiumSpacing and PremiumRadius variables.',
      verificationSteps: 'Double check UI code references instead of raw double paddings.',
    ),
    UxReviewChecklistItem(
      id: 'color_gradients',
      title: 'Curated Harmonious Color Gradients',
      description: 'Check if pro/cyan and hero background gradients match visual guidelines.',
      verificationSteps: 'Card borders, paywall headers, and progress bars must render gradients.',
    ),
    UxReviewChecklistItem(
      id: 'micro_interactions',
      title: 'Smooth Micro-interactions and Scaling',
      description: 'Confirm buttons scale down slightly on click/gesture interactions.',
      verificationSteps: 'Tap a PremiumButton and verify the scale animation executes.',
    ),
    UxReviewChecklistItem(
      id: 'haptic_feedback',
      title: 'Native Haptic Feedback Integration',
      description: 'Trigger appropriate haptic intensities for success/warning/swipes.',
      verificationSteps: 'Test onboarding page swipe (selection click) and project creations (success vibration).',
    ),
    UxReviewChecklistItem(
      id: 'onboarding_flow',
      title: 'Polished Sliding Onboarding wizard',
      description: 'Onboarding runs cleanly on first install detailing offline-first perks.',
      verificationSteps: 'Perform a clean startup or reset settings to re-trigger onboarding.',
    ),
    UxReviewChecklistItem(
      id: 'first_project_guide',
      title: 'Workflow Guide bottom sheet',
      description: 'Bottom sheet displays correct Import -> Edit -> Export timeline hints.',
      verificationSteps: 'Launch editor for an empty/new project and verify guide sheet shows.',
    ),
    UxReviewChecklistItem(
      id: 'empty_states',
      title: 'Premium styled Empty states',
      description: 'Dashboard list and timeline media pools must display descriptive cards.',
      verificationSteps: 'Verify no blank grey boxes remain on empty screens.',
    ),
    UxReviewChecklistItem(
      id: 'accessibility_semantics',
      title: 'Accessibility Semantics & Screen Reader tags',
      description: 'Primary action buttons and lists must wrap semantic attributes.',
      verificationSteps: 'Check semantics node layout or verify with debug semantical debugger.',
    ),
    UxReviewChecklistItem(
      id: 'monetization_gating',
      title: 'Plan Watermark & Resolution Limits',
      description: 'Free users cannot remove watermarks or render in 4K resolution.',
      verificationSteps: 'Confirm watermarked exports trigger paywall for free memberships.',
    ),
  ];
}
