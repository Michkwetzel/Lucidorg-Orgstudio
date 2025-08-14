import 'package:platform_v2/config/enums.dart';

class AnalysisBlockData {
  final String blockName;
  final AnalysisBlockType analysisBlockType;
  final List<String> groupIds;

  const AnalysisBlockData({
    required this.blockName,
    required this.analysisBlockType,
    required this.groupIds,
  });

  factory AnalysisBlockData.empty() {
    return AnalysisBlockData(
      blockName: '',
      analysisBlockType: AnalysisBlockType.none,
      groupIds: [],
    );
  }

  // Factory constructor to create from Firestore data
  factory AnalysisBlockData.fromMap(Map<String, dynamic> data) {
    return AnalysisBlockData(
      blockName: data['blockName'] ?? '',
      analysisBlockType: _parseAnalysisBlockType(data['analysisBlockType'] as String?),
      groupIds: (data['groupIds'] as List?)?.cast<String>() ?? [],
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'blockName': blockName,
      'analysisBlockType': analysisBlockType.name,
      'groupIds': groupIds,
    };
  }

  // Helper method to parse string to enum
  static AnalysisBlockType _parseAnalysisBlockType(String? value) {
    if (value == null) return AnalysisBlockType.none;

    switch (value) {
      case 'none':
        return AnalysisBlockType.none;
      case 'question':
        return AnalysisBlockType.question;
      case 'indicator':
        return AnalysisBlockType.indicator;
      case 'internalStats':
        return AnalysisBlockType.internalStats;
      default:
        return AnalysisBlockType.none;
    }
  }

  // Copy with method for immutable updates
  AnalysisBlockData copyWith({
    String? blockName,
    AnalysisBlockType? analysisBlockType,
    List<String>? groupIds,
  }) {
    return AnalysisBlockData(
      blockName: blockName ?? this.blockName,
      analysisBlockType: analysisBlockType ?? this.analysisBlockType,
      groupIds: groupIds ?? this.groupIds,
    );
  }

  // Equality and hashCode for proper comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AnalysisBlockData) return false;

    return blockName == other.blockName && analysisBlockType == other.analysisBlockType && _listEquals(groupIds, other.groupIds);
  }

  @override
  int get hashCode => Object.hash(
    blockName,
    analysisBlockType,
    Object.hashAll(groupIds),
  );

  @override
  String toString() {
    return 'AnalysisBlockData(blockName: $blockName, analysisBlockType: $analysisBlockType, groupIds: $groupIds)';
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
