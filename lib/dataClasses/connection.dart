import 'package:cloud_firestore/cloud_firestore.dart';

class Connection {
  final String id;
  final String parentId;
  final String childId;

  Connection(this.id, {required this.parentId, required this.childId});

  factory Connection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle both old (parentID/childID) and new (parentId/childId) field names
    final parentId = (data['parentId'] ?? data['parentID']) as String?;
    final childId = (data['childId'] ?? data['childID']) as String?;

    if (parentId == null || childId == null) {
      throw Exception('Connection document ${doc.id} is missing required fields. parentId: $parentId, childId: $childId');
    }

    return Connection(
      doc.id,
      parentId: parentId,
      childId: childId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'parentId': parentId,
      'childId': childId,
    };
  }
}
