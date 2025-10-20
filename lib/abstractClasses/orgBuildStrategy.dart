import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/abstractClasses/blockBehaviourStrategy.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/firestoreIdGenerator.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';
import 'package:platform_v2/services/uiServices/alertService.dart';
import 'package:platform_v2/widgets/components/general/officeBadge.dart';

//Class encapsulating Block behaviour and appearance in OrgBuild mode
class OrgBuildStrategy extends BlockBehaviorStrategy {
  @override
  Widget getBlockWidget(BlockContext context) {
    return SizedBox(
      width: context.hitboxWidth,
      height: context.hitboxHeight,
      child: Stack(
        children: [
          Positioned(
            left: context.hitboxOffset,
            top: context.hitboxOffset,
            child: Container(
              width: kBlockWidth,
              height: kBlockHeight,
              decoration: blockDecoration(context),
              child: blockData(context),
            ),
          ),

          // // Region badge (top-left)
          // if (context.blockNotifier.blockData?.region.isNotEmpty == true)
          //   Positioned(
          //     left: context.hitboxOffset + 3,
          //     top: context.hitboxOffset + 3,
          //     child: OfficeBadge(
          //       value: context.blockNotifier.blockData!.region,
          //       isTopLeft: true,
          //     ),
          //   ),

          // // SubOffice badge (top-right)
          // if (context.blockNotifier.blockData?.subOffice.isNotEmpty == true)
          //   Positioned(
          //     right: context.hitboxOffset + 3,
          //     top: context.hitboxOffset + 3,
          //     child: OfficeBadge(
          //       value: context.blockNotifier.blockData!.subOffice,
          //       isTopLeft: false,
          //     ),
          //   ),

          if (context.blockNotifier.selected) ...buildDotWidgets(context),
        ],
      ),
    );
  }

