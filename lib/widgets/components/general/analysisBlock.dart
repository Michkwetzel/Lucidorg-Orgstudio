import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/abstractClasses/analysisBlockBehaviorStrategy.dart';
import 'package:platform_v2/abstractClasses/analysisBlockContext.dart';
import 'package:platform_v2/abstractClasses/analysisIndicatorStrategy.dart';
import 'package:platform_v2/abstractClasses/analysisInternalStatsStrategy.dart';
import 'package:platform_v2/abstractClasses/analysisQuestionStrategy.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/notifiers/general/groupsNotifier.dart';

class AnalysisBlock extends ConsumerWidget {
  final String blockId;

  const AnalysisBlock({
    super.key,
    required this.blockId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const dotOverhang = 38.0;
    const hitboxOffset = 0.0; // Analysis blocks don't have selection dots like regular blocks

    AnalysisBlockContext analysisBlockContext = AnalysisBlockContext(
      ref: ref,
      blockId: blockId,
      buildContext: context,
      hitboxOffset: hitboxOffset,
    );

    // Watch the analysis block notifier to get the current state
    final analysisBlockState = ref.watch(analysisBlockNotifierProvider(blockId));
    
    // Check if data is loaded
    if (!analysisBlockState.dataLoaded) {
      return const SizedBox.shrink();
    }

    // Select strategy based on analysis block type
    AnalysisBlockBehaviorStrategy strategy;
    switch (analysisBlockState.analysisBlockType) {
      case AnalysisBlockType.question:
        strategy = AnalysisQuestionStrategy();
        break;
      case AnalysisBlockType.indicator:
        strategy = AnalysisIndicatorStrategy();
        break;
      case AnalysisBlockType.internalStats:
        strategy = AnalysisInternalStatsStrategy();
        break;
      case AnalysisBlockType.none:
      default:
        // Default to question strategy for now
        strategy = AnalysisQuestionStrategy();
        break;
    }

    return Positioned(
      left: analysisBlockState.position.dx - hitboxOffset,
      top: analysisBlockState.position.dy - hitboxOffset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => strategy.onTap(analysisBlockContext),
            onDoubleTapDown: (details) => strategy.onDoubleTapDown(analysisBlockContext),
            onPanUpdate: (details) => strategy.onPanUpdate(analysisBlockContext, details, hitboxOffset),
            child: strategy.getBlockWidget(analysisBlockContext),
          ),
          const SizedBox(height: 8),
          _buildConfigurationPanel(ref, analysisBlockState),
        ],
      ),
    );
  }

  Widget _buildConfigurationPanel(WidgetRef ref, dynamic analysisBlockState) {
    final groupsNotifier = ref.watch(groupsProvider);
    
    if (!groupsNotifier.dataLoaded) {
      return const SizedBox(
        width: 200,
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Block Type Selection
          const Text(
            'Analysis Type',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButton<AnalysisBlockType>(
            value: analysisBlockState.analysisBlockType,
            isExpanded: true,
            items: [
              DropdownMenuItem(
                value: AnalysisBlockType.question,
                child: Text('Question Analysis'),
              ),
              DropdownMenuItem(
                value: AnalysisBlockType.indicator,
                child: Text('Indicator Analysis'),
              ),
              DropdownMenuItem(
                value: AnalysisBlockType.internalStats,
                child: Text('Internal Stats'),
              ),
            ],
            onChanged: (AnalysisBlockType? newType) {
              if (newType != null) {
                ref.read(analysisBlockNotifierProvider(blockId)).changeBlockType(newType);
              }
            },
          ),
          const SizedBox(height: 12),
          
          // Groups Selection
          const Text(
            'Selected Groups',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          
          // Show selected groups as chips
          if (analysisBlockState.groupIds.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: analysisBlockState.groupIds.map<Widget>((groupId) {
                final group = groupsNotifier.groups.firstWhere(
                  (g) => g.id == groupId,
                  orElse: () => GroupData(
                    id: groupId,
                    groupName: 'Unknown Group',
                    dataDocIds: [],
                    blockIds: [],
                    averagedRawResults: [],
                    createdAt: '',
                  ),
                );
                
                return Chip(
                  label: Text(
                    group.groupName,
                    style: const TextStyle(fontSize: 10),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    ref.read(analysisBlockNotifierProvider(blockId)).removeGroup(groupId);
                  },
                  backgroundColor: Colors.blue.shade100,
                  side: BorderSide(color: Colors.blue.shade300),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            )
          else
            Text(
              'No groups selected',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Add Group Dropdown
          if (groupsNotifier.groups.isNotEmpty)
            DropdownButton<String>(
              hint: const Text(
                'Add Group',
                style: TextStyle(fontSize: 11),
              ),
              isExpanded: true,
              items: groupsNotifier.groups
                  .where((group) => !analysisBlockState.groupIds.contains(group.id))
                  .map((group) => DropdownMenuItem(
                        value: group.id,
                        child: Text(
                          group.groupName,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ))
                  .toList(),
              onChanged: (String? groupId) {
                if (groupId != null) {
                  ref.read(analysisBlockNotifierProvider(blockId)).addGroup(groupId);
                }
              },
            )
          else
            Text(
              'No groups available',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}