import 'package:platform_v2/config/enums.dart';

class UserProfile {
  final String userUID;
  final String email;
  final String? orgUID;
  final Permission permission;
  final String? latestSurveyDocName;

  const UserProfile({
    required this.userUID,
    required this.email,
    required this.orgUID,
    required this.permission,
    this.latestSurveyDocName,
  });

  UserProfile copyWith({
    String? userUID,
    String? email,
    String? orgUID,
    Permission? permission,
    String? latestSurveyDocName,
  }) {
    return UserProfile(
      userUID: userUID ?? this.userUID,
      email: email ?? this.email,
      orgUID: orgUID ?? this.orgUID,
      permission: permission ?? this.permission,
      latestSurveyDocName: latestSurveyDocName ?? this.latestSurveyDocName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.userUID == userUID && other.email == email && other.orgUID == orgUID && other.permission == permission && other.latestSurveyDocName == latestSurveyDocName;
  }

  @override
  int get hashCode {
    return Object.hash(
      userUID,
      email,
      orgUID,
      permission,
      latestSurveyDocName,
    );
  }

  @override
  String toString() {
    return 'UserProfile(userUID: $userUID, email: $email, orgUID: $orgUID, permission: $permission, latestSurveyDocName: $latestSurveyDocName)';
  }
}
