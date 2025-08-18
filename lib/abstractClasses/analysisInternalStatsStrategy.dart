import 'package:flutter/material.dart';
import 'package:platform_v2/abstractClasses/analysisBlockBehaviorStrategy.dart';
import 'package:platform_v2/abstractClasses/analysisBlockContext.dart';
import 'package:platform_v2/config/constants.dart';

/// Strategy for analysis blocks that display internal statistics
class AnalysisInternalStatsStrategy extends AnalysisBlockBehaviorStrategy {
  @override
  Widget getBlockWidget(AnalysisBlockContext context) {
    return SizedBox(
      width: context.hitboxWidth,
      height: context.hitboxHeight,
      child: Container(
        margin: EdgeInsets.all(context.hitboxOffset),
        width: kBlockWidth,
        height: kBlockHeight,
        decoration: blockDecoration(context),
        child: blockData(context),
      ),
    );
  }

  @override
  Widget blockData(AnalysisBlockContext context) {
    final blockData = context.analysisBlockNotifier.blockData;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.insert_chart,
          size: 40,
          color: Colors.purple.shade700,
        ),
        const SizedBox(height: 8),
        Text(
          blockData.blockName.isNotEmpty ? blockData.blockName : 'Internal Stats',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Groups: ${blockData.groupIds.length}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Stats Charts',
            style: TextStyle(
              fontSize: 10,
              color: Colors.purple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  BoxDecoration blockDecoration(AnalysisBlockContext context) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.purple.shade300, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  @override
  void onTap(AnalysisBlockContext context) {
    // TODO: Implement internal stats block tap behavior
    // Could open stats configuration overlay, etc.
  }

  @override
  void onDoubleTapDown(AnalysisBlockContext context) {
    // TODO: Implement double tap behavior
    // Could open detailed stats view
  }

  @override
  void onPanUpdate(AnalysisBlockContext context, DragUpdateDetails details, double hitboxOffset) {
    // Handle block dragging
    final RenderBox? canvasBox = context.buildContext.findAncestorRenderObjectOfType<RenderBox>();
    if (canvasBox == null) return;
    
    final localPosition = canvasBox.globalToLocal(details.globalPosition);
    final newPosition = Offset(
      localPosition.dx - hitboxOffset,
      localPosition.dy - hitboxOffset,
    );
    
    context.analysisBlockNotifier.updatePosition(newPosition);
  }
}