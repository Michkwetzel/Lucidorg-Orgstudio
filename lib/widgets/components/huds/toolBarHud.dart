import 'package:flutter/material.dart';
import 'package:platform_v2/config/constants.dart';

class ToolBarHud extends StatelessWidget {
  const ToolBarHud({super.key});

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: "block_type_1", // Pass data to identify what's being dragged
      feedback: Container(
        width: 100,
        height: 100,
        decoration: kboxShadowNormal,
        child: Icon(Icons.add),
      ),
      onDragEnd: (details) {},
      child: Container(
        width: 120,
        height: 100,
        decoration: kboxShadowNormal,
        child: Icon(Icons.add),
      ),
    );
  }
}
