import 'package:flutter/material.dart';
import 'package:platform_v2/widgets/components/huds/botLeftHud.dart';
import 'package:platform_v2/widgets/components/huds/topLeftHud.dart';
import 'package:platform_v2/widgets/components/huds/topRightHud.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: Stack(
        children: [
          child,

          Stack(
            children: [
              Positioned(
                top: 12,
                left: 24,
                child: TopLeftHud(),
              ),
              Positioned(
                top: 12,
                right: 24,
                child: TopRightHud(),
              ),
              Positioned(
                bottom: 24,
                left: 24,
                child: BotLeftHud(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
