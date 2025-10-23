import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
// import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/dataClasses/user_profile.dart';

class AuthState {
  // Here you have the FirebaseUser and also the Data Class: UserProfile
  final User? firebaseUser;
  final UserProfile? userProfile;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => firebaseUser != null;

  AuthState({this.firebaseUser, this.userProfile, this.isLoading = false, this.error});

  AuthState copyWith({User? firebaseUser, UserProfile? userProfile, bool? isLoading, String? error}) {
    return AuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      userProfile: userProfile ?? this.userProfile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final logger = Logger("AuthFireStoreService");
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(AuthState());

  void initState() {
    _auth.userChanges().listen((User? user) async {
      if (user != null) {
        state = state.copyWith(firebaseUser: user);
        // await getUserInfo();
        logger.info("User signed in with UID: ${user.uid}, Email: ${user.email}}");
      } else {
        logger.info("No user signed in");
      }
    });
  }

  // UserProfile? getUserProfile() {
  //   return state.userProfile;
  // }

  // Permission _parsePermission(String? permission) {
  //   switch (permission) {
  //     case 'admin':
  //       return Permission.admin;
  //     default:
  //       return Permission.error;
  //   }
  // }

  // Future<void> getUserInfo() async {
  //   try {
  //     final userDocRef = await _firestore.collection('users').doc(state.firebaseUser!.uid).get();
  //     final permission = _parsePermission(userDocRef.data()?['permission']);
  //     final orgUID = userDocRef.data()?['orgUID'];
  //     final email = userDocRef.data()?['userEmail'];
  //     final userUID = state.firebaseUser!.uid;
  //     state = state.copyWith(
  //       userProfile: UserProfile(permission: permission, orgUID: orgUID, email: email, userUID: userUID),
  //     );
  //   } on Exception catch (e) {
  //     logger.severe("Unable to get userInfo for user UID: ${state.firebaseUser?.uid}, email: ${state.firebaseUser?.email}, e: $e");
  //   }
  // }

  Future<void> deleteAccount() async {
    logger.info("Attempting to delete account that was just created");
    await _auth.currentUser!.delete();
    logger.info("Account deleted");
  }

  Future<void> createUserWithEmailAndPassword(String inputEmail, String inputPassword) async {
    logger.info("Create user Account started inputEmail: $inputEmail, password: $inputPassword");
    _auth.signOut();
    await _auth.createUserWithEmailAndPassword(email: inputEmail, password: inputPassword);
    logger.info("Success creating Google Auth Account");
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    logger.info("Singing in with Email and Password $email, $password");
    _auth.signOut();
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<dynamic> signinWithGoogle() async {
    logger.info("Singing in with Google");
    _auth.signOut();
    return await _auth.signInWithPopup(GoogleAuthProvider());
  }

  Future<void> signInAnonymously() async {
    logger.info("Signing in anonymously (guest mode)");
    _auth.signOut();
    await _auth.signInAnonymously();
    logger.info("Successfully signed in as guest");
  }

  void signOutUser() {
    _auth.signOut();
    state = state.copyWith(firebaseUser: null, userProfile: null);
  }
}
