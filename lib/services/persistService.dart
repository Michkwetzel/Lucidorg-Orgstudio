import 'package:shared_preferences/shared_preferences.dart';
import 'package:platform_v2/config/enums.dart';

class PersistenceService {
  static const String _orgIdKey = 'orgId';
  static const String _orgNameKey = 'orgName';
  static const String _appViewKey = 'appView';
  static const String _appModeKey = 'appMode';

  // Load persisted state
  static Future<Map<String, dynamic>> loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final orgId = prefs.getString(_orgIdKey);
    final orgName = prefs.getString(_orgNameKey);
    final appViewString = prefs.getString(_appViewKey);
    final appModeString = prefs.getString(_appModeKey);

    AppScreen appView = AppScreen.none;
    if (appViewString != null) {
      appView = _parseAppView(appViewString);
    }

    AppMode? appMode;
    if (appModeString != null) {
      appMode = _parseAppMode(appModeString);
    }

    return {
      'orgId': orgId,
      'orgName': orgName,
      'appView': appView,
      'appMode': appMode,
    };
  }

  // Persist organization data
  static Future<void> persistOrg(String? orgId, String? orgName) async {
    final prefs = await SharedPreferences.getInstance();
    if (orgId != null) {
      await prefs.setString(_orgIdKey, orgId);
      if (orgName != null) {
        await prefs.setString(_orgNameKey, orgName);
      }
    }
  }

  // Clear persisted organization data
  static Future<void> clearPersistedOrg() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_orgIdKey);
    await prefs.remove(_orgNameKey);
  }

  // Persist app view
  static Future<void> persistAppView(AppScreen appView) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appViewKey, appView.toString());
  }

  // Persist app mode
  static Future<void> persistAppMode(AppMode appMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appModeKey, appMode.toString());
  }

  // Clear persisted app view
  static Future<void> clearPersistedAppView() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appViewKey);
    await prefs.remove(_appModeKey);
  }

  // Parse app view from string - uses enum values directly
  static AppScreen _parseAppView(String appViewString) {
    for (AppScreen screen in AppScreen.values) {
      if (screen.toString() == appViewString) {
        return screen;
      }
    }
    return AppScreen.none;
  }

  // Parse app mode from string
  static AppMode? _parseAppMode(String appModeString) {
    for (AppMode mode in AppMode.values) {
      if (mode.toString() == appModeString) {
        return mode;
      }
    }
    return null;
  }
}
