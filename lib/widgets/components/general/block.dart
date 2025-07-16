import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/services/firestoreIdGenerator.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

class Block extends ConsumerWidget {
  final String blockID;

  const Block({
    super.key,
    required this.blockID,
  });

  // Helper function to find parent of current block. Used when creating a new block directly
  String? _findParentOfBlock(WidgetRef ref, String blockID) {
    final connections = ref.read(connectionManagerProvider).connections;
    for (final connection in connections) {
      if (connection.childId == blockID) {
        return connection.parentId;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String getDepartment() {
      return ref.read(blockNotifierProvider(blockID).notifier).blockData?.department ?? '';
    }

    final blockState = ref.watch(blockNotifierProvider(blockID));
    final blockNotifier = ref.read(blockNotifierProvider(blockID).notifier);
    final BlockData? blockData = blockState.blockData;

    ref.listen<String?>(selectedBlockProvider, (previous, next) {
      if (next != blockID && blockState.selectionMode) {
        blockNotifier.selectionModeDisable();
      }
    });

    if (blockState.positionLoaded == false) {
      return const SizedBox.shrink();
    }

    // Calculate the expanded size to include selection dots when in selection mode
    const dotOverhang = 38.0; // How far the dots extend beyond the block
    final isSelectionMode = blockState.selectionMode;
    final hitboxOffset = isSelectionMode ? dotOverhang : 0.0;
    final hitboxWidth = kBlockWidth + (hitboxOffset * 2);
    final hitboxHeight = kBlockHeight + (hitboxOffset * 2);

    return Positioned(
      left: blockState.position.dx - hitboxOffset,
      top: blockState.position.dy - hitboxOffset,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Toggle selection mode
          if (isSelectionMode) {
            ref.read(blockNotifierProvider(blockID).notifier).selectionModeDisable();
            ref.read(selectedBlockProvider.notifier).state = null;
          } else {
            //Enable selectionMode for block and update SelectedBLockProvider
            ref.read(blockNotifierProvider(blockID).notifier).selectionModeEnable();
            ref.read(selectedBlockProvider.notifier).state = blockID;

            //Find descendants off block if any
            blockNotifier.updateDescendants(blockID, ref.read(connectionManagerProvider.notifier).parentAndChildren);
          }
        },
        onDoubleTapDown: (details) {
          OverlayService.openBlockInputBox(
            context,
            initialData: blockData,
            onSave: (data) {
              ref.read(blockNotifierProvider(blockID).notifier).updateData(data);
            },
            onClose: () {},
          );
        },
        onPanUpdate: (details) {
          // Convert global position to local canvas position
          Offset? getNewPosition() {
            final RenderBox? canvasBox = context.findAncestorRenderObjectOfType<RenderBox>();
            if (canvasBox != null) {
              final localPosition = canvasBox.globalToLocal(details.globalPosition);

              // Account for the hitbox offset when calculating the actual block position
              // The gesture detector is expanded, so we need to subtract the hitbox offset
              // to get the correct block position
              return Offset(
                localPosition.dx - hitboxOffset,
                localPosition.dy - hitboxOffset,
              );
            }
            return null;
          }

          // Get new position
          final newPosition = getNewPosition();

          // Early return if position calculation failed
          if (newPosition == null) return;

          // Check if block is selected and if it has any children. If yes then do batch move and batch firestore update
          // If not just move block and one doc update
          if (isSelectionMode && blockNotifier.descendants.isNotEmpty) {
            Set<String> descendants = blockNotifier.descendants;
            final currentPosition = blockNotifier.position;
            final delta = newPosition - currentPosition;

            // Update UI immediately for all descendants
            for (var descendant in descendants) {
              final notifier = ref.read(blockNotifierProvider(descendant).notifier);
              final currentPos = notifier.position;
              notifier.updatePositionWithoutFirestore(currentPos + delta);
            }

            // Update the main block position immediately as well
            ref.read(blockNotifierProvider(blockID).notifier).updatePositionWithoutFirestore(newPosition);

            // Batch update to Firestore (debounced)
            Map<String, Offset> positions = {blockID: newPosition};
            for (var descendant in descendants) {
              positions[descendant] = ref.read(blockNotifierProvider(descendant).notifier).position;
            }
            blockNotifier.batchUpdateDescendantPositions(positions);
          } else {
            // Single block movement
            ref.read(blockNotifierProvider(blockID).notifier).updatePosition(newPosition);
          }
        },
        child: SizedBox(
          width: hitboxWidth,
          height: hitboxHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main block container - positioned at the center of the hitbox area
              Positioned(
                left: hitboxOffset,
                top: hitboxOffset,
                child: Container(
                  width: kBlockWidth,
                  height: kBlockHeight,
                  decoration: isSelectionMode
                      ? kboxShadowNormal.copyWith(border: Border.all(color: Colors.blue, width: 2))
                      : blockData?.hasMultipleEmails ?? false
                      ? kboxShadowNormal.copyWith(border: Border.all(color: Colors.black, width: 2))
                      : kboxShadowNormal,
                  child: Column(
                    spacing: 4,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(blockData?.name ?? ""),
                      Text(blockData?.role ?? ""),
                      Text(blockData?.department ?? ""),
                    ],
                  ),
                ),
              ),

              if (isSelectionMode) ...[
                Positioned(
                  top: hitboxOffset,
                  right: hitboxOffset,
                  child: _BlockDropdownMenu(blockID: blockID),
                ),

                // Top center dot
                Positioned(
                  left: (hitboxWidth / 2) - (kSelectionDotSize / 2),
                  top: 0,
                  child: _SelectionDot(
                    onTap: () {
                      String newBlockID = FirestoreIdGenerator.generate();
                      // Position 300px above
                      Offset newPosition = Offset(blockState.position.dx, blockState.position.dy - 300);

                      ref.read(canvasProvider.notifier).addBlock(newBlockID, newPosition, department: getDepartment());

                      // Create parent-child connection: new block (parent) → current block (child)
                      ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: newBlockID, childBlockID: blockID);
                      ref.read(blockNotifierProvider(blockID).notifier).selectionModeDisable();
                    },
                  ),
                ),

                // Bottom center dot
                Positioned(
                  left: (hitboxWidth / 2) - (kSelectionDotSize / 2),
                  bottom: 0,
                  child: _SelectionDot(
                    onTap: () {
                      // print('Bottom dot button clicked');
                      String newBlockID = FirestoreIdGenerator.generate();
                      ref.read(canvasProvider.notifier).addBlock(newBlockID, Offset(blockState.position.dx, blockState.position.dy + 300), department: getDepartment());
                      ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: blockID, childBlockID: newBlockID);
                      ref.read(blockNotifierProvider(blockID).notifier).selectionModeDisable();
                    },
                  ),
                ),

                // Right center dot
                Positioned(
                  right: 0,
                  top: (hitboxHeight / 2) - (kSelectionDotSize / 2),
                  child: _SelectionDot(
                    onTap: () {
                      String newBlockID = FirestoreIdGenerator.generate();
                      // Position 300px to the right
                      Offset newPosition = Offset(blockState.position.dx + 300, blockState.position.dy);

                      ref.read(canvasProvider.notifier).addBlock(newBlockID, newPosition, department: getDepartment());

                      // Find parent of current block
                      String? parentID = _findParentOfBlock(ref, blockID);
                      if (parentID != null) {
                        // Create sibling connection: parent → new block
                        ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: parentID, childBlockID: newBlockID);
                      }
                      ref.read(blockNotifierProvider(blockID).notifier).selectionModeDisable();
                    },
                  ),
                ),

                // Left center dot
                Positioned(
                  left: 0,
                  top: (hitboxHeight / 2) - (kSelectionDotSize / 2),
                  child: _SelectionDot(
                    onTap: () {
                      String newBlockID = FirestoreIdGenerator.generate();
                      // Position 300px to the left
                      Offset newPosition = Offset(blockState.position.dx - 300, blockState.position.dy);

                      ref.read(canvasProvider.notifier).addBlock(newBlockID, newPosition, department: getDepartment());

                      // Find parent of current block
                      String? parentID = _findParentOfBlock(ref, blockID);
                      if (parentID != null) {
                        // Create sibling connection: parent → new block
                        ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: parentID, childBlockID: newBlockID);
                      }
                      ref.read(blockNotifierProvider(blockID).notifier).selectionModeDisable();
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

  const _SelectionDot({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: kSelectionDotSize,
        height: kSelectionDotSize,
        decoration: BoxDecoration(
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

class _BlockDropdownMenu extends ConsumerWidget {
  final String blockID;

  const _BlockDropdownMenu({required this.blockID});

  // Static menu items - built once, reused for all instances
  static const List<PopupMenuEntry<String>> _menuItems = [
    PopupMenuItem<String>(
      value: 'delete',
      child: Row(
        children: [
          Icon(Icons.delete_outline, size: 16, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete', style: TextStyle(color: Colors.red)),
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_horiz,
        size: 16,
        color: Colors.grey,
      ),
      iconSize: 16,
      padding: const EdgeInsets.all(4),
      onSelected: (value) => _handleSelection(value, ref),
      itemBuilder: (context) => _menuItems,
    );
  }

  void _handleSelection(String value, WidgetRef ref) {
    if (value == 'delete') {
      ref.read(canvasProvider.notifier).deleteBlock(blockID);
    }
  }
}
