import 'package:platform_v2/config/enums.dart';

class AnalysisBlockData {
  final String blockName;
  final AnalysisBlockType analysisBlockType;
  final AnalysisSubType analysisSubType;
  final List<String> groupIds;

  const AnalysisBlockData({
    required this.blockName,
    required this.analysisBlockType,
    required this.analysisSubType,
    required this.groupIds,
  });

  factory AnalysisBlockData.empty() {
    return AnalysisBlockData(
      blockName: '',
      analysisBlockType: AnalysisBlockType.none,
      analysisSubType: AnalysisSubType.none,
      groupIds: [],
    );
  }

  // Factory constructor to create from Firestore data
  factory AnalysisBlockData.fromMap(Map<String, dynamic> data) {
    final analysisBlockType = _parseAnalysisBlockType(data['analysisBlockType'] as String?);
    final analysisSubType = _parseAnalysisSubType(data['analysisSubType'] as String?);
    
    // Migration: if subType is none but blockType is set, provide reasonable default
    AnalysisSubType finalSubType = analysisSubType;
    if (analysisSubType == AnalysisSubType.none && analysisBlockType != AnalysisBlockType.none) {
      final originalType = data['analysisBlockType'] as String?;
      if (originalType == 'indicator') {
        finalSubType = AnalysisSubType.indicators;
      } else {
        finalSubType = AnalysisSubType.questions; // Default for 'question' and 'internalStats'
      }
    }
    
    return AnalysisBlockData(
      blockName: data['blockName'] ?? '',
      analysisBlockType: analysisBlockType,
      analysisSubType: finalSubType,
      groupIds: (data['groupIds'] as List?)?.cast<String>() ?? [],
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'blockName': blockName,
      'analysisBlockType': analysisBlockType.name,
      'analysisSubType': analysisSubType.name,
      'groupIds': groupIds,
    };
  }

  // Helper method to parse string to enum
  static AnalysisBlockType _parseAnalysisBlockType(String? value) {
    if (value == null) return AnalysisBlockType.none;

    switch (value) {
      case 'none':
        return AnalysisBlockType.none;
      case 'groupAnalysis':
        return AnalysisBlockType.groupAnalysis;
      case 'groupComparison':
        return AnalysisBlockType.groupComparison;
      // Migration support for old enum values
      case 'question':
      case 'indicator':
      case 'internalStats':
        return AnalysisBlockType.groupAnalysis; // Default old types to groupAnalysis
      default:
        return AnalysisBlockType.none;
    }
  }

  // Helper method to parse string to AnalysisSubType enum
  static AnalysisSubType _parseAnalysisSubType(String? value) {
    if (value == null) return AnalysisSubType.none;

    switch (value) {
      case 'none':
        return AnalysisSubType.none;
      case 'indicators':
        return AnalysisSubType.indicators;
      case 'questions':
        return AnalysisSubType.questions;
      default:
        return AnalysisSubType.none;
    }
  }

  // Copy with method for immutable updates
  AnalysisBlockData copyWith({
    String? blockName,
    AnalysisBlockType? analysisBlockType,
    AnalysisSubType? analysisSubType,
    List<String>? groupIds,
  }) {
    return AnalysisBlockData(
      blockName: blockName ?? this.blockName,
      analysisBlockType: analysisBlockType ?? this.analysisBlockType,
      analysisSubType: analysisSubType ?? this.analysisSubType,
      groupIds: groupIds ?? this.groupIds,
    );
  }

  // Equality and hashCode for proper comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnalysisBlockData) return false;

    return blockName == other.blockName && 
           analysisBlockType == other.analysisBlockType && 
           analysisSubType == other.analysisSubType &&
           _listEquals(groupIds, other.groupIds);
  }

  @override
  int get hashCode => Object.hash(
    blockName,
    analysisBlockType,
    analysisSubType,
    Object.hashAll(groupIds),
  );

  @override
  String toString() {
    return 'AnalysisBlockData(blockName: $blockName, analysisBlockType: $analysisBlockType, analysisSubType: $analysisSubType, groupIds: $groupIds)';
  }

  // Validation methods
  bool get isGroupAnalysis => analysisBlockType == AnalysisBlockType.groupAnalysis;
  bool get isGroupComparison => analysisBlockType == AnalysisBlockType.groupComparison;
  
  bool get hasValidGroupSelection {
    if (isGroupAnalysis) {
      return groupIds.length == 1; // Group Analysis requires exactly 1 group
    } else if (isGroupComparison) {
      return groupIds.isNotEmpty; // Group Comparison requires at least 1 group
    }
    return true; // No validation for 'none' type
  }

  bool get hasValidConfiguration {
    return analysisBlockType != AnalysisBlockType.none &&
           analysisSubType != AnalysisSubType.none &&
           hasValidGroupSelection;
  }

  // Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
