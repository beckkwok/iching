/// User preference for the language the LLM responds in.
enum LanguagePreference {
  english('en', 'English'),
  chinese('cn', '中文');

  /// Persisted value in the settings table.
  final String code;

  /// Display label.
  final String label;

  const LanguagePreference(this.code, this.label);

  /// Settings table key under which the preference is stored.
  static const String settingsKey = 'language';

  /// Parse from a stored settings value; defaults to [english].
  static LanguagePreference fromCode(String? code) {
    return switch (code) {
      'cn' => chinese,
      _ => english,
    };
  }
}
