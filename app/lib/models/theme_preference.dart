/// User preference for the app's theme mode.
enum ThemePreference {
  dark('dark', 'Dark'),
  light('light', 'Light');

  /// Persisted value in the settings table.
  final String code;

  /// Display label.
  final String label;

  const ThemePreference(this.code, this.label);

  /// Settings table key under which the preference is stored.
  static const String settingsKey = 'theme_mode';

  /// Parse from a stored settings value; defaults to [dark].
  static ThemePreference fromCode(String? code) {
    return switch (code) {
      'light' => light,
      _ => dark,
    };
  }
}
