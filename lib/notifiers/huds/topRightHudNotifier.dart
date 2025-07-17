import 'package:flutter_riverpod/flutter_riverpod.dart';

class TopRightHudNotifier extends StateNotifier<bool> {
  TopRightHudNotifier() : super(true);

  void showHud() {
    state = true;
  }

  void hideHud() {
    state = false;
  }
}
