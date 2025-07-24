import 'package:flutter/material.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';

// The rulebook for what functions a strategy can implement.
abstract class BlockBehaviorStrategy {

  // Final block Widget build by Block.
  Widget getBlockWidget(BlockContext context);

  Widget blockData(BlockContext context);

  BoxDecoration blockDecoration(BlockContext context);

  void onTap(BlockContext context);

  void onDoubleTapDown(BlockContext context);

  void onPanUpdate(BlockContext context, DragUpdateDetails details, double hitboxOffset);
}
