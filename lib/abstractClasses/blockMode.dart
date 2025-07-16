import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/notifiers/general/blockNotifier.dart';
import 'package:platform_v2/notifiers/general/connectionsManager.dart';
import 'package:platform_v2/notifiers/general/orgCanvasNotifier.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

//Base abstract block detailing possible functions
//
class BaseBlockMode {
  final BlockNotifier blockNotifier; // Represents the current block being selected
  final OrgCanvasNotifier orgCanvasNotifier;
  final ConnectionManager connectionManager;

  BaseBlockMode({
    required this.blockNotifier,
    required this.orgCanvasNotifier,
    required this.connectionManager,
  });

  String getDepartment() {
    return blockNotifier.blockData?.department ?? '';
  }

  void onTap(selectedBlockId) {
    // If block is selected. Deselect. Otherwise enable selection and get descendants if any
    if (blockNotifier.selectionMode) {
      blockNotifier.selectionModeDisable();
      selectedBlockId = null;
    } else {
      blockNotifier.selectionModeEnable();
      selectedBlockId = blockNotifier.blockID;
      blockNotifier.updateDescendants(blockNotifier.blockID, connectionManager.parentAndChildren);
    }
  }

  void onDoubleTapDown(BuildContext context) {
    // Open Data overlay
    OverlayService.openBlockInputBox(
      context,
      initialData: blockNotifier.blockData,
      onSave: (data) {
        blockNotifier.updateData(data);
      },
      onClose: () {},
    );
  }

  void onPanUpdate(BuildContext context, WidgetRef ref, DragUpdateDetails details, double hitboxOffset, String blockId) {
    // Convert global position to local canvas position
    final RenderBox? canvasBox = context.findAncestorRenderObjectOfType<RenderBox>();
    if (canvasBox == null) return;
    final localPosition = canvasBox.globalToLocal(details.globalPosition);
    final newPosition = Offset(
      localPosition.dx - hitboxOffset,
      localPosition.dy - hitboxOffset,
    );

    // Check if block is selected and if it has any children. If yes then do batch move and batch firestore update
    // If not just move block and one doc update
    if (blockNotifier.selectionMode && blockNotifier.descendants.isNotEmpty) {
      Set<String> descendants = blockNotifier.descendants;
      final currentPosition = blockNotifier.position;
      final delta = newPosition - currentPosition;

      // Update the main block position immediately as well
      ref.read(blockNotifierProvider(blockId).notifier).updatePositionWithoutFirestore(newPosition);

      // Update UI immediately for all descendants and also collect new positons.
      Map<String, Offset> positions = {blockId: newPosition};
      for (var descendant in descendants) {
        final descendantNotifier = ref.read(blockNotifierProvider(descendant).notifier);
        final currentPos = descendantNotifier.position;
        final newPosition = currentPos + delta;
        descendantNotifier.updatePositionWithoutFirestore(newPosition);
        positions[descendant] = newPosition;
      }

      //Batch Firestore update with debounce. Goes through BlockNotifier.
      blockNotifier.batchUpdateDescendantPositions(positions);
    } else {
      // Move single block
      blockNotifier.updatePosition(newPosition);
    }
  }
}

  // onTap();
  // onDoubleTap(TapDownDetails details);
  // onPanUpdate(DragUpdateDetails details, RenderBox? canvasBox);

  // onLeftTap();
  // onRightTap();
  // onTopTap();
  // onBottomTap();

  // BoxDecoration get decoration;
  // Widget get blockDataDisplay;
// class OrgBuildMode extends BaseBlockMode {
//   final BlockNotifier blockNotifier;
//   final OrgCanvasNotifier orgCanvasNotifier;
//   final ConnectionManager connectionManager;

//   OrgBuildMode(this.blockNotifier, this.orgCanvasNotifier, this.connectionManager);

//   @override
//   BlockMode get modeName => BlockMode.orgBuild;

//   @override
//   onTap() {
//     // TODO: implement onTap
//     throw UnimplementedError();
//   }
// }
