// Main overlay widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/services/uiServices/overLayService.dart';

class SendAssessmentOverlay extends ConsumerStatefulWidget {
  final Function(String, String)? onSend;
  final VoidCallback? onClose;

  const SendAssessmentOverlay({
    super.key,
    this.onSend,
    this.onClose,
  });

  @override
  ConsumerState<SendAssessmentOverlay> createState() => _SendAssessmentOverlayState();
}

class _SendAssessmentOverlayState extends ConsumerState<SendAssessmentOverlay> {
  final TextEditingController textController = TextEditingController();
  String selectedOption = 'Select';

  void _handleSend() {
    final selectedBlockIds = ref.read(selectedBlocksProvider);

    if (selectedBlockIds.isNotEmpty) {
      // Show confirmation overlay
      OverlayService.openAssessmentSendConfirmationOverlay(
        context,
        onSend: () {
          // Handle actual send logic here in the future
          widget.onSend?.call(selectedOption, textController.text.trim());
        },
        onCancel: () {
          // Confirmation overlay cancelled, do nothing
        },
      );
    } else {
      // No blocks selected, proceed with original logic
      widget.onSend?.call(selectedOption, textController.text.trim());
    }
  }

  void _handleOptionTap(String option) {
    switch (option) {
      case 'Select':
        ref.read(appStateProvider.notifier).setAppMode(AppMode.assessmentSendSelectBlocks);
        break;
      case 'Department':
        // Handle department logic
        break;
      case 'All':
        // Handle all logic
        break;
    }
    setState(() => selectedOption = option);
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Listen for app view changes
    ref.listenManual(appStateProvider.select((state) => state.displayContext.appView), (previous, next) {
      if (next != AppView.assessmentBuild) {
        widget.onClose?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedBlockIds = ref.watch(selectedBlocksProvider);

    return Stack(
      children: [
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 450,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Send Assessment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close),
                          iconSize: 20,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Selection options (segmented buttons)
                    const Text(
                      'Selection Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SegmentedOption(
                              option: 'Select',
                              isSelected: selectedOption == 'Select',
                              onTap: () => _handleOptionTap('Select'),
                            ),
                          ),
                          Expanded(
                            child: SegmentedOption(
                              option: 'Department',
                              isSelected: selectedOption == 'Department',
                              onTap: () => _handleOptionTap('Department'),
                            ),
                          ),
                          Expanded(
                            child: SegmentedOption(
                              option: 'All',
                              isSelected: selectedOption == 'All',
                              onTap: () => _handleOptionTap('All'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selected Blocks Section
                    if (selectedBlockIds.isNotEmpty) ...[
                      const Text(
                        'Selected Blocks',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: selectedBlockIds.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (context, index) {
                            final blockId = selectedBlockIds.elementAt(index);
                            return Consumer(
                              builder: (context, ref, child) {
                                final blockNotifier = ref.watch(blockNotifierProvider(blockId));
                                final blockData = blockNotifier.blockData;

                                if (blockData == null) {
                                  return const ListTile(
                                    title: Text('Loading...'),
                                    dense: true,
                                  );
                                }

                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  title: Text(
                                    blockData.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (blockData.role.isNotEmpty)
                                        Text(
                                          'Role: ${blockData.role}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      if (blockData.department.isNotEmpty)
                                        Text(
                                          'Department: ${blockData.department}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      if (blockData.primaryEmail.isNotEmpty)
                                        Text(
                                          'Email: ${blockData.primaryEmail}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Handle cancel logic here
                              ref.read(selectedBlocksProvider.notifier).state = {};
                              ref.read(appStateProvider.notifier).setAppMode(AppMode.assessmentBuild);
                              widget.onClose?.call();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleSend,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Send'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Separate widget for segmented option
class SegmentedOption extends StatelessWidget {
  final String option;
  final bool isSelected;
  final VoidCallback onTap;

  const SegmentedOption({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = option == 'Select';
    final isLast = option == 'All';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? const Radius.circular(7) : Radius.zero,
            bottomLeft: isFirst ? const Radius.circular(7) : Radius.zero,
            topRight: isLast ? const Radius.circular(7) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(7) : Radius.zero,
          ),
          border: Border(
            right: !isLast ? BorderSide(color: Colors.grey.shade300, width: 0.5) : BorderSide.none,
          ),
        ),
        child: Text(
          option,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
