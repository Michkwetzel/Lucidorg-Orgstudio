import 'package:platform_v2/config/enums.dart';

class DisplayContext {
  final String? orgName;
  final String? assessmentName;
  final AppView appView;

  const DisplayContext({
    this.orgName,
    this.assessmentName,
    this.appView = AppView.none,
  });

  DisplayContext copyWith({
    String? orgName,
    String? assessmentName,
    AppView? appView,
    // Use this pattern to allow explicitly setting fields to null
    bool clearOrgName = false,
    bool clearAssessmentName = false,
  }) {
    return DisplayContext(
      orgName: clearOrgName ? null : (orgName ?? this.orgName),
      assessmentName: clearAssessmentName ? null : (assessmentName ?? this.assessmentName),
      appView: appView ?? this.appView,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisplayContext && 
           other.orgName == orgName && 
           other.assessmentName == assessmentName &&
           other.appView == appView;
  }

  @override
  int get hashCode {
    return Object.hash(
      orgName,
      assessmentName,
      appView,
    );
  }

  @override
  String toString() {
    return 'DisplayContext(orgName: $orgName, assessmentName: $assessmentName, appView: $appView)';
  }
}