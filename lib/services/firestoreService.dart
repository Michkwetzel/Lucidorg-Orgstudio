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
}