import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/dataClasses/displayContext.dart';
import 'package:platform_v2/dataClasses/firestoreContext.dart';
import 'package:platform_v2/services/persistService.dart';

// Notifier Holding Main app state like which appView, Selected org, Selected Assessment, etc.
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

  AppState copyWith({
    bool? isLoading,
    bool? isInitialized,
    FirestoreContext? firestoreContext,
    DisplayContext? displayContext,
    // Individual field updates for convenience
    String? orgId,
    String? orgName,
    String? assessmentID,
    String? assessmentName,
    AppView? appView,
    AppMode? appMode,
    // Use this pattern to allow explicitly setting fields to null
    bool clearOrgId = false,
    bool clearOrgName = false,
    bool clearAssessmentID = false,
    bool clearAssessmentName = false,
  }) {
    // Handle individual field updates by creating new contexts
    FirestoreContext newFirestoreContext = firestoreContext ?? this.firestoreContext;
    DisplayContext newDisplayContext = displayContext ?? this.displayContext;

    if (orgId != null || clearOrgId) {
      newFirestoreContext = newFirestoreContext.copyWith(
        orgId: orgId,
        clearOrgId: clearOrgId,
      );
    }

    if (orgName != null || clearOrgName) {
      newDisplayContext = newDisplayContext.copyWith(
        orgName: orgName,
        clearOrgName: clearOrgName,
      );
    }

    if (assessmentID != null || clearAssessmentID) {
      newFirestoreContext = newFirestoreContext.copyWith(
        assessmentId: assessmentID,
        clearAssessmentId: clearAssessmentID,
      );
    }

    if (assessmentName != null || clearAssessmentName) {
      newDisplayContext = newDisplayContext.copyWith(
        assessmentName: assessmentName,
        clearAssessmentName: clearAssessmentName,
      );
    }

    if (appView != null) {
      newDisplayContext = newDisplayContext.copyWith(
        appView: appView,
      );
    }

    if (appMode != null) {
      newDisplayContext = newDisplayContext.copyWith(
        appMode: appMode,
      );
    }

    return AppState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      firestoreContext: newFirestoreContext,
      displayContext: newDisplayContext,
    );
  }

  // Getters for data classes
  FirestoreContext get firestore => firestoreContext;
  DisplayContext get display => displayContext;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppState && other.isLoading == isLoading && other.isInitialized == isInitialized && other.firestoreContext == firestoreContext && other.displayContext == displayContext;
  }

  @override
  int get hashCode {
    return Object.hash(
      isLoading,
      isInitialized,
      firestoreContext,
      displayContext,
    );
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

  // Load persisted state on initialization
  Future<void> _loadPersistedState() async {
    final persistedData = await PersistenceService.loadPersistedState();
    final orgId = persistedData['orgId'] as String?;
    final orgName = persistedData['orgName'] as String?;
    final appView = persistedData['appView'] as AppView;
    final appMode = persistedData['appMode'] as AppMode?;

    if (orgId != null) {
      state = state.copyWith(orgId: orgId, orgName: orgName, appView: appView, appMode: appMode, isInitialized: true);
    } else {
      // No saved org, but still mark as initialized so app can show org selection
      state = state.copyWith(appView: appView, appMode: appMode, isInitialized: true);
    }
  }

  void setAppMode(AppMode appMode) {
    state = state.copyWith(appMode: appMode);
    // Optionally persist the app mode if needed
    // PersistenceService.persistAppMode(appMode);
  }

  void setOrg(String? orgId, String? orgName) {
    print('OrgID: $orgId, OrgName: $orgName');
    state = state.copyWith(orgId: orgId, orgName: orgName);
    PersistenceService.persistOrg(orgId, orgName);
  }

  void clearOrg() {
    state = state.copyWith(clearOrgId: true, clearOrgName: true);
    PersistenceService.clearPersistedOrg();
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setAppView(AppView appview, {String? assessmentID, String? assessmentName}) {
    //Also sets Appview
    if (appview == AppView.assessmentBuild) {
      state = state.copyWith(assessmentID: assessmentID, assessmentName: assessmentName, appView: AppView.assessmentBuild);
    } else if (appview == AppView.orgSelect) {
      state = state.copyWith(appView: AppView.orgSelect, clearOrgId: true);
    } else if (appview == AppView.assessmentSelect) {
      state = state.copyWith(appView: AppView.assessmentSelect);
    } else if (appview == AppView.orgBuild) {
      state = state.copyWith(appView: AppView.orgBuild, clearAssessmentID: true, clearAssessmentName: true);
    }

    PersistenceService.persistAppView(appview);
  }

  void clearAssessment() {
    state = state.copyWith(clearAssessmentID: true, clearAssessmentName: true);
  }

  void reset() {
    state = const AppState();
    PersistenceService.clearPersistedAppView();
  }

  // Getters for data classes
  FirestoreContext get firestore => state.firestoreContext;
  DisplayContext get display => state.displayContext;
  AppView get currentAppView => state.displayContext.appView;
  AppMode get currentAppMode => state.displayContext.appMode;
  bool get isLoading => state.isLoading;
  bool get isInitialized => state.isInitialized;
}
