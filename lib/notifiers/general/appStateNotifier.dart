import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/dataClasses/displayContext.dart';
import 'package:platform_v2/dataClasses/firestoreContext.dart';
import 'package:platform_v2/services/persistService.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';

class AppState {
  final bool isLoading;
  final bool isInitialized;
  final FirestoreContext firestoreContext;
  final DisplayContext displayContext;

  const AppState({
    this.isLoading = false,
    this.isInitialized = false,
    this.firestoreContext = const FirestoreContext(),
    this.displayContext = const DisplayContext(),
  });

  // Simplified copyWith - only handles the main properties
  AppState copyWith({
    bool? isLoading,
    bool? isInitialized,
    FirestoreContext? firestoreContext,
    DisplayContext? displayContext,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      firestoreContext: firestoreContext ?? this.firestoreContext,
      displayContext: displayContext ?? this.displayContext,
    );
  }

  // Convenience methods for common updates
  AppState updateFirestore(FirestoreContext Function(FirestoreContext) update) {
    return copyWith(firestoreContext: update(firestoreContext));
  }

  AppState updateDisplay(DisplayContext Function(DisplayContext) update) {
    return copyWith(displayContext: update(displayContext));
  }

  AppState updateOrg({String? orgId, String? orgName, bool clear = false}) {
    return copyWith(
      firestoreContext: firestoreContext.copyWith(
        orgId: orgId,
        clearOrgId: clear,
      ),
      displayContext: displayContext.copyWith(
        orgName: orgName,
        clearOrgName: clear,
      ),
    );
  }

  AppState updateAssessment({String? assessmentId, String? assessmentName, bool clear = false}) {
    return copyWith(
      firestoreContext: firestoreContext.copyWith(
        assessmentId: assessmentId,
        clearAssessmentId: clear,
      ),
      displayContext: displayContext.copyWith(
        assessmentName: assessmentName,
        clearAssessmentName: clear,
      ),
    );
  }

  AppState updateAppView(AppScreen appView) {
    return copyWith(
      displayContext: displayContext.copyWith(appView: appView),
    );
  }

  AppState updateAppMode(AppMode appMode) {
    return copyWith(
      displayContext: displayContext.copyWith(appMode: appMode),
    );
  }

  // Getters
  FirestoreContext get firestore => firestoreContext;
  DisplayContext get display => displayContext;
  String? get orgId => firestoreContext.orgId;
  String? get orgName => displayContext.orgName;
  String? get assessmentId => firestoreContext.assessmentId;
  String? get assessmentName => displayContext.assessmentName;
  AppScreen get appView => displayContext.appView;
  AppMode get appMode => displayContext.appMode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppState && other.isLoading == isLoading && other.isInitialized == isInitialized && other.firestoreContext == firestoreContext && other.displayContext == displayContext;
  }

  @override
  int get hashCode {
    return Object.hash(isLoading, isInitialized, firestoreContext, displayContext);
  }

  @override
  String toString() {
    return 'AppState(isLoading: $isLoading, isInitialized: $isInitialized, firestoreContext: $firestoreContext, displayContext: $displayContext)';
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState()) {
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    final persistedData = await PersistenceService.loadPersistedState();
    final orgId = persistedData['orgId'] as String?;
    final orgName = persistedData['orgName'] as String?;
    final appView = persistedData['appView'] as AppScreen? ?? AppScreen.none;
    final appMode = persistedData['appMode'] as AppMode? ?? AppMode.none;

    if (orgId != null) {
      state = state.updateOrg(orgId: orgId, orgName: orgName).updateAppView(appView).updateAppMode(appMode).copyWith(isInitialized: true);
    } else {
      state = state.updateAppView(appView).updateAppMode(appMode).copyWith(isInitialized: true);
    }
  }

  void setAppMode(AppMode appMode) {
    state = state.updateAppMode(appMode);
    PersistenceService.persistAppMode(appMode);
  }

  void setOrg(String? orgId, String? orgName) {
    print('OrgID: $orgId, OrgName: $orgName');
    state = state.updateOrg(orgId: orgId, orgName: orgName);
    PersistenceService.persistOrg(orgId, orgName);
  }

  void clearOrg() {
    state = state.updateOrg(clear: true);
    PersistenceService.clearPersistedOrg();
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setAssessment(String? assessmentId, String? assessmentName) {
    print('AssessmentID: $assessmentId, AssessmentName: $assessmentName');
    state = state.updateAssessment(assessmentId: assessmentId, assessmentName: assessmentName);
    // Could add persistence here if needed for assessments
    // PersistenceService.persistAssessment(assessmentId, assessmentName);
  }

  void setAppView(AppScreen appView) {
    switch (appView) {
      case AppScreen.orgBuild:
        state = state.updateAssessment(clear: true).updateAppView(appView);
        break;
      default:
        state = state.updateAppView(appView);
    }
    PersistenceService.persistAppView(appView);
  }

  // Combined method for common use case - single rebuild
  void setOrgAndNavigate(String? orgId, String? orgName, AppScreen appView) {
    print('OrgID: $orgId, OrgName: $orgName');
    state = state.updateOrg(orgId: orgId, orgName: orgName).updateAppView(appView);
    PersistenceService.persistOrg(orgId, orgName);
    PersistenceService.persistAppView(appView);
  }

  // Combined method for common use case - single rebuild
  void setAssessmentAndNavigate(String? assessmentId, String? assessmentName, AppScreen appView) {
    print('AssessmentID: $assessmentId, AssessmentName: $assessmentName');
    state = state.updateAssessment(assessmentId: assessmentId, assessmentName: assessmentName).updateAppView(appView);
    NavigationService.navigateTo("/app/canvas");

    PersistenceService.persistAppView(appView);
  }

  // Batch update method for multiple changes at once
  void batchUpdate(AppState Function(AppState) updates) {
    state = updates(state);
  }

  void clearAssessment() {
    state = state.updateAssessment(clear: true);
  }

  void reset() {
    state = const AppState();
    PersistenceService.clearPersistedAppView();
  }

  // Clean getters
  FirestoreContext get firestore => state.firestoreContext;
  DisplayContext get display => state.displayContext;
  AppScreen get currentAppView => state.appView;
  AppMode get currentAppMode => state.appMode;
  bool get isLoading => state.isLoading;
  bool get isInitialized => state.isInitialized;
}
