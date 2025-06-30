class BlockData {
  final String name;
  final String role;
  final String department;
  final String email;
  final List<String> emails;
  final bool isMultipleEmails;

  BlockData({
    required this.name,
    required this.role,
    required this.department,
    required this.email,
    required this.isMultipleEmails,
    required this.emails,
  });

  @override
  String toString() {
    return 'ContactData(name: $name, role: $role, department: $department, email: $email, isMultipleEmails: $isMultipleEmails, emails: $emails)';
  }

  factory BlockData.initial() {
    return BlockData(
      name: '',
      role: '',
      department: '',
      email: '',
      emails: [],
      isMultipleEmails: false,
    );
  }
}
