import 'package:flutter_riverpod/flutter_riverpod.dart';

class TopleftHudState {
  final String? title;
  final String? subTitle;
  final String? extraText;
  final bool showDropDown;

  TopleftHudState({
    this.title = "Companies",
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
}
