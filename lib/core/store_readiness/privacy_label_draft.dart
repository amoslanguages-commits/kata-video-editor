class PrivacyDisclosureAnswer {
  final String section;
  final String question;
  final String suggestedAnswer;
  final String explanation;
  final bool mustVerifyBeforeSubmission;

  const PrivacyDisclosureAnswer({
    required this.section,
    required this.question,
    required this.suggestedAnswer,
    required this.explanation,
    this.mustVerifyBeforeSubmission = true,
  });
}

class PrivacyLabelDraft {
  PrivacyLabelDraft._();

  static const answers = <PrivacyDisclosureAnswer>[
    PrivacyDisclosureAnswer(
      section: 'Media access',
      question: 'Does the app access user photos, videos, or audio?',
      suggestedAnswer: 'Yes',
      explanation:
          'The editor imports media selected by the user for editing and export.',
    ),
    PrivacyDisclosureAnswer(
      section: 'Media collection',
      question: 'Are imported media files uploaded or shared by default?',
      suggestedAnswer: 'No',
      explanation:
          'The app is designed offline-first; imported files stay on device by default.',
    ),
    PrivacyDisclosureAnswer(
      section: 'Project data',
      question: 'Does the app store project/timeline data?',
      suggestedAnswer: 'Yes, on device',
      explanation:
          'Projects, clips, tracks, keyframes, transitions, text styles, and exports are stored locally.',
    ),
    PrivacyDisclosureAnswer(
      section: 'Diagnostics',
      question: 'Does the app store diagnostics or crash data?',
      suggestedAnswer: 'Local diagnostics only in V1',
      explanation:
          'Diagnostics logs are local unless a future crash reporting provider is enabled.',
    ),
    PrivacyDisclosureAnswer(
      section: 'Analytics',
      question: 'Does the app collect analytics?',
      suggestedAnswer: 'No in V1 if analyticsEnabled is false',
      explanation:
          'Analytics abstraction exists, but production config currently disables analytics.',
    ),
    PrivacyDisclosureAnswer(
      section: 'Purchases',
      question: 'Does the app process purchases?',
      suggestedAnswer: 'No in V1',
      explanation:
          'Premium unlock is local/dev-only until real monetization is implemented.',
    ),
    PrivacyDisclosureAnswer(
      section: 'Account data',
      question: 'Does the app require an account?',
      suggestedAnswer: 'No in V1',
      explanation:
          'The app is local-first and does not require sign-in in the current plan.',
    ),
    PrivacyDisclosureAnswer(
      section: 'Data deletion',
      question: 'Can users delete local projects/data?',
      suggestedAnswer: 'Yes',
      explanation:
          'Users can delete projects and clear cache/diagnostics locally.',
    ),
  ];
}
