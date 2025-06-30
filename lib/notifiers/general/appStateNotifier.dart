import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Notifier Holding Main app state like which screen, Selected org, Selected Assessment, etc.
class AppState {
  final bool isLoading;
  final Screen screen;
  final String? orgId;
  final String? orgName;
  final String? assessmentID;
  final String? assessmentName;

  const AppState({
    this.isLoading = false,
    this.screen = Screen.logIn,
    this.orgId,
    this.orgName,
    this.assessmentID,
    this.assessmentName,
  });

  AppState copyWith({
    bool? isLoading,
    Screen? screen,
    String? orgId,
    String? orgName,
    String? assessmentID,
    String? assessmentName,
    // Use this pattern to allow explicitly setting fields to null
    bool clearOrgId = false,
    bool clearOrgName = false,
    bool clearAssessmentID = false,
    bool clearAssessmentName = false,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      screen: screen ?? this.screen,
      orgId: clearOrgId ? null : (orgId ?? this.orgId),
      orgName: clearOrgName ? null : (orgName ?? this.orgName),
      assessmentID: clearAssessmentID ? null : (assessmentID ?? this.assessmentID),
      assessmentName: clearAssessmentName ? null : (assessmentName ?? this.assessmentName),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppState &&
        other.isLoading == isLoading &&
        other.screen == screen &&
        other.orgId == orgId &&
        other.orgName == orgName &&
        other.assessmentID == assessmentID &&
        other.assessmentName == assessmentName;
  }

  @override
  int get hashCode {
    return Object.hash(
      isLoading,
      screen,
      orgId,
      orgName,
      assessmentID,
      assessmentName,
    );
  }

  @override
  String toString() {
    return 'AppState(isLoading: $isLoading, screen: $screen, orgId: $orgId, orgName: $orgName, assessmentID: $assessmentID, assessmentName: $assessmentName)';
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState()) {
    _loadPersistedState();
  }
  // Load persisted state on initialization
  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final orgId = prefs.getString('orgId');
    final orgName = prefs.getString('orgName');

    if (orgId != null) {
      state = state.copyWith(orgId: orgId, orgName: orgName);
    }
  }

  void setOrg(String? orgId, String? orgName) {
    state = state.copyWith(orgId: orgId, orgName: orgName);
    _persistOrg(orgId, orgName);
  }

  void clearOrg() {
    state = state.copyWith(clearOrgId: true, clearOrgName: true);
    _clearPersistedOrg();
  }

  Future<void> _persistOrg(String? orgId, String? orgName) async {
    final prefs = await SharedPreferences.getInstance();
    if (orgId != null) {
      await prefs.setString('orgId', orgId);
      if (orgName != null) {
        await prefs.setString('orgName', orgName);
      }
    }
  }

  Future<void> _clearPersistedOrg() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('orgId');
    await prefs.remove('orgName');
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setScreen(Screen screen) {
    state = state.copyWith(screen: screen);
  }

  void setAssessment(String? assessmentID, String? assessmentName) {
    state = state.copyWith(assessmentID: assessmentID, assessmentName: assessmentName);
  }

  void clearAssessment() {
    state = state.copyWith(clearAssessmentID: true, clearAssessmentName: true);
  }

  void reset() {
    state = const AppState();
  }

  // Getters for convenience
  String? get orgId => state.orgId;
  String? get orgName => state.orgName;
  String? get assessmentID => state.assessmentID;
  String? get assessmentName => state.assessmentName;
  Screen get currentScreen => state.screen;
  bool get isLoading => state.isLoading;
}
