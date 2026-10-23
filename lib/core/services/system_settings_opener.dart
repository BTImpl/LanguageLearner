import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the settings page of this app in the system settings, where the
/// student can allow the camera or the photos again.
abstract interface class SystemSettingsOpener {
  /// Whether the settings page could be opened.
  Future<bool> openAppSettings();
}

/// The iOS way: the `app-settings:` link opens the page of this app.
class UrlLauncherSettingsOpener implements SystemSettingsOpener {
  const UrlLauncherSettingsOpener();

  @override
  Future<bool> openAppSettings() => launchUrl(Uri.parse('app-settings:'));
}

/// Opens the system settings of the app. Override it in tests with a fake.
final systemSettingsOpenerProvider = Provider<SystemSettingsOpener>(
  (ref) => const UrlLauncherSettingsOpener(),
);
