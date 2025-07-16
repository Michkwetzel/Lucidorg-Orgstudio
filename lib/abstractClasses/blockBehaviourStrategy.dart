import 'package:flutter/material.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';

abstract class BlockBehaviorStrategy {
  double hitboxOffset(BlockContext context);
  double hitboxWidth(BlockContext context);
  double hitboxHeight(BlockContext context);
  void onTap(BlockContext context);
  void onDoubleTapDown(BlockContext context);
  void onPanUpdate(BlockContext context, DragUpdateDetails details);
}
