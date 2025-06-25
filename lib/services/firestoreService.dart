import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreService {
  static late final FirebaseFirestore _instance;

  static void initialize() {
    _instance = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'platform-v2',
    );
  }

  static FirebaseFirestore get instance => _instance;

  static Future<void> addBlock(String orgId, Map<String, dynamic> blockData) async {
    await _instance.collection('orgs').doc(orgId).collection('blocks').doc(blockData['blockId']).set({
      ...blockData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteBlock(String orgId, String blockId) async {
    await _instance.collection('orgs').doc(orgId).collection('blocks').doc(blockId).delete();
  }

  static Future<void> updateBlock(String orgId, String blockId, Map<String, dynamic> updates) async {
    await _instance.collection('orgs').doc(orgId).collection('blocks').doc(blockId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getBlocksStream(String orgId) {
    return _instance.collection('orgs').doc(orgId).collection('blocks').snapshots();
  }

  static Future<QuerySnapshot> getBlocks(String orgId) async {
    return await _instance.collection('orgs').doc(orgId).collection('blocks').get();
  }
}
