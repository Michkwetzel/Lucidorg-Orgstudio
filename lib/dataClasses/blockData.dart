import 'package:flutter/material.dart';

class BlockData {
  final String name;
  final String role;
  final String department;
  final List<String> emails;
  final List<int> rawResults;
  final Offset position;
  final bool sent;
  final bool submitted;
  //TODO: At the moment these are not nullable. might be usefull to do this later depending on how calculations are made.

  BlockData({
    required this.name,
    required this.role,
    required this.department,
    required this.emails,
    this.rawResults = const [],
    this.position = const Offset(0, 0),
    this.sent = false,
    this.submitted = false,
  });

  // Convenience getters
  String get primaryEmail => emails.isNotEmpty ? emails.first : '';
  bool get hasMultipleEmails => emails.length > 1;
  bool get hasEmails => emails.isNotEmpty;

  // Add this method to your BlockData class
  BlockData copyWith({
    String? name,
    String? role,
    String? department,
    List<String>? emails,
    List<int>? rawResults,
    Offset? position,
    bool? sent,
    bool? submitted,
  }) {
    return BlockData(
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
      emails: emails ?? this.emails,
      rawResults: rawResults ?? this.rawResults,
      position: position ?? this.position,
      sent: sent ?? this.sent,
      submitted: submitted ?? this.submitted,
    );
  }

  @override
  String toString() {
    return 'BlockData(name: $name\n, role: $role\n, department: $department\n, emails: $emails)';
  }

  // Override equality operator to compare values instead of references
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BlockData) return false;

    return name == other.name && 
           role == other.role && 
           department == other.department && 
           _listEquals(emails, other.emails) &&
           _listEquals(rawResults, other.rawResults) &&
           position == other.position &&
           sent == other.sent &&
           submitted == other.submitted;
  }

  // Override hashCode to be consistent with equality
  @override
  int get hashCode {
    return Object.hash(
      name,
      role,
      department,
      Object.hashAll(emails),
      Object.hashAll(rawResults),
      position,
      sent,
      submitted,
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
      position: const Offset(0, 0),
      sent: false,
      submitted: false,
    );
  }

  // Convenience constructors
  factory BlockData.withSingleEmail({
    required String name,
    required String role,
    required String department,
    required String email,
    Offset position = const Offset(0, 0),
    bool sent = false,
    bool submitted = false,
  }) {
    return BlockData(
      name: name,
      role: role,
      department: department,
      emails: [email],
      position: position,
      sent: sent,
      submitted: submitted,
    );
  }
}
