import 'package:flutter/material.dart';
import 'package:platform_v2/config/constants.dart';

class OrgBlock extends StatelessWidget {
  final double x;
  final double y;
  const OrgBlock({super.key, required this.x, required this.y});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: Draggable<String>(
        data: "orgBlock",
        feedback: Container(
          width: 100,
          height: 100,
          decoration: kboxShadowNormal,
          child: Icon(Icons.add),
        ),
        onDragStarted: () {
          context.ref
        },
        onDragEnd: (details) {
          // Get the render box of the canvas container
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.offset);
          print('Dropped at local: $localPosition');
          print('Dropped at global: ${details.offset}');
        },
        child: Container(
          width: 120,
          height: 100,
          decoration: kboxShadowNormal,
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
