import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/widgets/components/huds/botLeftHud.dart';
import 'package:platform_v2/widgets/components/huds/toolBarHud.dart';
import 'package:platform_v2/widgets/components/huds/topLeftHud.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFBFBFB),
      body: Stack(
        children: [
          child,

          Stack(
            children: [
              Positioned(
                top: 80,
                left: 24,
                child: ToolBarHud(),
              ),
              Positioned(
                top: 12,
                left: 24,
                child: TopLeftHud(),
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
