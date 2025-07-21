class FirestoreContext {
  final String? orgId;
  final String? assessmentId;

  const FirestoreContext({this.orgId, this.assessmentId});

  FirestoreContext copyWith({
    String? orgId,
    String? assessmentId,
    bool clearOrgId = false,
    bool clearAssessmentId = false,
  }) {
    return FirestoreContext(
      orgId: clearOrgId ? null : (orgId ?? this.orgId),
      assessmentId: clearAssessmentId ? null : (assessmentId ?? this.assessmentId),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FirestoreContext && other.orgId == orgId && other.assessmentId == assessmentId;
  }

  @override
  int get hashCode => Object.hash(orgId, assessmentId);

  @override
  String toString() => 'FirestoreContext(orgId: $orgId, assessmentId: $assessmentId)';
}
