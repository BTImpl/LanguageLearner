/// Build-time configuration, set with `--dart-define`.
abstract final class AppConfig {
  /// The web OAuth client of the Google Cloud project: the audience the backend
  /// checks in the ID token. Not a secret. Override with
  /// `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` to use another project.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '88142873402-bj03a8kcq13bh2qn3p3gutj0nkg6ejhr.apps.googleusercontent.com',
  );
}
