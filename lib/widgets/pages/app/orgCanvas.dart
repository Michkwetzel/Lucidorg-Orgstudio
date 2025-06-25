import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/dataClasses/blockParam.dart';
import 'package:platform_v2/services/firestoreIdGenerator.dart';
import 'package:platform_v2/widgets/components/general/orgBlock.dart';

class OrgCanvas extends ConsumerStatefulWidget {
  const OrgCanvas({super.key});

  @override
  ConsumerState<OrgCanvas> createState() => _OrgCanvasState();
}

class _OrgCanvasState extends ConsumerState<OrgCanvas> {
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    // Listen to transformation changes and update the scale provider
    _transformationController.addListener(() {
      final scale = _transformationController.value.getMaxScaleOnAxis();
      ref.read(canvasScaleProvider.notifier).state = scale;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: InteractiveViewer(
        transformationController: _transformationController,
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
                  ref.read(canvasProvider.notifier).addBlock(blockId, localPosition);
                } else if (details.data['blockType'] == BlockType.existing) {
                  ref.read(blockNotifierProvider(details.data['id']).notifier).updatePosition(localPosition);
                }
              },
              builder: (context, candidateData, rejectedData) => Container(
                width: 3000,
                height: 3000,
                color: Colors.transparent,
                child: Stack(
                  children: ref
                      .watch(blockListProvider)
                      .entries
                      .map(
                        (entry) => OrgBlock(
                          key: ValueKey(entry.key),
                          id: entry.key,
                          initialPosition: entry.value.position,
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
