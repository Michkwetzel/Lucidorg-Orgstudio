import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/firestoreIdGenerator.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

// The rulebook for what functions a strategy can impliment.
abstract class BlockBehaviorStrategy {
  List<Widget> getSideDotWidgets(BlockContext context, double hitboxWidth, double hitboxHeight) {
    String getDepartment() {
      return context.blockNotifier.blockData?.department ?? '';
    }

    return [
      // Dropdown menu
      Positioned(
        top: 38,
        right: 38,
        child: _BlockDropdownMenu(blockId: context.blockId),
      ),

      // Top center dot
      Positioned(
        left: (hitboxWidth / 2) - (kSelectionDotSize / 2),
        top: 0,
        child: _SelectionDot(
          onTap: () {
            String newBlockID = FirestoreIdGenerator.generate();
            Offset newPosition = Offset(context.blockNotifier.position.dx, context.blockNotifier.position.dy - 300);

            context.ref.read(canvasProvider.notifier).addBlock(newBlockID, newPosition, department: getDepartment());
            context.ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: newBlockID, childBlockID: context.blockId);
            context.blockNotifier.selectionModeDisable();
          },
        ),
      ),

      // Bottom center dot
      Positioned(
        left: (hitboxWidth / 2) - (kSelectionDotSize / 2),
        bottom: 0,
        child: _SelectionDot(
          onTap: () {
            String newBlockID = FirestoreIdGenerator.generate();
            context.ref.read(canvasProvider.notifier).addBlock(newBlockID, Offset(context.blockNotifier.position.dx, context.blockNotifier.position.dy + 300), department: getDepartment());
            context.ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: context.blockId, childBlockID: newBlockID);
            context.blockNotifier.selectionModeDisable();
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
            Offset newPosition = Offset(context.blockNotifier.position.dx + 300, context.blockNotifier.position.dy);

            context.ref.read(canvasProvider.notifier).addBlock(newBlockID, newPosition, department: getDepartment());

            String? parentID = _findParentOfBlock(context.ref, context.blockId);
            if (parentID != null) {
              context.ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: parentID, childBlockID: newBlockID);
            }
            context.blockNotifier.selectionModeDisable();
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
            Offset newPosition = Offset(context.blockNotifier.position.dx - 300, context.blockNotifier.position.dy);

            context.ref.read(canvasProvider.notifier).addBlock(newBlockID, newPosition, department: getDepartment());

            String? parentID = _findParentOfBlock(context.ref, context.blockId);
            if (parentID != null) {
              context.ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: parentID, childBlockID: newBlockID);
            }
            context.blockNotifier.selectionModeDisable();
          },
        ),
      ),
    ];
  }
  
  Widget getBlockDataDisplay(BlockContext context, double hitboxOffset);
  BoxDecoration getDecoration(BlockContext context);

  void onTap(BlockContext context) {
    if (context.blockNotifier.selectionMode) {
      context.blockNotifier.selectionModeDisable();
      context.ref.read(selectedBlockProvider.notifier).state = null;
    } else {
      context.blockNotifier.selectionModeEnable();
      context.ref.read(selectedBlockProvider.notifier).state = context.blockId;
      context.blockNotifier.updateDescendants(context.connectionManager.parentAndChildren);
    }
  }

  void onDoubleTapDown(BlockContext context) {
    OverlayService.openBlockInputBox(
      context.buildContext,
      initialData: context.blockNotifier.blockData,
      onSave: (data) {
        context.blockNotifier.updateData(data);
      },
      onClose: () {},
    );
  }

// The same
  void onPanUpdate(BlockContext context, DragUpdateDetails details, double hitboxOffset) {
    // Convert global position to local canvas position
    final RenderBox? canvasBox = context.buildContext.findAncestorRenderObjectOfType<RenderBox>();
    if (canvasBox == null) return;
    final localPosition = canvasBox.globalToLocal(details.globalPosition);
    final newPosition = Offset(
      localPosition.dx - hitboxOffset,
      localPosition.dy - hitboxOffset,
    );

    // Check if block is selected and if it has any children. If yes then do batch move and batch firestore update
    // If not just move block and one doc update
    if (context.blockNotifier.selectionMode && context.blockNotifier.descendants.isNotEmpty) {
      Set<String> descendants = context.blockNotifier.descendants;
      final currentPosition = context.blockNotifier.position;
      final delta = newPosition - currentPosition;

      // Update the main block position immediately as well
      context.blockNotifier.updatePositionWithoutFirestore(newPosition);

      // Update UI immediately for all descendants and also collect new positons.
      Map<String, Offset> positions = {context.blockId: newPosition};
      for (var descendant in descendants) {
        final descendantNotifier = context.ref.read(blockNotifierProvider(descendant).notifier);
        final currentPos = descendantNotifier.position;
        final newPosition = currentPos + delta;
        descendantNotifier.updatePositionWithoutFirestore(newPosition);
        positions[descendant] = newPosition;
      }

      //Batch Firestore update with debounce. Goes through BlockNotifier.
      context.blockNotifier.batchUpdateDescendantPositions(positions);
    } else {
      // Move single block
      context.blockNotifier.updatePosition(newPosition);
    }
  }

  // Helper function to find parent of current block
  String? _findParentOfBlock(WidgetRef ref, String blockID) {
    final connections = ref.read(connectionManagerProvider).connections;
    for (final connection in connections) {
      if (connection.childId == blockID) {
        return connection.parentId;
      }
    }
    return null;
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
              color: Colors.black.withValues(alpha: 0.2),
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
