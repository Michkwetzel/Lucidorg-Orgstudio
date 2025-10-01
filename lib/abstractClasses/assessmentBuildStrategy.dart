import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/abstractClasses/blockBehaviourStrategy.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';
import 'package:platform_v2/abstractClasses/orgBuildStrategy.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/firestoreIDGenerator.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

//Class encapsulating Block behaviour and appearance in AssessmentBuild mode
class AssessmentBuildStrategy extends BlockBehaviorStrategy {
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

          if (context.blockNotifier.selected) ...buildDotWidgets(context),
        ],
      ),
    );
  }

  @override
  Widget blockData(BlockContext context) {
    final blockData = context.blockNotifier.blockData;
    final hasMultipleEmails = blockData?.hasMultipleEmails ?? false;
    final emailRatio = context.blockNotifier.emailStatusRatio;
    final hierarchy = blockData?.hierarchy;
    final showHierarchy = hierarchy != null && hierarchy != Hierarchy.none;

    return Column(
      spacing: 4,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          blockData?.name ?? "NO NAME",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Text(
          blockData?.role ?? "NO ROLE",
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black87,
          ),
        ),
        Text(
          blockData?.department ?? "NO DEPT",
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
        if (showHierarchy)
          Text(
            hierarchy.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        if (hasMultipleEmails && emailRatio.isNotEmpty)
          Text(
            emailRatio,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
      ],
    );
  }

  @override
  BoxDecoration blockDecoration(BlockContext context) {
    final hasMultipleEmails = context.blockNotifier.blockData?.hasMultipleEmails ?? false;
    
    // Determine base color based on status
    Color blockColor;
    BoxDecoration baseDecoration;

    if (hasMultipleEmails) {
      // Multi-email block logic
      final sent = context.blockNotifier.sent;
      final allSubmitted = context.blockNotifier.allEmailsSubmitted;
      final partialSubmitted = context.blockNotifier.partialEmailsSubmitted;

      if (!sent) {
        // White - No emails sent yet
        baseDecoration = kboxShadowNormal;
      } else if (allSubmitted) {
        // Green - All emails submitted
        blockColor = Colors.green[300]!;
        baseDecoration = kboxShadowNormal.copyWith(color: blockColor);
      } else {
        // Yellow - Some emails sent/submitted but not all
        blockColor = Colors.amber[300]!;
        baseDecoration = kboxShadowNormal.copyWith(color: blockColor);
      }

      // Always add border for multi-email blocks
      return baseDecoration.copyWith(
        border: Border.all(color: Colors.black, width: 2),
      );
    } else {
      // Single email block logic (unchanged)
      final sent = context.blockNotifier.sent;
      final submitted = context.blockNotifier.submitted;

      if (!sent) {
        // White - Assessment not sent yet
        baseDecoration = kboxShadowNormal;
      } else if (sent && !submitted) {
        // Amber - Assessment sent but not submitted
        blockColor = Colors.amber[300]!;
        baseDecoration = kboxShadowNormal.copyWith(color: blockColor);
      } else {
        // Green - Assessment submitted
        blockColor = Colors.green[300]!;
        baseDecoration = kboxShadowNormal.copyWith(color: blockColor);
      }

      return baseDecoration;
    }
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
}
