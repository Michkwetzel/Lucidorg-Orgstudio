import 'package:flutter/material.dart';

class BlockParams {
  final String blockId;
  final Offset position;

  const BlockParams({required this.blockId, required this.position});

  @override
  bool operator ==(Object other) =>
      identical(
        this,
        other,
      ) ||
      other is BlockParams && runtimeType == other.runtimeType && blockId == other.blockId && position == other.position;

  @override
  int get hashCode => blockId.hashCode ^ position.hashCode;
}
