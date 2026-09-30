/// An emoji reaction the user can give to an interpretation (issue #27).
///
/// Replaces the old 1-5 star rating: a reaction is easier for the user to give
/// and carries an emotional signal that can be fed to the agent memory.
enum Reaction {
  happy('happy', '😄'),
  love('love', '❤️'),
  sad('sad', '😔'),
  angry('angry', '😡'),
  surprised('surprised', '😲'),
  healing('healing', '❤️‍🩹');

  const Reaction(this.key, this.emoji);

  /// Stable key persisted in the database.
  final String key;

  /// The emoji shown in the UI and passed to the LLM.
  final String emoji;

  /// Look up a [Reaction] by its persisted [key], or `null` if unknown.
  static Reaction? fromKey(String? key) {
    if (key == null) return null;
    for (final reaction in Reaction.values) {
      if (reaction.key == key) return reaction;
    }
    return null;
  }

  @override
  String toString() => 'Reaction($key)';
}
