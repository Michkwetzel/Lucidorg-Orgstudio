import 'package:flutter/material.dart';
import 'package:flutter/src/gestures/drag_details.dart';
import 'package:platform_v2/abstractClasses/blockBehaviourStrategy.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

class OrgBuildStrategy implements BlockBehaviorStrategy {
  @override
  double hitboxWidth(BlockContext context) {
    return kBlockWidth + (hitboxOffset(context) * 2);
  }

  @override
  double hitboxHeight(BlockContext context) {
    return kBlockHeight + (hitboxOffset(context) * 2);
  }

  @override
  double hitboxOffset(BlockContext context) {
    return context.blockNotifier.selectionMode ? context.dotOverhang : 0.0;
  }

  @override
  void onTap(BlockContext context) {
    if (context.blockNotifier.selectionMode) {
      context.blockNotifier.selectionModeDisable();
      context.ref.read(selectedBlockProvider.notifier).state = null;
    } else {
      context.blockNotifier.selectionModeEnable();
      context.ref.read(selectedBlockProvider.notifier).state = context.blockId;
    }
  }

  @override
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

  @override
  void onPanUpdate(BlockContext context, DragUpdateDetails details) {
    // Convert global position to local canvas position
    final RenderBox? canvasBox = context.buildContext.findAncestorRenderObjectOfType<RenderBox>();
    if (canvasBox == null) return;
    final localPosition = canvasBox.globalToLocal(details.globalPosition);
    final newPosition = Offset(
      localPosition.dx - hitboxOffset(context),
      localPosition.dy - hitboxOffset(context),
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
}
