import 'package:cloud_firestore/cloud_firestore.dart';

class Connection {
  final String id;
  final String parentId;
  final String childId;

  Connection(this.id, {required this.parentId, required this.childId});

  factory Connection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Connection(
      doc.id,
      parentId: data['parentId'] as String,
      childId: data['childId'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'parentId': parentId,
      'childId': childId,
    };
  }
}
