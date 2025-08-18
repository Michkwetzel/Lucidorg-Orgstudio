import 'package:flutter/material.dart';
import 'package:platform_v2/abstractClasses/analysisBlockBehaviorStrategy.dart';
import 'package:platform_v2/abstractClasses/analysisBlockContext.dart';
import 'package:platform_v2/config/constants.dart';

/// Strategy for analysis blocks that display benchmark indicator charts
class AnalysisIndicatorStrategy extends AnalysisBlockBehaviorStrategy {
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
          Icons.analytics,
          size: 40,
          color: Colors.green.shade700,
        ),
        const SizedBox(height: 8),
        Text(
          blockData.blockName.isNotEmpty ? blockData.blockName : 'Indicator Analysis',
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
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Benchmark Charts',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green,
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
      border: Border.all(color: Colors.green.shade300, width: 2),
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
    // TODO: Implement indicator analysis block tap behavior
    // Could open benchmark selection overlay, etc.
  }

  @override
  void onDoubleTapDown(AnalysisBlockContext context) {
    // TODO: Implement double tap behavior
    // Could open detailed indicator chart view
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