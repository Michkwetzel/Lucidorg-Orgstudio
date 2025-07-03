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

    return Row(
      mainAxisSize: MainAxisSize.min,
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
        SizedBox(width: 12),
        Text(state.title ?? "", style: kTextHeading2R,),
        SizedBox(width: 4),
        if (state.subTitle != null) Text(" - ${state.subTitle}"),
      ],
    );
  }
}
