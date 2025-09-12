import 'package:flutter/material.dart';

import 'settings_service.dart';

/// A class that many Widgets can interact with to read user settings, update
/// user settings, or listen to user settings changes.
///
/// Controllers glue Data Services to Flutter Widgets. The SettingsController
/// uses the SettingsService to store and retrieve user settings.
class ThemeToggle extends InheritedWidget with ChangeNotifier {
  ThemeToggle({super.key, required super.child, required this.settingsService});

  // Make SettingsService a private variable so it is not used directly.
  final SettingsService settingsService;

  // Make ThemeMode a private variable so it is not updated directly without
  // also persisting the changes with the SettingsService.
  late ThemeMode _themeMode;

  // Allow Widgets to read the user's preferred ThemeMode.
  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  bool get isLight => _themeMode == ThemeMode.light;

  Icon get icon => isDark ? Icon(Icons.light_mode) : Icon(Icons.dark_mode);

  /// Load the user's settings from the SettingsService. It may load from a
  /// local database or the internet. The controller only knows it can load the
  /// settings from the service.
  Future<void> loadSettings() async {
    _themeMode = await settingsService.themeMode();

    // Important! Inform listeners a change has occurred.
    notifyListeners();
  }

  /// Update and persist the ThemeMode based on the user's selection.
  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;

    // Dot not perform any work if new and old ThemeMode are identical
    if (newThemeMode == _themeMode) return;

    // Otherwise, store the new theme mode in memory
    _themeMode = newThemeMode;

    // Important! Inform listeners a change has occurred.
    notifyListeners();

    // Persist the changes to a local database or the internet using the
    // SettingService.
    await settingsService.updateThemeMode(newThemeMode);
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }

  static ThemeToggle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeToggle>()!;

  toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      updateThemeMode(ThemeMode.light);
    } else {
      updateThemeMode(ThemeMode.dark);
    }
  }
}
