import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

class Block extends ConsumerWidget {
  final String blockID;

  const Block({
    super.key,
    required this.blockID,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockNotifier = ref.watch(blockNotifierProvider(blockID));
    final BlockData? blockData = blockNotifier.blockData;

    if (blockNotifier.positionLoaded == false) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: blockNotifier.position.dx,
      top: blockNotifier.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Toggle selection mode
          if (blockNotifier.selectionMode) {
            ref.read(blockNotifierProvider(blockID).notifier).selectionModeDisable();
          } else {
            ref.read(blockNotifierProvider(blockID).notifier).selectionModeEnable();
          }
        },
        onDoubleTapDown: (details) {
          OverlayService.openBlockInputBox(
            context,
            onSave: (data) {
              ref.read(blockNotifierProvider(blockID).notifier).updateData(data);
            },
            onClose: () {},
          );
        },
        onPanUpdate: (details) {
          // Convert global position to local canvas position
          final RenderBox? canvasBox = context.findAncestorRenderObjectOfType<RenderBox>();
          if (canvasBox != null) {
            final localPosition = canvasBox.globalToLocal(details.globalPosition);
            final adjustedPosition = Offset(
              localPosition.dx - 60,
              localPosition.dy - 50,
            );
            ref.read(blockNotifierProvider(blockID).notifier).updatePosition(adjustedPosition);
          }
        },
        child: SizedBox(
          width: 140, // Increased to accommodate dots
          height: 120, // Increased to accommodate dots
          child: Stack(
            children: [
              // Main block container
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  width: 120,
                  height: 100,
                  decoration: blockNotifier.selectionMode 
                      ? kboxShadowNormal.copyWith(
                          border: Border.all(color: Colors.blue, width: 2)
                        )
                      : kboxShadowNormal,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: blockData == null
                              ? const Center(child: Text("New Block"))
                              : Column(
                                  spacing: 4,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(blockData.name),
                                    Text(blockData.role),
                                    Text(blockData.department),
                                  ],
                                ),
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
                              ref.read(canvasProvider.notifier).deleteBlock(blockID);
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
              
              // Selection dots - only show when in selection mode
              if (blockNotifier.selectionMode) ...[
                // Top center
                Positioned(
                  left: 70 - 4, // Center horizontally
                  top: 10 - 4 - 6, // 6 pixels above the block
                  child: _SelectionDot(
                    onTap: () {
                      // TODO: Add top center tap functionality
                    },
                    onLongPress: () {
                      // TODO: Add top center long press functionality
                    },
                  ),
                ),
                
                // Right center
                Positioned(
                  left: 130 - 4 + 6, // 6 pixels to the right of the block
                  top: 60 - 4, // Center vertically
                  child: _SelectionDot(
                    onTap: () {
                      // TODO: Add right center tap functionality
                    },
                    onLongPress: () {
                      // TODO: Add right center long press functionality
                    },
                  ),
                ),
                
                // Bottom center
                Positioned(
                  left: 70 - 4, // Center horizontally
                  top: 110 - 4 + 6, // 6 pixels below the block
                  child: _SelectionDot(
                    onTap: () {
                      // TODO: Add bottom center tap functionality
                    },
                    onLongPress: () {
                      // TODO: Add bottom center long press functionality
                    },
                  ),
                ),
                
                // Left center
                Positioned(
                  left: 10 - 4 - 6, // 6 pixels to the left of the block
                  top: 60 - 4, // Center vertically
                  child: _SelectionDot(
                    onTap: () {
                      // TODO: Add left center tap functionality
                    },
                    onLongPress: () {
                      // TODO: Add left center long press functionality
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SelectionDot({
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}