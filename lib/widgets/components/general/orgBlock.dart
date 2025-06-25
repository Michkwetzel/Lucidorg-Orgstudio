import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';

class OrgBlock extends ConsumerWidget {
  final String id;

  const OrgBlock({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockNotifier = ref.watch(blockNotifierProvider(id));

    return Positioned(
      left: blockNotifier.position.dx,
      top: blockNotifier.position.dy,
      child: GestureDetector(
        onDoubleTap: () {
          print("id: $id");
        },
        child: Draggable<Map<String, dynamic>>(
          data: {'id': id, 'blockType': BlockType.existing},
          feedback: Container(
            width: 50,
            height: 50,
            decoration: kboxShadowNormal,
          ),
          child: Container(
            width: 120,
            height: 100,
            decoration: kboxShadowNormal,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: Center(
                    child: Text('Block Content'),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_horiz,
                      size: 16,
                      color: Colors.grey,
                    ),
                    iconSize: 16,
                    padding: const EdgeInsets.all(4),
                    onSelected: (value) {
                      if (value == 'delete') {
                        ref.read(canvasProvider.notifier).deleteBlock(id);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
