import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/dataClasses/org.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/services/uiServices/snackBarService.dart';

class OrgsScreenState {
  final List<Org> orgs;
  final bool isLoading;
  final String loadingMessage;
  final String? error;

  OrgsScreenState({this.orgs = const [], this.isLoading = false, this.error, this.loadingMessage = ""});

  OrgsScreenState copyWith({List<Org>? orgs, bool? isLoading, String? error, String? loadingMessage}) {
    return OrgsScreenState(
      orgs: orgs ?? this.orgs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }
}

class OrgsScreenNotifier extends StateNotifier<OrgsScreenState> {
  Logger logger = Logger("orgNotifer");
  OrgsScreenNotifier() : super(OrgsScreenState()) {
    getOrgs();
  }

  @override
  void dispose() {
    print("disposing");
    super.dispose();
  }

  void getOrgs() async {
    try {
      state = state.copyWith(isLoading: true, loadingMessage: "Getting orgs...");
      logger.info("Getting orgs from firestore");
      final orgCollection = await FirestoreService.instance.collection('orgs').get();
      List<Org> orgs = [];
      List<String> orgNames = []; // For logging
      for (var orgDoc in orgCollection.docs) {
        orgs.add(Org(orgName: orgDoc["orgName"], id: orgDoc.id));
        orgNames.add(orgDoc["orgName"]);
      }

      state = state.copyWith(orgs: orgs, isLoading: false);
      logger.info("orgs: ${orgNames.join(", ")}");
    } catch (e) {
      state = state.copyWith(error: "Error getting orgs", isLoading: false);
      logger.severe("Error getting orgs: $e");
    }
  }

  void createorg(String orgName) async {
    try {
      state = state.copyWith(isLoading: true, loadingMessage: "Creating org...");
      await FirestoreService.instance.collection('orgs').add({"orgName": orgName, "dateCreated": DateTime.now().toIso8601String()});
      SnackBarService.showMessage("org created successfully", Colors.green);
      getOrgs();
    } catch (e) {
      state = state.copyWith(error: "Error creating org", isLoading: false);
      SnackBarService.showMessage("Unsuccessfull", Colors.red);
      logger.severe("Error creating org: $e");
    }
  }
}
