import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/firestoreIdGenerator.dart';
import 'package:platform_v2/widgets/components/general/orgBlock.dart';

class OrgCanvas extends ConsumerWidget {
  const OrgCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox.expand(
      child: InteractiveViewer(
        constrained: false,
        minScale: 0.1,
        maxScale: 10,
        boundaryMargin: EdgeInsets.all(20),
        child: Builder(
          builder: (context) {
            return DragTarget<Map<String, dynamic>>(
              onAcceptWithDetails: (details) {
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(details.offset);
                if (details.data['blockType'] == BlockType.add) {
                  final blockId = FirestoreIdGenerator.generate();
                  ref.read(canvasProvider.notifier).addBlock(blockId); // Add block ID to canvas
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(blockNotifierProvider(blockId).notifier).updatePosition(localPosition); //Created changeNotifier for block. Then updates position
                  });
                } else if (details.data['blockType'] == BlockType.existing) {
                  ref.read(blockNotifierProvider(details.data['id']).notifier).updatePosition(localPosition);
                }
              },
              builder: (context, candidateData, rejectedData) => Container(
                width: 3000,
                height: 3000,
                color: Colors.transparent,
                child: Stack(
                  children: ref.watch(blockListProvider).map((blockId) => OrgBlock(key: ValueKey(blockId), id: blockId)).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
