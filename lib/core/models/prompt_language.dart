/// The language the app asks in: the word is shown in this language and the
/// answer is in the other one.
enum PromptLanguage {
  english,
  hungarian;

  /// The other direction.
  PromptLanguage get flipped => switch (this) {
    english => hungarian,
    hungarian => english,
  };
}
