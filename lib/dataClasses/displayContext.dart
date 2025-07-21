import 'package:platform_v2/config/enums.dart';

class DisplayContext {
  final String? orgName;
  final String? assessmentName;
  final AppView appView;
  final AppMode appMode;

  const DisplayContext({
    this.orgName,
    this.assessmentName,
    this.appView = AppView.none,
    this.appMode = AppMode.none,
  });

  DisplayContext copyWith({
    String? orgName,
    String? assessmentName,
    AppView? appView,
    AppMode? appMode,
    bool clearOrgName = false,
    bool clearAssessmentName = false,
  }) {
    return DisplayContext(
      orgName: clearOrgName ? null : (orgName ?? this.orgName),
      assessmentName: clearAssessmentName ? null : (assessmentName ?? this.assessmentName),
      appView: appView ?? this.appView,
      appMode: appMode ?? this.appMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisplayContext && other.orgName == orgName && other.assessmentName == assessmentName && other.appView == appView && other.appMode == appMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      orgName,
      assessmentName,
      appView,
      appMode,
    );
  }

  @override
  String toString() {
    return 'DisplayContext(orgName: $orgName, assessmentName: $assessmentName, appView: $appView), appMode: $appMode)';
  }
}
