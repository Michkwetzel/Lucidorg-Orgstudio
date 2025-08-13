// Main overlay widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';

class CreateGroupOverlay extends ConsumerStatefulWidget {
  final Function(Options, String)? onCreate;
  final VoidCallback? onClose;

  const CreateGroupOverlay({
    super.key,
    this.onCreate,
    this.onClose,
  });

  @override
  ConsumerState<CreateGroupOverlay> createState() => _CreateGroupOverlayState();
}

class _CreateGroupOverlayState extends ConsumerState<CreateGroupOverlay> {
  final TextEditingController groupNameController = TextEditingController();
  Options selectedOption = Options.select;
  List<String> availableDepartments = [];

  void _handleCreate() {
    final groupName = groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    widget.onCreate?.call(selectedOption, groupName);
  }

  void _scanForDepartments() {
    final blockIds = ref.read(canvasProvider);
    final departments = <String>{};

    for (final blockId in blockIds) {
      final blockNotifier = ref.read(blockNotifierProvider(blockId));
      final blockData = blockNotifier.blockData;
      if (blockData != null && blockData.department.isNotEmpty) {
        departments.add(blockData.department);
      }
    }

    setState(() {
      availableDepartments = departments.toList()..sort();
    });
  }

  void _toggleDepartment(String department) {
    final selectedDepartments = ref.read(selectedDepartmentsProvider);
    final newSelectedDepartments = Set<String>.from(selectedDepartments);

    if (selectedDepartments.contains(department)) {
      newSelectedDepartments.remove(department);
    } else {
      newSelectedDepartments.add(department);
    }

    ref.read(selectedDepartmentsProvider.notifier).state = newSelectedDepartments;
    _updateSelectedBlocksFromDepartments(newSelectedDepartments);
  }

  void _updateSelectedBlocksFromDepartments(Set<String> selectedDepartments) {
    final blockIds = ref.read(canvasProvider);
    final selectedBlocks = <String>{};

    for (final blockId in blockIds) {
      final blockNotifier = ref.read(blockNotifierProvider(blockId));
      final blockData = blockNotifier.blockData;
      if (blockData != null && selectedDepartments.contains(blockData.department)) {
        selectedBlocks.add(blockId);
      }
    }

    ref.read(selectedBlocksProvider.notifier).state = selectedBlocks;
  }

  void _selectAllBlocks() {
    final blockIds = ref.read(canvasProvider);
    ref.read(selectedBlocksProvider.notifier).state = Set.from(blockIds);
    ref.read(selectedDepartmentsProvider.notifier).state = {};
  }

  void _handleOptionTap(Options option) {
    switch (option) {
      case Options.select:
        // Enable manual block selection mode
        ref.read(appStateProvider.notifier).setAssessmentMode(AssessmentMode.assessmentGroupCreate);
        break;
      case Options.department:
        _scanForDepartments();
        break;
      case Options.all:
        _selectAllBlocks();
        break;
    }
    setState(() => selectedOption = option);
  }

  @override
  void dispose() {
    groupNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Listen for app view changes
    ref.listenManual(appStateProvider.select((state) => state.appView), (previous, next) {
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
                          'Create Group',
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

                    // Group Name Input
                    const Text(
                      'Group Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: groupNameController,
                      decoration: const InputDecoration(
                        hintText: 'Enter group name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
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
                              isSelected: selectedOption == Options.select,
                              onTap: () => _handleOptionTap(Options.select),
                            ),
                          ),
                          Expanded(
                            child: SegmentedOption(
                              option: 'Department',
                              isSelected: selectedOption == Options.department,
                              onTap: () => _handleOptionTap(Options.department),
                            ),
                          ),
                          Expanded(
                            child: SegmentedOption(
                              option: 'All',
                              isSelected: selectedOption == Options.all,
                              onTap: () => _handleOptionTap(Options.all),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Department Selection Section
                    if (selectedOption == Options.department) ...[
                      const Text(
                        'Select Departments',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (availableDepartments.isNotEmpty)
                        Consumer(
                          builder: (context, ref, child) {
                            final selectedDepartments = ref.watch(selectedDepartmentsProvider);
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: availableDepartments.map((department) {
                                final isSelected = selectedDepartments.contains(department);
                                return FilterChip(
                                  label: Text(department),
                                  selected: isSelected,
                                  onSelected: (selected) => _toggleDepartment(department),
                                  selectedColor: Colors.blue.shade100,
                                  checkmarkColor: Colors.blue.shade700,
                                  backgroundColor: Colors.grey.shade100,
                                  side: BorderSide(
                                    color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                    ],

                    // Selected Blocks Section
                    if (selectedBlockIds.isNotEmpty && selectedOption != Options.department) ...[
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
                              ref.read(selectedDepartmentsProvider.notifier).state = {};
                              ref.read(appStateProvider.notifier).setAssessmentMode(AssessmentMode.assessmentDataView);
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
                            onPressed: selectedBlockIds.isNotEmpty ? _handleCreate : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Create Group'),
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