import 'package:platform_v2/config/enums.dart';

class DisplayOption {
  final String id;
  final String label;
  final bool isQuestion;
  final Benchmark? benchmark;
  final int? questionNumber;

  const DisplayOption._({
    required this.id,
    required this.label,
    required this.isQuestion,
    this.benchmark,
    this.questionNumber,
  });

  // Factory constructor for benchmarks
  factory DisplayOption.benchmark(Benchmark benchmark) {
    return DisplayOption._(
      id: 'benchmark_${benchmark.name}',
      label: _getBenchmarkLabel(benchmark),
      isQuestion: false,
      benchmark: benchmark,
    );
  }

  // Factory constructor for questions
  factory DisplayOption.question(int questionNumber) {
    return DisplayOption._(
      id: 'question_$questionNumber',
      label: 'Q$questionNumber',
      isQuestion: true,
      questionNumber: questionNumber,
    );
  }

  static String _getBenchmarkLabel(Benchmark benchmark) {
    switch (benchmark) {
      case Benchmark.orgAlign:
        return 'Org Alignment';
      case Benchmark.growthAlign:
        return 'Growth Alignment';
      case Benchmark.collabKPIs:
        return 'Collab KPIs';
      case Benchmark.engagedCommunity:
        return 'Engaged Community';
      case Benchmark.crossFuncComms:
        return 'Cross-Func Comms';
      case Benchmark.crossFuncAcc:
        return 'Cross-Func Acc';
      case Benchmark.alignedTech:
        return 'Aligned Tech';
      case Benchmark.collabProcesses:
        return 'Collab Processes';
      case Benchmark.meetingEfficacy:
        return 'Meeting Efficacy';
      case Benchmark.purposeDriven:
        return 'Purpose Driven';
      case Benchmark.empoweredLeadership:
        return 'Empowered Leadership';
      case Benchmark.engagement:
        return 'Engagement';
      case Benchmark.productivity:
        return 'Productivity';
      case Benchmark.orgIndex:
        return 'Index';
      case Benchmark.workforce:
        return 'Workforce';
      case Benchmark.operations:
        return 'Operations';
      case Benchmark.alignP:
        return 'Alignment P';
      case Benchmark.processP:
        return 'Process P';
      case Benchmark.leadershipP:
        return 'Leadership P';
      case Benchmark.peopleP:
        return 'People P';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisplayOption && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DisplayOption($label)';
}