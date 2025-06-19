import 'package:platform_v2/config/enums.dart';

class UserProfile {
  final String userUID;
  final String email;
  final String? companyUID;
  final Permission permission;
  final String? latestSurveyDocName;

  const UserProfile({
    required this.userUID,
    required this.email,
    required this.companyUID,
    required this.permission,
    this.latestSurveyDocName,
  });

  UserProfile copyWith({
    String? userUID,
    String? email,
    String? companyUID,
    Permission? permission,
    String? latestSurveyDocName,
  }) {
    return UserProfile(
      userUID: userUID ?? this.userUID,
      email: email ?? this.email,
      companyUID: companyUID ?? this.companyUID,
      permission: permission ?? this.permission,
      latestSurveyDocName: latestSurveyDocName ?? this.latestSurveyDocName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.userUID == userUID &&
        other.email == email &&
        other.companyUID == companyUID &&
        other.permission == permission &&
        other.latestSurveyDocName == latestSurveyDocName;
  }

  @override
  int get hashCode {
    return Object.hash(
      userUID,
      email,
      companyUID,
      permission,
      latestSurveyDocName,
    );
  }

  @override
  String toString() {
    return 'UserProfile(userUID: $userUID, email: $email, companyUID: $companyUID, permission: $permission, latestSurveyDocName: $latestSurveyDocName)';
  }
}
