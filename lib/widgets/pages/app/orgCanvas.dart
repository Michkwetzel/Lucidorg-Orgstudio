import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/constants.dart';
import 'package:platform_v2/config/provider.dart';

class OrgCanvas extends ConsumerWidget {
  const OrgCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox.expand(
      child: InteractiveViewer(
        constrained: false,
        minScale: 0.1,
        maxScale: 5.0,
        boundaryMargin: EdgeInsets.all(20),
        child: Builder(
          builder: (context) {
            //TODO: note that gesture detector is not needed. unless i need clicking functionality.
            return GestureDetector(
              onTapDown: (details) {
                // Convert global to local coordinates
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(details.globalPosition);
                print('Canvas tap at local: $localPosition');
                print('Canvas tap at global: ${details.globalPosition}');
              },
              child: DragTarget<String>(
                onAcceptWithDetails: (details) {
                  final RenderBox renderBox = context.findRenderObject() as RenderBox;
                  final localPosition = renderBox.globalToLocal(details.offset);
                  print(localPosition);

                  ref.read(canvasProvider.notifier).addBlock(localPosition.dx, localPosition.dy);
                },
                builder: (context, candidateData, rejectedData) => Container(
                  width: 3000,
                  height: 3000,
                  color: Colors.transparent,
                  child: Stack(
                    children: ref.watch(canvasProvider),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
