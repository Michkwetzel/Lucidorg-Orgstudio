import 'package:flutter/material.dart';

// Block Identification class. Not ideal to have this as its own class but only way to pass initial position to the providier.family setup
class BlockID {
  final String blockId;
  final Offset? initialPosition;

  const BlockID(this.blockId, [this.initialPosition]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlockID && other.blockId == blockId;
  }

  @override
  int get hashCode => blockId.hashCode;
}