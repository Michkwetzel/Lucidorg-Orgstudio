import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/abstractClasses/analysisBlockBehaviorStrategy.dart';
import 'package:platform_v2/abstractClasses/analysisBlockContext.dart';
import 'package:platform_v2/abstractClasses/analysisInternalStatsStrategy.dart';
import 'package:platform_v2/abstractClasses/analysisQuestionStrategy.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/notifiers/general/groupsNotifier.dart';

class AnalysisBlock extends ConsumerStatefulWidget {
  final String blockId;

  const AnalysisBlock({
    super.key,
    required this.blockId,
  });

  @override
  ConsumerState<AnalysisBlock> createState() => _AnalysisBlockState();
}

class _AnalysisBlockState extends ConsumerState<AnalysisBlock> {
  bool _isPanelExpanded = false;

  @override
  Widget build(BuildContext context) {
    const hitboxOffset = 0.0; // Analysis blocks don't have selection dots like regular blocks

    AnalysisBlockContext analysisBlockContext = AnalysisBlockContext(
      ref: ref,
      blockId: widget.blockId,
      buildContext: context,
      hitboxOffset: hitboxOffset,
    );

    // Watch the analysis block notifier to get the current state
    final analysisBlockState = ref.watch(analysisBlockNotifierProvider(widget.blockId));
    
    // Check if data is loaded
    if (!analysisBlockState.dataLoaded) {
      return const SizedBox.shrink();
    }

    // Select strategy based on analysis block type and subtype
    AnalysisBlockBehaviorStrategy strategy;
    switch (analysisBlockState.analysisBlockType) {
      case AnalysisBlockType.groupAnalysis:
      case AnalysisBlockType.groupComparison:
        // Both analysis types use the internal stats strategy with data visualization
        strategy = AnalysisInternalStatsStrategy();
        break;
      case AnalysisBlockType.none:
        // Default to question strategy for unconfigured blocks
        strategy = AnalysisQuestionStrategy();
        break;
    }

    return Positioned(
      left: analysisBlockState.position.dx - hitboxOffset,
      top: analysisBlockState.position.dy - hitboxOffset,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => strategy.onTap(analysisBlockContext),
        onDoubleTapDown: (details) => strategy.onDoubleTapDown(analysisBlockContext),
        onPanUpdate: (details) => strategy.onPanUpdate(analysisBlockContext, details, hitboxOffset),
        child: _buildIntegratedBlock(context, ref, analysisBlockState, strategy, analysisBlockContext),
      ),
    );
  }

  Widget _buildIntegratedBlock(BuildContext context, WidgetRef ref, dynamic analysisBlockState, AnalysisBlockBehaviorStrategy strategy, AnalysisBlockContext analysisBlockContext) {
    final groupsNotifier = ref.watch(groupsProvider);
    
    // Get block title based on analysis type
    String getBlockTitle() {
      switch (analysisBlockState.analysisBlockType) {
        case AnalysisBlockType.groupAnalysis:
          return 'Group Analysis';
        case AnalysisBlockType.groupComparison:
          return 'Group Comparison';
        case AnalysisBlockType.none:
        default:
          return 'Analysis Block';
      }
    }

    const blockWidth = 1500.0;
    const blockHeight = 500.0;

    return SizedBox(
      width: blockWidth,
      height: blockHeight,
      child: Container(
        width: blockWidth,
        height: blockHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade300, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with title and controls
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.purple.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Block title
                  Expanded(
                    child: Text(
                      getBlockTitle(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                  ),
                  // Delete button
                  IconButton(
                    onPressed: () async {
                      // Show confirmation dialog
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete Analysis Block'),
                            content: const Text('Are you sure you want to delete this analysis block? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );

                      if (shouldDelete == true && mounted) {
                        try {
                          await ref.read(analysisBlockNotifierProvider(widget.blockId)).deleteBlock();
                          // Remove from canvas
                          ref.read(canvasProvider.notifier).deleteBlock(widget.blockId);
                        } catch (e) {
                          // Show error message
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error deleting block: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red.shade600,
                      size: 18,
                    ),
                    tooltip: 'Delete Analysis Block',
                  ),
                  // Minimize/Expand chevron
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isPanelExpanded = !_isPanelExpanded;
                      });
                    },
                    icon: Icon(
                      _isPanelExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 20,
                      color: Colors.purple.shade600,
                    ),
                    tooltip: _isPanelExpanded ? 'Minimize' : 'Expand',
                  ),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: _buildContent(context, ref, analysisBlockState, groupsNotifier, strategy, analysisBlockContext),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, dynamic analysisBlockState, dynamic groupsNotifier, AnalysisBlockBehaviorStrategy strategy, AnalysisBlockContext analysisBlockContext) {
    return Column(
      children: [
        // Configuration controls (collapsible)
        if (_isPanelExpanded)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.purple.shade100, width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Analysis Type & Focus Configuration  
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analysis Type',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<AnalysisBlockType>(
                        value: analysisBlockState.analysisBlockType == AnalysisBlockType.none ? null : analysisBlockState.analysisBlockType,
                        isExpanded: true,
                        hint: Text('Select Type'),
                        items: [
                          DropdownMenuItem(value: AnalysisBlockType.groupAnalysis, child: Text('Group Analysis')),
                          DropdownMenuItem(value: AnalysisBlockType.groupComparison, child: Text('Group Comparison')),
                        ],
                        onChanged: (AnalysisBlockType? newType) {
                          if (newType != null) {
                            ref.read(analysisBlockNotifierProvider(widget.blockId)).changeBlockType(newType);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (analysisBlockState.analysisBlockType != AnalysisBlockType.none) ...[
                        const Text('Analysis Focus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        DropdownButton<AnalysisSubType>(
                          value: analysisBlockState.analysisSubType == AnalysisSubType.none ? null : analysisBlockState.analysisSubType,
                          isExpanded: true,
                          hint: Text('Select Focus'),
                          items: [
                            DropdownMenuItem(value: AnalysisSubType.indicators, child: Text('Indicators')),
                            DropdownMenuItem(value: AnalysisSubType.questions, child: Text('Questions')),
                          ],
                          onChanged: (AnalysisSubType? newSubType) {
                            if (newSubType != null) {
                              ref.read(analysisBlockNotifierProvider(widget.blockId)).changeSubType(newSubType);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column: Groups Selection
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysisBlockState.analysisBlockType == AnalysisBlockType.groupAnalysis ? 'Selected Group (1 only)' : 'Selected Groups',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if (analysisBlockState.groupIds.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: analysisBlockState.groupIds.map<Widget>((groupId) {
                            final group = groupsNotifier.groups.firstWhere(
                              (g) => g.id == groupId,
                              orElse: () => GroupData(id: groupId, groupName: 'Unknown Group', dataDocIds: [], blockIds: [], averagedRawResults: [], createdAt: ''),
                            );
                            return Chip(
                              label: Text(group.groupName, style: const TextStyle(fontSize: 10)),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () => ref.read(analysisBlockNotifierProvider(widget.blockId)).removeGroup(groupId),
                              backgroundColor: Colors.blue.shade100,
                              side: BorderSide(color: Colors.blue.shade300),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        )
                      else
                        Text('No groups selected', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 8),
                      if (groupsNotifier.groups.isNotEmpty)
                        SizedBox(
                          width: 200,
                          child: DropdownButton<String>(
                            hint: Text(analysisBlockState.analysisBlockType == AnalysisBlockType.groupAnalysis ? 'Select Group' : 'Add Group', style: TextStyle(fontSize: 11)),
                            isExpanded: true,
                            items: groupsNotifier.groups.where((group) => 
                              analysisBlockState.analysisBlockType == AnalysisBlockType.groupAnalysis ? true : !analysisBlockState.groupIds.contains(group.id)
                            ).map<DropdownMenuItem<String>>((group) => DropdownMenuItem<String>(value: group.id, child: Text(group.groupName, style: const TextStyle(fontSize: 11)))).toList(),
                            onChanged: (String? groupId) {
                              if (groupId != null) {
                                ref.read(analysisBlockNotifierProvider(widget.blockId)).addGroup(groupId);
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Data visualization area (always visible)
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: strategy.blockData(analysisBlockContext),
            ),
          ),
        ),
      ],
    );
  }
}