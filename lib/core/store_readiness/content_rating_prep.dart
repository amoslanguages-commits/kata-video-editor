class ContentRatingQuestion {
  final String id;
  final String topic;
  final String suggestedAnswer;
  final String explanation;

  const ContentRatingQuestion({
    required this.id,
    required this.topic,
    required this.suggestedAnswer,
    required this.explanation,
  });
}

class ContentRatingPrep {
  ContentRatingPrep._();

  static const questions = <ContentRatingQuestion>[
    ContentRatingQuestion(
      id: 'user_generated_content',
      topic: 'User-generated content',
      suggestedAnswer:
          'The app edits user-selected local media. It does not provide a public feed in V1.',
      explanation:
          'Users can import any personal media, but the app does not host or distribute content.',
    ),
    ContentRatingQuestion(
      id: 'violence',
      topic: 'Violence',
      suggestedAnswer: 'No app-provided violent content.',
      explanation:
          'The editor itself does not include violent content. User-imported media is controlled by the user.',
    ),
    ContentRatingQuestion(
      id: 'adult_content',
      topic: 'Adult content',
      suggestedAnswer: 'No app-provided adult content.',
      explanation:
          'The editor does not provide adult content. User media is private/local.',
    ),
    ContentRatingQuestion(
      id: 'online_interaction',
      topic: 'Online interaction',
      suggestedAnswer: 'No public user interaction in V1.',
      explanation:
          'There is no social feed, messaging, or public sharing inside V1.',
    ),
    ContentRatingQuestion(
      id: 'ads',
      topic: 'Ads',
      suggestedAnswer: 'No ads in V1 unless later added.',
      explanation:
          'Current architecture does not include ad SDKs.',
    ),
    ContentRatingQuestion(
      id: 'purchases',
      topic: 'Purchases',
      suggestedAnswer: 'No real purchases in V1.',
      explanation:
          'Real subscription/payment validation is planned for Step 27.',
    ),
  ];
}
