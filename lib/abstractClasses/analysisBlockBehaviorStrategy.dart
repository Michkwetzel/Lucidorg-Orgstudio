import 'package:flutter/material.dart';
import 'package:platform_v2/abstractClasses/analysisBlockContext.dart';

/// Base class for analysis block behavior strategies
/// Defines the interface for how analysis blocks should behave and appear
abstract class AnalysisBlockBehaviorStrategy {
  /// Returns the complete widget structure for the analysis block
  Widget getBlockWidget(AnalysisBlockContext context);

  /// Returns the content/data widget inside the analysis block
  Widget blockData(AnalysisBlockContext context);

  /// Returns the decoration (styling, borders, etc.) for the analysis block
  BoxDecoration blockDecoration(AnalysisBlockContext context);

  /// Handles tap events on the analysis block
  void onTap(AnalysisBlockContext context);

  /// Handles double tap events on the analysis block
  void onDoubleTapDown(AnalysisBlockContext context);

  /// Handles pan/drag events on the analysis block
  void onPanUpdate(AnalysisBlockContext context, DragUpdateDetails details, double hitboxOffset);
}