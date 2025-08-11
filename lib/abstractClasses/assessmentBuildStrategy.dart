import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/abstractClasses/blockBehaviourStrategy.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';
import 'package:platform_v2/abstractClasses/orgBuildStrategy.dart';
import 'package:platform_v2/config/constants.dart';
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
    // print('AssessmentBuildStrategy blockData: name=${blockData?.name}, role=${blockData?.role}, department=${blockData?.department}');
    // print('AssessmentBuildStrategy blockData null? ${blockData == null}');

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
      ],
    );
  }

  @override
  BoxDecoration blockDecoration(BlockContext context) {
    final sent = context.blockNotifier.sent;
    final submitted = context.blockNotifier.submitted;

    // print(sent);
    // print(submitted);
    // Color based on explicit assessment status flags
    Color blockColor;

    if (!sent) {
      // White - Assessment not sent yet (same as orgBuild)
      return kboxShadowNormal;
    } else if (sent && !submitted) {
      // Amber - Assessment sent but not submitted
      blockColor = Colors.amber[300]!;
    } else {
      // Green - Assessment submitted
      blockColor = Colors.green[300]!;
    }

    return kboxShadowNormal.copyWith(color: blockColor);
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
            String newBlockID = FirestoreIdGenerator.generate();
            Offset newPosition = Offset(context.blockNotifier.position.dx, context.blockNotifier.position.dy - 300);

            context.ref.read(canvasProvider.notifier).addBlock(newBlockID, newPosition, department: getDepartment());
            context.ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: newBlockID, childBlockID: context.blockId);
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
            String newBlockID = FirestoreIdGenerator.generate();
            context.ref.read(canvasProvider.notifier).addBlock(newBlockID, Offset(context.blockNotifier.position.dx, context.blockNotifier.position.dy + 300), department: getDepartment());
            context.ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: context.blockId, childBlockID: newBlockID);
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
            String newBlockID = FirestoreIdGenerator.generate();
            Offset newPosition = Offset(context.blockNotifier.position.dx + 300, context.blockNotifier.position.dy);

            context.ref.read(canvasProvider.notifier).addBlock(newBlockID, newPosition, department: getDepartment());

            String? parentID = _findParentOfBlock(context.ref, context.blockId);
            if (parentID != null) {
              context.ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: parentID, childBlockID: newBlockID);
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
            String newBlockID = FirestoreIdGenerator.generate();
            Offset newPosition = Offset(context.blockNotifier.position.dx - 300, context.blockNotifier.position.dy);

            context.ref.read(canvasProvider.notifier).addBlock(newBlockID, newPosition, department: getDepartment());

            String? parentID = _findParentOfBlock(context.ref, context.blockId);
            if (parentID != null) {
              context.ref.read(connectionManagerProvider.notifier).createDirectConnection(parentBlockID: parentID, childBlockID: newBlockID);
            }
            context.blockNotifier.onDeSelect();
          },
        ),
      ),
    ];
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

  @override
  void onTap(BlockContext context) {
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
