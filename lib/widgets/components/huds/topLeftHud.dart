import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/notifiers/huds/topLeftHudNotifier.dart';

class TopLeftHud extends ConsumerWidget {
  const TopLeftHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TopleftHudState state = ref.watch(topleftHudProvider);

    return Container(
      decoration: kboxShadowNormal,
      child: Row(
        children: [
          SizedBox(
            width: 35,
            height: 35,
            child: Image.asset(
              'assets/logo/logoIcon.png',
            ),
          ),
          SizedBox(width: 4),
          if (state.showDropDown) Icon(Icons.keyboard_arrow_down_rounded),
          SizedBox(width: 24),
          Text(state.title ?? ""),
          SizedBox(width: 4),
          if (state.subTitle != null) Text(" - ${state.subTitle}"),
        ],
      ),
    );
  }
}
