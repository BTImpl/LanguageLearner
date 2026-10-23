import 'package:languagelearner/core/services/system_settings_opener.dart';

/// A [SystemSettingsOpener] that only counts the calls.
class FakeSystemSettingsOpener implements SystemSettingsOpener {
  int opened = 0;

  @override
  Future<bool> openAppSettings() async {
    opened++;
    return true;
  }
}
