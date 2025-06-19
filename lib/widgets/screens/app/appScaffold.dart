import 'package:flutter/material.dart';
import 'package:platform_v2/widgets/components/huds/topLeftHud.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        TopLeftHud(),
      ],
    );
  }
}
