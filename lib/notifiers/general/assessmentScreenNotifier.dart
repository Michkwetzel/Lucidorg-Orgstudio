import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:platform_v2/dataClasses/assessment.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/services/uiServices/snackBarService.dart';

class AssessmentScreenState {
  final List<Assessment> assessments;
  final bool isLoading;
  final String loadingMessage;
  final String? error;

  AssessmentScreenState({this.assessments = const [], this.isLoading = false, this.error, this.loadingMessage = ""});

  AssessmentScreenState copyWith({List<Assessment>? assessments, bool? isLoading, String? error, String? loadingMessage}) {
    return AssessmentScreenState(
      assessments: assessments ?? this.assessments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }
}

class AssessmentScreenNotifier extends StateNotifier<AssessmentScreenState> {
  Logger logger = Logger("AssessmentNotifier");
  final String orgId;
  
  AssessmentScreenNotifier({required this.orgId}) : super(AssessmentScreenState()) {
    getAssessments();
  }

  void getAssessments() async {
    try {
      state = state.copyWith(isLoading: true, loadingMessage: "Getting assessments...");
      // logger.info("Getting assessments from firestore for org: $orgId");
      
      final assessmentCollection = await FirestoreService.instance
          .collection('orgs')
          .doc(orgId)
          .collection('assessments')
          .get();
      
      List<Assessment> assessments = [];
      List<String> assessmentNames = []; // For logging
      
      for (var assessmentDoc in assessmentCollection.docs) {
        assessments.add(Assessment(assessmentName: assessmentDoc["assessmentName"], id: assessmentDoc.id));
        assessmentNames.add(assessmentDoc["assessmentName"]);
      }

      state = state.copyWith(assessments: assessments, isLoading: false);
      // logger.info("assessments: ${assessmentNames.join(", ")}");
    } catch (e) {
      state = state.copyWith(error: "Error getting assessments", isLoading: false);
      logger.severe("Error getting assessments: $e");
    }
  }

  void createAssessment(String assessmentName) async {
    try {
      state = state.copyWith(isLoading: true, loadingMessage: "Creating assessment...");

      await FirestoreService.instance
          .collection('orgs')
          .doc(orgId)
          .collection('assessments')
          .add({
        'assessmentName': assessmentName,
        'dateCreated': DateTime.now().millisecondsSinceEpoch,
      });
      
      SnackBarService.showMessage("Assessment created successfully", Colors.green);
      getAssessments();
    } catch (e) {
      state = state.copyWith(error: "Error creating assessment", isLoading: false);
      SnackBarService.showMessage("Unsuccessful", Colors.red);
      logger.severe("Error creating assessment: $e");
    }
  }
}