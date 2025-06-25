import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';

// Notifier Holding Main app state like which screen, Selected org, Selected Assessment, etc.
class AppState {
  final bool isLoading;
  final Screen screen;

  final String? orgId;
  final String? orgName;
  final String? assessmentID;
  final String? assessmentName;

  AppState({
    this.isLoading = false,
    this.screen = Screen.logIn,

    this.orgId,
    this.orgName,
    this.assessmentID,
    this.assessmentName,
  });

  AppState copyWith({
    bool? isLoading,
    String? orgId,
    Screen? screen,
    String? orgName,
    String? assessmentID,
    String? assessmentName,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      orgId: orgId,
      screen: screen ?? this.screen,
      orgName: orgName,
      assessmentID: assessmentID,
      assessmentName: assessmentName,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState());

  void setOrg(String? orgId, String? orgName) {
    state = state.copyWith(orgId: orgId, orgName: orgName);
  }

  void setScreen(Screen screen) {
    state = state.copyWith(screen: screen);
  }

  String? get orgId => state.orgId;
}
