// Updated toolBarHud.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';

class ToolBarHud extends ConsumerWidget {
  const ToolBarHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Draggable<Map<String, dynamic>>(
          data: {'blockType': BlockType.add},
          feedback: Builder(
            builder: (context) {
              double scale = ref.read(canvasScaleProvider);
              return Container(
                width: 120 * scale,
                height: 100 * scale,
                decoration: kboxShadowNormal,
                child: Icon(
                  Icons.add,
                  size: 24 * scale,
                ),
              );
            },
          ),
          child: Container(
            width: 120,
            height: 100,
            decoration: kboxShadowNormal,
            child: Icon(Icons.add),
          ),
        ),
        FilledButton.tonal(
          onPressed: () => ref.read(canvasProvider.notifier).saveToDB(),
          child: Text("Save"),
        ),
      ],
    );
  }
}
