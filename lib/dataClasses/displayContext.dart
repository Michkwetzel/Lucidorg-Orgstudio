import 'package:platform_v2/config/enums.dart';

class DisplayContext {
  final String? orgName;
  final String? assessmentName;
  final AppView appView;
  final AssessmentMode? assessmentMode;

  const DisplayContext({
    this.orgName,
    this.assessmentName,
    this.appView = AppView.none,
    this.assessmentMode,
  });

  DisplayContext copyWith({
    String? orgName,
    String? assessmentName,
    AppView? appView,
    AssessmentMode? assessmentMode,
    bool clearOrgName = false,
    bool clearAssessmentName = false,
    bool clearAssessmentMode = false,
  }) {
    return DisplayContext(
      orgName: clearOrgName ? null : (orgName ?? this.orgName),
      assessmentName: clearAssessmentName ? null : (assessmentName ?? this.assessmentName),
      appView: appView ?? this.appView,
      assessmentMode: clearAssessmentMode ? null : (assessmentMode ?? this.assessmentMode),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisplayContext && other.orgName == orgName && other.assessmentName == assessmentName && other.appView == appView && other.assessmentMode == assessmentMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      orgName,
      assessmentName,
      appView,
      assessmentMode,
    );
  }

  @override
  String toString() {
    return 'DisplayContext(orgName: $orgName, assessmentName: $assessmentName, appView: $appView, assessmentMode: $assessmentMode)';
  }
}
