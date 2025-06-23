import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';

// Notifier Holding Main app state like which screen, Selected Company, Selected Assessment, etc.
class AppState {
  final bool isLoading;
  final Screen screen;

  final String? companyID;
  final String? companyName;
  final String? assessmentID;
  final String? assessmentName;

  AppState({
    this.isLoading = false,
    this.screen = Screen.logIn,

    this.companyID,
    this.companyName,
    this.assessmentID,
    this.assessmentName,
  });

  AppState copyWith({
    bool? isLoading,
    String? companyID,
    Screen? screen,
    String? companyName,
    String? assessmentID,
    String? assessmentName,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      companyID: companyID,
      screen: screen ?? this.screen,
      companyName: companyName,
      assessmentID: assessmentID,
      assessmentName: assessmentName,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState());

  void setCompany(String? companyID, String? companyName) {
    state = state.copyWith(companyID: companyID, companyName: companyName);
  }

  void setScreen(Screen screen) {
    state = state.copyWith(screen: screen);
  }
}
