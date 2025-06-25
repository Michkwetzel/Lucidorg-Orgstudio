import 'package:flutter_riverpod/flutter_riverpod.dart';

class TopleftHudState {
  final String? title;
  final String? subTitle;
  final String? extraText;
  final bool showDropDown;

  TopleftHudState({
    this.title = "Orgs",
    this.subTitle,
    this.extraText,
    this.showDropDown = false,
  });

  TopleftHudState copyWith({
    String? title,
    String? subTitle,
    String? extraText,
    bool? showDropDown,
  }) {
    return TopleftHudState(
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      extraText: extraText ?? this.extraText,
      showDropDown: showDropDown ?? this.showDropDown,
    );
  }
}

class TopleftHudNotifier extends StateNotifier<TopleftHudState> {
  TopleftHudNotifier() : super(TopleftHudState());

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setSubtitle(String subTitle) {
    state = state.copyWith(subTitle: subTitle);
  }

  void setExtraText(String extraText) {
    state = state.copyWith(extraText: extraText);
  }

  void showDropDown(bool show) {
    state = state.copyWith(showDropDown: show);
  }
}