  @override
  Widget blockData(BlockContext context) {
    final blockData = context.blockNotifier.blockData;
    final hierarchy = blockData?.hierarchy;
    final showHierarchy = hierarchy != null && hierarchy != Hierarchy.none;

    return Column(
      spacing: 4,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(blockData?.name ?? ""),
        Text(blockData?.role ?? ""),
        Text(blockData?.department ?? ""),
        if (showHierarchy)
          Text(
            hierarchy.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  List<Widget> buildDotWidgets(BlockContext context) {
    String getDepartment() {
      return context.blockNotifier.blockData?.department ?? '';
    }

    return [
      // Dropdown menu
      Positioned(
        top: 38,
        right: 38,
        child: BlockDropdownMenu(blockId: context.blockId),
      ),

      // Top center dot
      Positioned(
        left: (context.hitboxWidth / 2) - (kSelectionDotSize / 2),
        top: 0,
        child: SelectionDot(
          onTap: () {
            String newBlockId = FirestoreIdGenerator.generate();
            Offset newPosition = Offset(context.blockNotifier.position.dx, context.blockNotifier.position.dy - 300);

            context.ref.read(canvasProvider.notifier).addBlock(newBlockId, newPosition, department: getDepartment());
            context.ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockId: newBlockId, childBlockId: context.blockId);
            context.blockNotifier.onDeSelect();
          },
        ),
      ),

      // Bottom center dot
      Positioned(
        left: (context.hitboxWidth / 2) - (kSelectionDotSize / 2),
        bottom: 0,
        child: SelectionDot(
          onTap: () {
            String newBlockId = FirestoreIdGenerator.generate();
            context.ref.read(canvasProvider.notifier).addBlock(newBlockId, Offset(context.blockNotifier.position.dx, context.blockNotifier.position.dy + 300), department: getDepartment());
            context.ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockId: context.blockId, childBlockId: newBlockId);
            context.blockNotifier.onDeSelect();
          },
        ),
      ),

      // Right center dot
      Positioned(
        right: 0,
        top: (context.hitboxHeight / 2) - (kSelectionDotSize / 2),
        child: SelectionDot(
          onTap: () {
            String newBlockId = FirestoreIdGenerator.generate();
            Offset newPosition = Offset(context.blockNotifier.position.dx + 300, context.blockNotifier.position.dy);

            context.ref.read(canvasProvider.notifier).addBlock(newBlockId, newPosition, department: getDepartment());

            String? parentId = _findParentOfBlock(context.ref, context.blockId);
            if (parentId != null) {
              context.ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockId: parentId, childBlockId: newBlockId);
            }
            context.blockNotifier.onDeSelect();
          },
        ),
      ),

      // Left center dot
      Positioned(
        left: 0,
        top: (context.hitboxHeight / 2) - (kSelectionDotSize / 2),
        child: SelectionDot(
          onTap: () {
            String newBlockId = FirestoreIdGenerator.generate();
            Offset newPosition = Offset(context.blockNotifier.position.dx - 300, context.blockNotifier.position.dy);

            context.ref.read(canvasProvider.notifier).addBlock(newBlockId, newPosition, department: getDepartment());

            String? parentId = _findParentOfBlock(context.ref, context.blockId);
            if (parentId != null) {
              context.ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockId: parentId, childBlockId: newBlockId);
            }
            context.blockNotifier.onDeSelect();
          },
        ),
      ),
    ];
  }

  @override
  BoxDecoration blockDecoration(BlockContext context) {
    if (context.blockNotifier.selected) {
      return kboxShadowNormal.copyWith(border: Border.all(color: Colors.blue, width: 2));
    } else if (context.blockNotifier.blockData?.hasMultipleEmails ?? false) {
      return kboxShadowNormal.copyWith(border: Border.all(color: Colors.black, width: 2));
    }
    return kboxShadowNormal;
  }

  @override
  void onTap(BlockContext context) {
    print(context.blockId);

    if (context.blockNotifier.selected) {
      context.blockNotifier.onDeSelect();
      context.ref.read(selectedBlockProvider.notifier).state = null;
    } else {
      context.blockNotifier.onSelect();
      context.ref.read(selectedBlockProvider.notifier).state = context.blockId;
      context.blockNotifier.updateDescendants(context.connectionManager.parentAndChildren);
    }
  }

  @override
  void onDoubleTapDown(BlockContext context) {
    OverlayService.showBlockInput(
      context.buildContext,
      blockId: context.blockId,
      initialData: context.blockNotifier.blockData,
      onSave: (data) {
        context.blockNotifier.updateData(data);
      },
      onCancel: () {},
    );
  }

  @override
  void onPanUpdate(BlockContext context, DragUpdateDetails details, double hitboxOffset) {
    // Convert global position to local canvas position
    final RenderBox? canvasBox = context.buildContext.findAncestorRenderObjectOfType<RenderBox>();
    if (canvasBox == null) return;
    final localPosition = canvasBox.globalToLocal(details.globalPosition);
    final newPosition = Offset(
      localPosition.dx,
      localPosition.dy,
    );

    // Check if block is selected and if it has any children. If yes then do batch move and batch firestore update
    // If not just move block and one doc update
    if (context.blockNotifier.selected && context.blockNotifier.descendants.isNotEmpty) {
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
  String? _findParentOfBlock(WidgetRef ref, String blockId) {
    final connections = ref.read(connectionManagerProvider).connections;
    for (final connection in connections) {
      if (connection.childId == blockId) {
        return connection.parentId;
      }
    }
    return null;
  }
}

class SelectionDot extends StatelessWidget {
  final VoidCallback onTap;

  const SelectionDot({
    super.key,
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

class BlockDropdownMenu extends ConsumerWidget {
  final String blockId;

  const BlockDropdownMenu({super.key, required this.blockId});

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

  void _handleSelection(String value, WidgetRef ref) async {
    if (value == 'delete') {
      final blockNotifier = ref.read(blockNotifierProvider(blockId));

      // Check if block has data docs
      if (blockNotifier.hasDataDocs) {
        final dataDocsCount = blockNotifier.dataDocsCount;
        final withResults = blockNotifier.dataDocsWithResultsCount;

        final message = dataDocsCount == 1
            ? 'This block has 1 data document${withResults > 0 ? ' with submitted results' : ''}. Deleting this block will also delete all associated data. Continue?'
            : 'This block has $dataDocsCount data documents${withResults > 0 ? ', $withResults with submitted results' : ''}. Deleting this block will also delete all associated data. Continue?';

        await AlertService.showConfirmation(
          title: 'Delete Block with Data',
          message: message,
          confirmText: 'Delete',
          cancelText: 'Cancel',
          onConfirm: () {
            ref.read(canvasProvider.notifier).deleteBlock(blockId);
          },
        );
      } else {
        // No data docs, delete directly
        ref.read(canvasProvider.notifier).deleteBlock(blockId);
      }
    }
  }
}
