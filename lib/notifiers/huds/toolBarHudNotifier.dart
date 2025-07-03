import 'package:flutter_riverpod/flutter_riverpod.dart';


class ToolbarHudState {
  final bool show;
  ToolbarHudState(this.show);
}

class ToolBarHudNotifier extends StateNotifier<ToolbarHudState> {
  ToolBarHudNotifier() : super(ToolbarHudState(false));

  void toggleShow(bool show) {
    state = ToolbarHudState(show);
  }
}
