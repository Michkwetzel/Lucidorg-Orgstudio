import 'package:flutter_riverpod/flutter_riverpod.dart';

class BotleftHudState {
  final bool show;
  final bool showCompaniesButton;

  BotleftHudState({
    required this.show,
    required this.showCompaniesButton,
  });

  BotleftHudState copyWith({
    bool? show,
    bool? showCompaniesButton,
  }) {
    return BotleftHudState(
      show: show ?? this.show,
      showCompaniesButton: showCompaniesButton ?? this.showCompaniesButton,
    );
  }
}

class BotLeftHudNotifier extends StateNotifier<BotleftHudState> {
  BotLeftHudNotifier() : super(BotleftHudState(show: false, showCompaniesButton: false));

  void toggleHud(bool show) {
    state = state.copyWith(show: show);
  }

  void toggleCompaniesButton(bool show) {
    state = state.copyWith(showCompaniesButton: show);
  }
}
