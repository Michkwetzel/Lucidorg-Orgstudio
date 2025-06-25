import 'package:flutter_riverpod/flutter_riverpod.dart';

class BotleftHudState {
  final bool show;
  final bool showOrgsButton;

  BotleftHudState({
    required this.show,
    required this.showOrgsButton,
  });

  BotleftHudState copyWith({
    bool? show,
    bool? showOrgsButton,
  }) {
    return BotleftHudState(
      show: show ?? this.show,
      showOrgsButton: showOrgsButton ?? this.showOrgsButton,
    );
  }
}

class BotLeftHudNotifier extends StateNotifier<BotleftHudState> {
  BotLeftHudNotifier() : super(BotleftHudState(show: false, showOrgsButton: false));

  void toggleHud(bool show) {
    state = state.copyWith(show: show);
  }

  void toggleOrgsButton(bool show) {
    state = state.copyWith(showOrgsButton: show);
  }
}
