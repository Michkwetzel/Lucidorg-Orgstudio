class BlockData {
  final String name;
  final String role;
  final String department;
  final List<String> emails;
  //TODO: At the moment these are not nullable. might be usefull to do this later depending on how calculations are made.

  BlockData({
    required this.name,
    required this.role,
    required this.department,
    required this.emails,
  });

  // Convenience getters
  String get primaryEmail => emails.isNotEmpty ? emails.first : '';
  bool get hasMultipleEmails => emails.length > 1;
  bool get hasEmails => emails.isNotEmpty;

  @override
  String toString() {
    return 'BlockData(name: $name\n, role: $role\n, department: $department\n, emails: $emails)';
  }

  // Override equality operator to compare values instead of references
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BlockData) return false;

    return name == other.name && role == other.role && department == other.department && _listEquals(emails, other.emails);
  }

  // Override hashCode to be consistent with equality
  @override
  int get hashCode {
    return Object.hash(
      name,
      role,
      department,
      Object.hashAll(emails),
    );
  }

  // Helper method to compare lists for equality
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  factory BlockData.initial() {
    return BlockData(
      name: '',
      role: '',
      department: '',
      emails: [],
    );
  }

  // Convenience constructors
  factory BlockData.withSingleEmail({
    required String name,
    required String role,
    required String department,
    required String email,
  }) {
    return BlockData(
      name: name,
      role: role,
      department: department,
      emails: [email],
    );
  }
}
