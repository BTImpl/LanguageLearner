/// How a word went in a round. The first attempt decides.
enum WordOutcome {
  /// Answered correctly at the first attempt, without help.
  firstTry,

  /// Solved after asking for help.
  withHelp,

  /// The first attempt was wrong.
  wrongFirst,
}
