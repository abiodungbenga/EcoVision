class AppConstants {
  static const String appName = 'EcoVision';
  static const String appTagline =
      'Environmental Footage & Multimodal Video Search';

  // Default V-Modal scope settings
  static const String defaultProjectId = 'ecovision';
  static const String defaultCollectionName = 'wildlife_research';
  static const String defaultStreamName = 'nature_footage';
  static const String defaultIndexType = 'vid_img_emb';

  /// Minimum relevance score (0.0 to 1.0) for a search result to be shown.
  /// Results below this are considered unrelated and filtered out.
  static const double minRelevanceScore = 0.18;

  // Research-themed semantic chips
  static const List<Map<String, String>> semanticChips = [
    {'label': 'Predation', 'query': 'hunting predation animal attack'},
    {'label': 'At the water', 'query': 'animal drinking water'},
    {'label': 'Human presence', 'query': 'people walking human presence'},
    {'label': 'After dark', 'query': 'animals at night low light'},
    {
      'label': 'Herd activity',
      'query': 'group of animals herd social interaction',
    },
  ];
}
