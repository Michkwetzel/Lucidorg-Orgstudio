import 'package:shared_preferences/shared_preferences.dart';
import 'package:platform_v2/config/enums.dart';

class PersistenceService {
  static const String _orgIdKey = 'orgId';
  static const String _orgNameKey = 'orgName';
  static const String _appViewKey = 'appView';
  static const String _assessmentModeKey = 'assessmentMode';

  // Load persisted state
  static Future<Map<String, dynamic>> loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final orgId = prefs.getString(_orgIdKey);
    final orgName = prefs.getString(_orgNameKey);
    final appViewString = prefs.getString(_appViewKey);
    final assessmentModeString = prefs.getString(_assessmentModeKey);

    AppView appView = AppView.none;
    if (appViewString != null) {
      appView = _parseAppView(appViewString);
    }

    AssessmentMode? assessmentMode;
    if (assessmentModeString != null) {
      assessmentMode = _parseAssessmentMode(assessmentModeString);
    }

    return {
      'orgId': orgId,
      'orgName': orgName,
      'appView': appView,
      'assessmentMode': assessmentMode,
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

  // Persist assessment mode - now handles nullable values
  static Future<void> persistAssessmentMode(AssessmentMode? assessmentMode) async {
    final prefs = await SharedPreferences.getInstance();
    if (assessmentMode != null) {
      await prefs.setString(_assessmentModeKey, assessmentMode.toString());
    } else {
      await prefs.remove(_assessmentModeKey);
    }
  }

  // Clear persisted assessment mode
  static Future<void> clearPersistedAssessmentMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_assessmentModeKey);
  }

  // Clear persisted app view
  static Future<void> clearPersistedAppView() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appViewKey);
    await prefs.remove(_assessmentModeKey);
  }

  // Parse app view from string - uses enum values directly
  static AppView _parseAppView(String appViewString) {
    for (AppView screen in AppView.values) {
      if (screen.toString() == appViewString) {
        return screen;
      }
    }
    return AppView.none;
  }

  // Parse assessment mode from string
  static AssessmentMode? _parseAssessmentMode(String assessmentModeString) {
    for (AssessmentMode mode in AssessmentMode.values) {
      if (mode.toString() == assessmentModeString) {
        return mode;
      }
    }
    return null;
  }
}
