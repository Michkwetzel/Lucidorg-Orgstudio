import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GenerateMockDataOverlay extends ConsumerStatefulWidget {
  final Function(String region, int variationLevel)? onGenerate;
  final VoidCallback? onClose;

  const GenerateMockDataOverlay({
    super.key,
    this.onGenerate,
    this.onClose,
  });

  @override
  ConsumerState<GenerateMockDataOverlay> createState() => _GenerateMockDataOverlayState();
}

class _GenerateMockDataOverlayState extends ConsumerState<GenerateMockDataOverlay> {
  String selectedRegion = '1';
  int variationLevel = 2;
  bool isProcessing = false;

  void _handleGenerate() async {
    setState(() {
      isProcessing = true;
    });

    widget.onGenerate?.call(selectedRegion, variationLevel);
  }

  String _getRegionName(String region) {
    const regionNames = {
      '1': 'Northeast (Best)',
      '2': 'Mid-Atlantic',
      '3': 'Southeast (Problem)',
      '4': 'Midwest',
      '5': 'Texas',
      '6': 'West Coast',
      '7': 'Mountain/NW (Problem)',
    };
    return regionNames[region] ?? 'Region $region';
  }

  String _getExpectedDocs() {
    // Estimate: 1 Regional Director + 7 offices × 8 blocks
    // Of those: 21 team blocks × 10 responses + 36 other blocks × 1 response
    // = 210 + 36 + 1 = 247-253 docs per region
    return '~253';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
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
                    'Generate Mock Data',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Region Selector
              Text(
                'Select Region',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final region = (i + 1).toString();
                  final isSelected = selectedRegion == region;
                  return FilterChip(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          region,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          _getRegionName(region).split(' ').skip(1).join(' '),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: isProcessing
                        ? null
                        : (selected) {
                            if (selected) {
                              setState(() {
                                selectedRegion = region;
                              });
                            }
                          },
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Variation Level Slider
              Text(
                'Response Variation: ${variationLevel == 0 ? "None" : variationLevel == 1 ? "Low" : variationLevel == 2 ? "Medium" : "High"}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Slider(
                value: variationLevel.toDouble(),
                min: 0,
                max: 3,
                divisions: 3,
                label: variationLevel == 0
                    ? "None"
                    : variationLevel == 1
                        ? "Low"
                        : variationLevel == 2
                            ? "Medium"
                            : "High",
                onChanged: isProcessing
                    ? null
                    : (value) {
                        setState(() {
                          variationLevel = value.round();
                        });
                      },
              ),
              Text(
                'Controls how much individual team members\' responses vary (±${variationLevel} per question)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Region ${selectedRegion}: ${_getRegionName(selectedRegion)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Will generate ${_getExpectedDocs()} data docs for Office department blocks in this region.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Team blocks: 10 responses each\n'
                      '• Other hierarchies: 1 response each\n'
                      '• Scores based on DLA Piper regional patterns',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
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
                  FilledButton.icon(
                    onPressed: isProcessing ? null : _handleGenerate,
                    icon: isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: const Text('Generate'),
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
