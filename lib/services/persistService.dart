import 'package:shared_preferences/shared_preferences.dart';
import 'package:platform_v2/config/enums.dart';

class PersistenceService {
  static const String _orgIdKey = 'orgId';
  static const String _orgNameKey = 'orgName';
  static const String _appViewKey = 'appView';

  // Load persisted state
  static Future<Map<String, dynamic>> loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final orgId = prefs.getString(_orgIdKey);
    final orgName = prefs.getString(_orgNameKey);
    final appViewString = prefs.getString(_appViewKey);

    AppView appView = AppView.none;
    if (appViewString != null) {
      appView = _parseAppView(appViewString);
    }

    return {
      'orgId': orgId,
      'orgName': orgName,
      'appView': appView,
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
  static Future<void> persistAppView(AppView appView) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appViewKey, appView.toString());
  }

  // Clear persisted app view
  static Future<void> clearPersistedAppView() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appViewKey);
  }

  // Parse app view from string
  static AppView _parseAppView(String appViewString) {
    switch (appViewString) {
      case 'AppView.logIn':
        return AppView.logIn;
      case 'AppView.selectOrg':
        return AppView.orgSelect;
      case 'AppView.orgBuild':
        return AppView.orgBuild;
      case 'AppView.assessmentView':
        return AppView.assessmentBuild;
      default:
        return AppView.none;
    }
  }
}
