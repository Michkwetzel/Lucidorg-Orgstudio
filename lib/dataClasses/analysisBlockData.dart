import 'package:platform_v2/config/enums.dart';

class AnalysisBlockData {
  final String blockName;
  final AnalysisBlockType analysisBlockType;
  final AnalysisSubType analysisSubType;
  final List<String> groupIds;
  final Set<int> selectedQuestions;
  final Set<Benchmark> selectedIndicators;
  final ChartType chartType;

  const AnalysisBlockData({
    required this.blockName,
    required this.analysisBlockType,
    required this.analysisSubType,
    required this.groupIds,
    required this.selectedQuestions,
    required this.selectedIndicators,
    required this.chartType,
  });

  factory AnalysisBlockData.empty() {
    return AnalysisBlockData(
      blockName: '',
      analysisBlockType: AnalysisBlockType.none,
      analysisSubType: AnalysisSubType.none,
      groupIds: [],
      selectedQuestions: Set<int>.from(List.generate(37, (i) => i + 1)),
      selectedIndicators: Set<Benchmark>.from(indicators()),
      chartType: ChartType.bar,
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
      selectedQuestions: _parseSelectedQuestions(data['selectedQuestions']),
      selectedIndicators: _parseSelectedIndicators(data['selectedIndicators']),
      chartType: _parseChartType(data['chartType'] as String?),
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'blockName': blockName,
      'analysisBlockType': analysisBlockType.name,
      'analysisSubType': analysisSubType.name,
      'groupIds': groupIds,
      'selectedQuestions': selectedQuestions.toList(),
      'selectedIndicators': selectedIndicators.map((e) => e.name).toList(),
      'chartType': chartType.name,
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

  // Helper method to parse string to ChartType enum
  static ChartType _parseChartType(String? value) {
    if (value == null) return ChartType.bar;

    switch (value) {
      case 'bar':
        return ChartType.bar;
      case 'radar':
        return ChartType.radar;
      case 'both':
        return ChartType.both;
      default:
        return ChartType.bar;
    }
  }

  // Helper method to parse selected questions
  static Set<int> _parseSelectedQuestions(dynamic value) {
    if (value == null) {
      return Set<int>.from(List.generate(37, (i) => i + 1)); // Default to all questions
    }
    
    if (value is List) {
      return Set<int>.from(value.where((e) => e is int).cast<int>());
    }
    
    return Set<int>.from(List.generate(37, (i) => i + 1)); // Fallback to all questions
  }

  // Helper method to parse selected indicators
  static Set<Benchmark> _parseSelectedIndicators(dynamic value) {
    if (value == null) {
      return Set<Benchmark>.from(indicators()); // Default to all indicators
    }
    
    if (value is List) {
      final result = <Benchmark>{};
      for (final item in value) {
        if (item is String) {
          for (final benchmark in Benchmark.values) {
            if (benchmark.name == item) {
              result.add(benchmark);
              break;
            }
          }
        }
      }
      return result.isEmpty ? Set<Benchmark>.from(indicators()) : result;
    }
    
    return Set<Benchmark>.from(indicators()); // Fallback to all indicators
  }

  // Copy with method for immutable updates
  AnalysisBlockData copyWith({
    String? blockName,
    AnalysisBlockType? analysisBlockType,
    AnalysisSubType? analysisSubType,
    List<String>? groupIds,
    Set<int>? selectedQuestions,
    Set<Benchmark>? selectedIndicators,
    ChartType? chartType,
  }) {
    return AnalysisBlockData(
      blockName: blockName ?? this.blockName,
      analysisBlockType: analysisBlockType ?? this.analysisBlockType,
      analysisSubType: analysisSubType ?? this.analysisSubType,
      groupIds: groupIds ?? this.groupIds,
      selectedQuestions: selectedQuestions ?? this.selectedQuestions,
      selectedIndicators: selectedIndicators ?? this.selectedIndicators,
      chartType: chartType ?? this.chartType,
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
           _listEquals(groupIds, other.groupIds) &&
           _setEquals(selectedQuestions, other.selectedQuestions) &&
           _setEquals(selectedIndicators, other.selectedIndicators) &&
           chartType == other.chartType;
  }

  @override
  int get hashCode => Object.hash(
    blockName,
    analysisBlockType,
    analysisSubType,
    Object.hashAll(groupIds),
    Object.hashAll(selectedQuestions),
    Object.hashAll(selectedIndicators),
    chartType,
  );

  @override
  String toString() {
    return 'AnalysisBlockData(blockName: $blockName, analysisBlockType: $analysisBlockType, analysisSubType: $analysisSubType, groupIds: $groupIds, selectedQuestions: ${selectedQuestions.length}, selectedIndicators: ${selectedIndicators.length}, chartType: $chartType)';
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

  // Helper method to compare sets
  bool _setEquals<T>(Set<T> a, Set<T> b) {
    return a.length == b.length && a.containsAll(b);
  }
}
