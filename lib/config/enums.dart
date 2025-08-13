enum AssessmentMode { none, assessmentSend, assessmentBuild, assessmentDataView, assessmentAnalyze, assessmentGroupCreate }

enum AppView { none, logIn, orgSelect, orgBuild, assessmentBuild, assessmentSelect }

enum AnalysisBlockType { none, quesion, indicator, internalStats }

enum Permission { admin, error }

enum Options { select, department, all }

enum Pilar { alignment, people, process, leadership, none }

enum Benchmark {
  orgIndex,
  workforce,
  operations,
  alignP,
  processP,
  leadershipP,
  peopleP,
  purposeDriven,
  growthAlign,
  orgAlign,
  collabProcesses,
  collabKPIs,
  alignedTech,
  crossFuncComms,
  empoweredLeadership,
  engagedCommunity,
  meetingEfficacy,
  crossFuncAcc,
  engagement,
  productivity,
}

List<Benchmark> indicators() {
  return [
    Benchmark.orgAlign,
    Benchmark.growthAlign,
    Benchmark.collabKPIs,
    Benchmark.engagedCommunity,
    Benchmark.crossFuncComms,
    Benchmark.crossFuncAcc,
    Benchmark.alignedTech,
    Benchmark.collabProcesses,
    Benchmark.meetingEfficacy,
    Benchmark.purposeDriven,
    Benchmark.empoweredLeadership,
    Benchmark.engagement,
    Benchmark.productivity,
  ];
}

List<Benchmark> pilars() {
  return [
    Benchmark.alignP,
    Benchmark.processP,
    Benchmark.leadershipP,
    Benchmark.peopleP,
  ];
}

extension Description on Benchmark {
  String get heading {
    switch (this) {
      case Benchmark.purposeDriven:
        return "Purpose Driven Organization";
      case Benchmark.growthAlign:
        return "Growth Alignment";
      case Benchmark.orgAlign:
        return "Organizational Alignment";
      case Benchmark.collabProcesses:
        return "Collaborative Processes";
      case Benchmark.collabKPIs:
        return "Collaborative KPIs";
      case Benchmark.alignedTech:
        return "Aligned Technology";
      case Benchmark.crossFuncComms:
        return "Cross-Functional Communications";
      case Benchmark.empoweredLeadership:
        return "Empowered Leadership";
      case Benchmark.engagedCommunity:
        return "Engaged Community";
      case Benchmark.meetingEfficacy:
        return "Meeting Efficacy";
      case Benchmark.crossFuncAcc:
        return "Cross-Functional Accountability";
      case Benchmark.engagement:
        return "Engagement";
      case Benchmark.productivity:
        return "Productivity";
      case Benchmark.orgIndex:
        return "Index";
      case Benchmark.workforce:
        return "Workforce";
      case Benchmark.operations:
        return "Operations";
      default:
        return "Not Indicator";
    }
  }

  Pilar get pilar {
    switch (this) {
      case Benchmark.purposeDriven:
        return Pilar.leadership;
      case Benchmark.growthAlign:
        return Pilar.alignment;
      case Benchmark.orgAlign:
        return Pilar.alignment;
      case Benchmark.collabProcesses:
        return Pilar.process;
      case Benchmark.collabKPIs:
        return Pilar.alignment;
      case Benchmark.alignedTech:
        return Pilar.process;
      case Benchmark.crossFuncComms:
        return Pilar.people;
      case Benchmark.empoweredLeadership:
        return Pilar.leadership;
      case Benchmark.engagedCommunity:
        return Pilar.people;
      case Benchmark.meetingEfficacy:
        return Pilar.process;
      case Benchmark.crossFuncAcc:
        return Pilar.people;
      default:
        return Pilar.none;
    }
  }
}
