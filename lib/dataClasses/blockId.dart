import 'package:flutter/material.dart';

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