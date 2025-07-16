import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';
import 'package:platform_v2/abstractClasses/blockMode.dart';
import 'package:platform_v2/abstractClasses/orgBuildStrategy.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/services/firestoreIdGenerator.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

class Block extends ConsumerWidget {
  final String blockId;

  const Block({
    super.key,
    required this.blockId,
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
    final OrgBuildStrategy strategy = OrgBuildStrategy();

    BlockContext blockContext = BlockContext(
      ref: ref,
      blockId: blockId,
      buildContext: context,
      dotOverhang: 38, //How far the dot extends beyond the block
    );

    final hitboxOffset = strategy.hitboxOffset(blockContext);
    final hitboxWidth = strategy.hitboxWidth(blockContext);
    final hitboxHeight = strategy.hitboxHeight(blockContext);

    String getDepartment() {
      return ref.read(blockNotifierProvider(blockId).notifier).blockData?.department ?? '';
    }

    final blockState = ref.watch(blockNotifierProvider(blockId));
    final blockNotifier = ref.read(blockNotifierProvider(blockId).notifier);
    final BlockData? blockData = blockState.blockData;

    ref.listen<String?>(selectedBlockProvider, (previous, next) {
      if (next != blockId && blockState.selectionMode) {
        blockNotifier.selectionModeDisable();
      }
    });

    if (blockState.positionLoaded == false) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: blockState.position.dx - hitboxOffset,
      top: blockState.position.dy - hitboxOffset,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => strategy.onTap(blockContext),
        onDoubleTapDown: (details) => strategy.onDoubleTapDown(blockContext),
        onPanUpdate: (details) => strategy.onPanUpdate(blockContext, details),
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
                  decoration: blockState.selectionMode
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

              if (blockState.selectionMode) ...[
                Positioned(
                  top: hitboxOffset,
                  right: hitboxOffset,
                  child: _BlockDropdownMenu(blockId: blockId),
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
                      ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: newBlockID, childBlockID: blockId);
                      ref.read(blockNotifierProvider(blockId).notifier).selectionModeDisable();
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
                      ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: blockId, childBlockID: newBlockID);
                      ref.read(blockNotifierProvider(blockId).notifier).selectionModeDisable();
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
                      String? parentID = _findParentOfBlock(ref, blockId);
                      if (parentID != null) {
                        // Create sibling connection: parent → new block
                        ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: parentID, childBlockID: newBlockID);
                      }
                      ref.read(blockNotifierProvider(blockId).notifier).selectionModeDisable();
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
                      String? parentID = _findParentOfBlock(ref, blockId);
                      if (parentID != null) {
                        // Create sibling connection: parent → new block
                        ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: parentID, childBlockID: newBlockID);
                      }
                      ref.read(blockNotifierProvider(blockId).notifier).selectionModeDisable();
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
  final String blockId;

  const _BlockDropdownMenu({required this.blockId});

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
      ref.read(canvasProvider.notifier).deleteBlock(blockId);
    }
  }
}
