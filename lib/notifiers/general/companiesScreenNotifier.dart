import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/dataClasses/company.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/services/uiServices/snackBarService.dart';

class CompaniesScreenState {
  final List<Company> companies;
  final bool isLoading;
  final String loadingMessage;
  final String? error;

  CompaniesScreenState({this.companies = const [], this.isLoading = false, this.error, this.loadingMessage = ""});

  CompaniesScreenState copyWith({List<Company>? companies, bool? isLoading, String? error, String? loadingMessage}) {
    return CompaniesScreenState(
      companies: companies ?? this.companies,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }
}

class CompaniesScreenNotifier extends StateNotifier<CompaniesScreenState> {
  Logger logger = Logger("companyNotifer");
  CompaniesScreenNotifier() : super(CompaniesScreenState()) {
    getCompanies();
  }

  @override
  void dispose() {
    print("disposing");
    super.dispose();
  }

  void getCompanies() async {
    try {
      state = state.copyWith(isLoading: true, loadingMessage: "Getting companies...");
      logger.info("Getting companies from firestore");
      final companyCollection = await FirestoreService.instance.collection('companies').get();
      List<Company> companies = [];
      List<String> companyNames = []; // For logging
      for (var companyDoc in companyCollection.docs) {
        companies.add(Company(companyName: companyDoc["companyName"], id: companyDoc.id));
        companyNames.add(companyDoc["companyName"]);
      }

      state = state.copyWith(companies: companies, isLoading: false);
      logger.info("companies: ${companyNames.join(", ")}");
    } catch (e) {
      state = state.copyWith(error: "Error getting companies", isLoading: false);
      logger.severe("Error getting companies: $e");
    }
  }

  void createCompany(String companyName) async {
    try {
      state = state.copyWith(isLoading: true, loadingMessage: "Creating company...");
      await FirestoreService.instance.collection('companies').add({"companyName": companyName, "dateCreated": DateTime.now().toIso8601String()});
      SnackBarService.showMessage("Company created successfully", Colors.green);
      getCompanies();
    } catch (e) {
      state = state.copyWith(error: "Error creating company", isLoading: false);
      SnackBarService.showMessage("Unsuccessfull", Colors.red);
      logger.severe("Error creating company: $e");
    }
  }
}
