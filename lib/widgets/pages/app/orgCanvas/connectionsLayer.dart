import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/customPainters/connectionPainter.dart';

class ConnectionLayer extends ConsumerWidget {
  const ConnectionLayer({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(connectionManagerProvider).connections;
    final activeBlocks = ref.watch(canvasProvider);

    // Only care about blocks that are part of actual connections
    final connectionBlockIds = connections.expand((conn) => [conn.parentId, conn.childId]).toSet().intersection(activeBlocks);

    // Check if connection-relevant blocks are ready
    final readyConnectionBlocks = connectionBlockIds.where((blockId) => ref.watch(blockNotifierProvider(blockId).select((s) => s.positionLoaded))).toSet();

    if (readyConnectionBlocks.isEmpty) {
      return const SizedBox.shrink();
    }

    // Only watch providers for blocks that are both ready AND part of connections
    Map<String, Offset> blockPositions = {};
    for (final blockId in readyConnectionBlocks) {
      blockPositions[blockId] = ref.watch(blockNotifierProvider(blockId).select((s) => s.position));
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: ConnectionsPainter(
          connections: connections,
          blockPositions: blockPositions,
        ),
        size: const Size(7000, 7000),
      ),
    );
  }
}
