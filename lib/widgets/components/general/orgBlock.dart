import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';

class OrgBlock extends ConsumerWidget {
  final String id;
  final Offset initialPosition;

  const OrgBlock({super.key, required this.id, required this.initialPosition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockNotifier = ref.watch(blockNotifierProvider(id)); //Each block has its own notifier
    // Set initial position once if provided
    if (!blockNotifier.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        blockNotifier.updatePositionAndInit(initialPosition);
      });
    }

    return Positioned(
      left: blockNotifier.position.dx,
      top: blockNotifier.position.dy,
      child: GestureDetector(
        onDoubleTap: () {
          print("id: $id");
        },
        child: Draggable<Map<String, dynamic>>(
          data: {'id': id, 'blockType': BlockType.existing},
          feedback: Builder(
            // So smart. a Builder function lets you run code before it is built. Ha
            builder: (context) {
              double scale = ref.read(canvasScaleProvider);
              return Container(
                width: 120 * scale,
                height: 100 * scale,
                decoration: kboxShadowNormal,
                child: Center(
                  child: Text(
                    'Block Content',
                    style: TextStyle(fontSize: 14 * scale),
                  ),
                ),
              );
            },
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
