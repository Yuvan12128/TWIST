enum AppLanguage {
  en(
    code: 'en',
    displayName: 'English',
    nativeName: 'English',
    subtitle: 'English stories & interface',
    flagEmoji: '🇬🇧',
  ),
  ta(
    code: 'ta',
    displayName: 'Tamil',
    nativeName: 'தமிழ்',
    subtitle: 'தமிழ் கதைகள் & இடைமுகம்',
    flagEmoji: '🇮🇳',
  ),
  tanglish(
    code: 'tanglish',
    displayName: 'Tanglish',
    nativeName: 'Tanglish',
    subtitle: 'Tamil stories in casual English letters',
    flagEmoji: '🔤',
  );

  final String code;
  final String displayName;
  final String nativeName;
  final String subtitle;
  final String flagEmoji;

  const AppLanguage({
    required this.code,
    required this.displayName,
    required this.nativeName,
    required this.subtitle,
    required this.flagEmoji,
  });

  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.en;
    switch (code.toLowerCase()) {
      case 'ta':
      case 'tamil':
        return AppLanguage.ta;
      case 'tanglish':
        return AppLanguage.tanglish;
      case 'en':
      case 'english':
      default:
        return AppLanguage.en;
    }
  }

  /// Safe localized text resolver with fallback:
  /// Tanglish -> English
  /// Tamil -> English
  /// English -> English
  static String getLocalizedText(Map<String, String>? content, AppLanguage language) {
    if (content == null || content.isEmpty) return '';

    // 1. Direct match
    final direct = content[language.code];
    if (direct != null && direct.trim().isNotEmpty) {
      return direct;
    }

    // 2. Fallbacks based on language
    if (language == AppLanguage.tanglish) {
      final enFallback = content[AppLanguage.en.code];
      if (enFallback != null && enFallback.trim().isNotEmpty) {
        return enFallback;
      }
      final taFallback = content[AppLanguage.ta.code];
      if (taFallback != null && taFallback.trim().isNotEmpty) {
        return taFallback;
      }
    } else if (language == AppLanguage.ta) {
      final enFallback = content[AppLanguage.en.code];
      if (enFallback != null && enFallback.trim().isNotEmpty) {
        return enFallback;
      }
      final tanglishFallback = content[AppLanguage.tanglish.code];
      if (tanglishFallback != null && tanglishFallback.trim().isNotEmpty) {
        return tanglishFallback;
      }
    } else {
      // English requested, check first available
      final enFallback = content[AppLanguage.en.code];
      if (enFallback != null && enFallback.trim().isNotEmpty) {
        return enFallback;
      }
    }

    // 3. Any non-empty value
    for (var val in content.values) {
      if (val.trim().isNotEmpty) return val;
    }

    return '';
  }
}
