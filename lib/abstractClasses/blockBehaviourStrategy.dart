import 'package:flutter/material.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';

// The rulebook for what functions a strategy can impliment.
abstract class BlockBehaviorStrategy {
  // Visual Block Appearance
  BoxDecoration getDecoration(BlockContext context);
  Widget getBlockDataDisplay(BlockContext context, double hitboxOffset);
  List<Widget> getBlockSelectionModeWidgets(BlockContext context, double hitboxWidth, double hitboxHeight);

  // Block Functions
  void onTap(BlockContext context);
  void onDoubleTapDown(BlockContext context);
  void onPanUpdate(BlockContext context, DragUpdateDetails details, double hitboxOffset);
}
