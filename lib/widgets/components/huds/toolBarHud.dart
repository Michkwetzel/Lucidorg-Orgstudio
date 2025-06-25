import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';

class ToolBarHud extends StatelessWidget {
  const ToolBarHud({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Draggable<Map<String, dynamic>>(
          data: {'blockType': BlockType.add}, // Pass data to identify what's being dragged
          feedback: Container(
            width: 50,
            height: 50,
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
        ),
        Consumer(
          builder: (context, ref, child) {
            return FilledButton.tonal(
              onPressed: () => ref.read(canvasProvider.notifier).saveToDB(),
              child: Text("Save"),
            );
          },
        ),
      ],
    );
  }
}
