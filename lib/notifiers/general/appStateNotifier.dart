import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/services/persistService.dart';

class AppState {
  final bool isLoading;
  final bool isInitialized;
  final AssessmentMode? assessmentMode;
  final AppView appView;
  final String? orgId;
  final String? orgName;
  final String? assessmentId;
  final String? assessmentName;

  const AppState({
    this.isLoading = false,
    this.isInitialized = false,
    this.assessmentMode,
    this.appView = AppView.none,
    this.orgId,
    this.orgName,
    this.assessmentId,
    this.assessmentName,
  });

  AppState copyWith({
    bool? isLoading,
    bool? isInitialized,
    AssessmentMode? assessmentMode,
    bool clearAssessmentMode = false,
    AppView? appView,
    String? orgId,
    bool clearOrgId = false,
    String? orgName,
    bool clearOrgName = false,
    String? assessmentId,
    bool clearAssessmentId = false,
    String? assessmentName,
    bool clearAssessmentName = false,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      assessmentMode: clearAssessmentMode ? null : (assessmentMode ?? this.assessmentMode),
      appView: appView ?? this.appView,
      orgId: clearOrgId ? null : (orgId ?? this.orgId),
      orgName: clearOrgName ? null : (orgName ?? this.orgName),
      assessmentId: clearAssessmentId ? null : (assessmentId ?? this.assessmentId),
      assessmentName: clearAssessmentName ? null : (assessmentName ?? this.assessmentName),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppState &&
        other.isLoading == isLoading &&
        other.isInitialized == isInitialized &&
        other.assessmentMode == assessmentMode &&
        other.appView == appView &&
        other.orgId == orgId &&
        other.orgName == orgName &&
        other.assessmentId == assessmentId &&
        other.assessmentName == assessmentName;
  }

  @override
  int get hashCode {
    return Object.hash(isLoading, isInitialized, assessmentMode, appView, orgId, orgName, assessmentId, assessmentName);
  }

  @override
  String toString() {
    return 'AppState(isLoading: $isLoading, isInitialized: $isInitialized, assessmentMode: $assessmentMode, appView: $appView, orgId: $orgId, orgName: $orgName, assessmentId: $assessmentId, assessmentName: $assessmentName)';
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Basic initialization without context loading
    state = state.copyWith(isInitialized: true);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setAssessmentMode(AssessmentMode? assessmentMode) {
    state = state.copyWith(assessmentMode: assessmentMode, clearAssessmentMode: assessmentMode == null);
  }

  void setView(AppView appView) {
    state = state.copyWith(appView: appView);
  }

  void setOrgId(String? orgId) {
    state = state.copyWith(orgId: orgId, clearOrgId: orgId == null);
  }

  void setOrgName(String? orgName) {
    state = state.copyWith(orgName: orgName, clearOrgName: orgName == null);
  }

  void setOrg({String? orgId, String? orgName}) {
    state = state.copyWith(
      orgId: orgId,
      clearOrgId: orgId == null,
      orgName: orgName,
      clearOrgName: orgName == null,
    );
  }

  void setAssessmentId(String? assessmentId) {
    state = state.copyWith(assessmentId: assessmentId, clearAssessmentId: assessmentId == null);
  }

  void setAssessmentName(String? assessmentName) {
    state = state.copyWith(assessmentName: assessmentName, clearAssessmentName: assessmentName == null);
  }

  void setAssessment({String? assessmentId, String? assessmentName}) {
    state = state.copyWith(
      assessmentId: assessmentId,
      clearAssessmentId: assessmentId == null,
      assessmentName: assessmentName,
      clearAssessmentName: assessmentName == null,
    );
  }

  void clearOrg() {
    state = state.copyWith(clearOrgId: true, clearOrgName: true);
  }

  void clearAssessment() {
    state = state.copyWith(clearAssessmentId: true, clearAssessmentName: true);
  }

  void clearAssessmentMode() {
    state = state.copyWith(clearAssessmentMode: true);
  }

  void reset() {
    state = const AppState();
  }

  // Batch update method for multiple changes at once
  void batchUpdate(AppState Function(AppState) updates) {
    state = updates(state);
  }

  // Clean getters
  bool get isLoading => state.isLoading;
  bool get isInitialized => state.isInitialized;
  AssessmentMode? get assessmentMode => state.assessmentMode;
  AppView get appView => state.appView;
  String? get orgId => state.orgId;
  String? get orgName => state.orgName;
  String? get assessmentId => state.assessmentId;
  String? get assessmentName => state.assessmentName;
}
