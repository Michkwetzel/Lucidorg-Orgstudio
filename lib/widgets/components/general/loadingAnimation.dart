import 'package:flutter/material.dart';
import 'package:platform_v2/config/constants.dart';

class LoadingAnimation extends StatefulWidget {
  const LoadingAnimation(
    this.loadingText, {
    super.key,
  });

  final String? loadingText;

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    // Custom curve for the spinning animation
    animation =
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ).drive(
          Tween<double>(
            begin: 0,
            end: 1,
          ).chain(
            TweenSequence([
              TweenSequenceItem(
                tween:
                    Tween<double>(begin: 0, end: 2) // Fast clockwise spin (2 rotations)
                        .chain(CurveTween(curve: Curves.easeOut)),
                weight: 40,
              ),
              TweenSequenceItem(
                tween:
                    Tween<double>(begin: 2, end: 1.5) // Slower counterclockwise (half rotation back)
                        .chain(CurveTween(curve: Curves.easeInOut)),
                weight: 60,
              ),
            ]),
          ),
        );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: RotationTransition(
              turns: animation,
              child: Image.asset(
                'assets/logo/3transparent_logo.png',
                width: 100,
                height: 100,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Container(
          decoration: kboxShadowNormal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Text(
              widget.loadingText ?? 'Loading...',
              style: kTextLeadR,
            ),
          ),
        ),
      ],
    );
  }
}
