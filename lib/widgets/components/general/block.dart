import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/dataClasses/blockId.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

class Block extends ConsumerStatefulWidget {
  final String blockId;
  final Offset initialPosition;

  const Block({
    super.key,
    required this.blockId,
    this.initialPosition = Offset.zero,
  });

  @override
  ConsumerState<Block> createState() => _BlockState();
}

class _BlockState extends ConsumerState<Block> {
  late final BlockID blockID;

  @override
  void initState() {
    super.initState();
    // Create BlockID once in initState to prevent recreation on every build
    blockID = BlockID(widget.blockId, widget.initialPosition);
  }

  @override
  Widget build(BuildContext context) {
    final blockNotifier = ref.watch(blockNotifierProvider(blockID));
    final BlockData? blockData = blockNotifier.blockData;

    return Positioned(
      left: blockNotifier.position.dx,
      top: blockNotifier.position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () {
          debugPrint('Long press - enabling connection mode for ${widget.blockId}');
          ref.read(blockNotifierProvider(blockID).notifier).toggleConnectionMode();
          ref.read(connectionManagerProvider.notifier).connectionModeEnable(widget.blockId, ConnectionType.parent);
        },
        onTap: () {
          ref.read(connectionManagerProvider.notifier).createConnection(widget.blockId);
        },
        onDoubleTapDown: (details) {
          OverlayService.openBlockInputBox(
            context,
            onSave: (data) {
              ref.read(blockNotifierProvider(blockID).notifier).updateData(data);
            },
            onClose: () {
              debugPrint('Close pressed - handle cleanup if needed');
            },
          );
        },
        onPanUpdate: (details) {
          // Convert global position to local canvas position
          final RenderBox? canvasBox = context.findAncestorRenderObjectOfType<RenderBox>();
          if (canvasBox != null) {
            final localPosition = canvasBox.globalToLocal(details.globalPosition);
            final adjustedPosition = Offset(
              localPosition.dx - 60,
              localPosition.dy - 50,
            );
            ref.read(blockNotifierProvider(blockID).notifier).updatePosition(adjustedPosition);
          }
        },
        child: Container(
          width: 120,
          height: 100,
          decoration: blockNotifier.connectionMode ? kRedBox : kboxShadowNormal,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: blockData == null
                      ? const Center(child: Text("New Block"))
                      : Column(
                          spacing: 4,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(blockData.name),
                            Text(blockData.role),
                            Text(blockData.department),
                          ],
                        ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz,
                    size: 16,
                    color: Colors.grey,
                  ),
                  iconSize: 16,
                  padding: const EdgeInsets.all(4),
                  onSelected: (value) {
                    if (value == 'delete') {
                      ref.read(canvasProvider.notifier).deleteBlock(widget.blockId);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
