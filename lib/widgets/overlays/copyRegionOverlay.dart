import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CopyRegionOverlay extends ConsumerStatefulWidget {
  final Function(String sourceRegion, String targetRegion)? onCopy;
  final VoidCallback? onClose;

  const CopyRegionOverlay({
    super.key,
    this.onCopy,
    this.onClose,
  });

  @override
  ConsumerState<CopyRegionOverlay> createState() => _CopyRegionOverlayState();
}

class _CopyRegionOverlayState extends ConsumerState<CopyRegionOverlay> {
  String sourceRegion = '1';
  String targetRegion = '2';
  bool isProcessing = false;

  void _handleCopy() async {
    if (sourceRegion == targetRegion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source and target regions must be different')),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    widget.onCopy?.call(sourceRegion, targetRegion);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Copy Region Blocks',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Source Region
              Text(
                'Source Region',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final region = (i + 1).toString();
                  return FilterChip(
                    label: Text(region),
                    selected: sourceRegion == region,
                    onSelected: isProcessing
                        ? null
                        : (selected) {
                            if (selected) {
                              setState(() {
                                sourceRegion = region;
                              });
                            }
                          },
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Target Region
              Text(
                'Target Region',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final region = (i + 1).toString();
                  return FilterChip(
                    label: Text(region),
                    selected: targetRegion == region,
                    onSelected: isProcessing
                        ? null
                        : (selected) {
                            if (selected) {
                              setState(() {
                                targetRegion = region;
                              });
                            }
                          },
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Info Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'This will copy all blocks with department "Office" from region $sourceRegion to region $targetRegion, including their connections. New blocks will be offset +2000 on the x-axis.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isProcessing ? null : widget.onClose,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: isProcessing ? null : _handleCopy,
                    child: isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Copy Blocks'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
