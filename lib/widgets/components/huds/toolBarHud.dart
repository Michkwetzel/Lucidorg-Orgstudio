// Updated toolBarHud.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';


class ToolBarHud extends ConsumerWidget {
  const ToolBarHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // // Add new block at center of canvas
            // final blockID = FirestoreIdGenerator.generate();
            // ref.read(canvasProvider.notifier).addBlock(blockID);
            // print("Added new block: $blockID");
          },
          child: Container(
            width: 120,
            height: 100,
            decoration: kboxShadowNormal,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 32),
                Text('Add Block', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        // FilledButton.tonal(
        //   onPressed: () => ref.read(canvasProvider.notifier).saveToDB(),
        //   child: Text("Save"),
        // ),
      ],
    );
  }
}
