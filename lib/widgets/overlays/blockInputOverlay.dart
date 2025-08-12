import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/services/firestoreService.dart';
import 'package:platform_v2/widgets/components/buildingBlocks/misc/uploadCSVWidget.dart';

class BlockInputOverlay extends ConsumerStatefulWidget {
  final Function(BlockData)? onSave;
  final VoidCallback? onClose;
  final BlockData? initialData;
  final String blockId;

  const BlockInputOverlay({
    super.key,
    this.onSave,
    this.onClose,
    this.initialData,
    required this.blockId,
  });

  @override
  ConsumerState<BlockInputOverlay> createState() => _BlockInputOverlayState();
}

class _BlockInputOverlayState extends ConsumerState<BlockInputOverlay> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController assessmentResultsController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isMultipleEmails = false;
  List<String> csvEmails = [];
  bool csvError = false;
  bool assessmentResultsError = false;
  String assessmentResultsErrorMessage = '';
  bool isLoadingAssessmentResults = false;
  bool isSavingAssessmentResults = false;

  @override
  void initState() {
    super.initState();
    _initializeWithData();
    _loadAssessmentResults();
  }

  void _initializeWithData() {
    final data = widget.initialData;
    if (data != null) {
      nameController.text = data.name;
      roleController.text = data.role;
      departmentController.text = data.department;

      // Handle emails
      if (data.emails.length > 1) {
        isMultipleEmails = true;
        emailController.text = data.emails.join(', ');
      } else if (data.emails.isNotEmpty) {
        isMultipleEmails = false;
        emailController.text = data.emails.first;
      }
    }
  }

  Future<void> _loadAssessmentResults() async {
    final appState = ref.read(appStateProvider);
    final orgId = appState.orgId;
    final assessmentId = appState.assessmentId;

    if (orgId == null || assessmentId == null) return;

    setState(() {
      isLoadingAssessmentResults = true;
      assessmentResultsError = false;
      assessmentResultsErrorMessage = '';
    });

    try {
      final rawResults = await _loadExistingRawResults(orgId, assessmentId, widget.blockId);
      if (rawResults != null && rawResults.isNotEmpty) {
        assessmentResultsController.text = rawResults.join('');
      }
    } catch (e) {
      setState(() {
        assessmentResultsError = true;
        assessmentResultsErrorMessage = 'Failed to load existing assessment results';
      });
    } finally {
      setState(() {
        isLoadingAssessmentResults = false;
      });
    }
  }

  void _clearAllData() {
    setState(() {
      nameController.clear();
      roleController.clear();
      departmentController.clear();
      assessmentResultsController.clear();
      emailController.clear();
      isMultipleEmails = false;
      csvEmails.clear();
      csvError = false;
    });
  }

  void _handleSave() async {
    List<String> emails = [];

    if (isMultipleEmails) {
      // Parse comma-separated emails from text field
      if (emailController.text.trim().isNotEmpty) {
        emails.addAll(emailController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
      }

      // Add CSV emails
      emails.addAll(csvEmails);
    }

    final data = BlockData(
      name: nameController.text.trim(),
      role: roleController.text.trim(),
      department: departmentController.text.trim(),
      emails: isMultipleEmails ? emails : [emailController.text.trim()],
    );

    // Save assessment results if provided
    if (assessmentResultsController.text.trim().isNotEmpty) {
      await _saveAssessmentResults();
    }

    widget.onSave?.call(data);
  }

  Future<void> _saveAssessmentResults() async {
    final appState = ref.read(appStateProvider);
    final orgId = appState.orgId;
    final assessmentId = appState.assessmentId;

    if (orgId == null || assessmentId == null) {
      setState(() {
        assessmentResultsError = true;
        assessmentResultsErrorMessage = 'Missing organization or assessment context';
      });
      return;
    }

    setState(() {
      isSavingAssessmentResults = true;
      assessmentResultsError = false;
      assessmentResultsErrorMessage = '';
    });

    try {
      final rawResults = _parseAssessmentResults(assessmentResultsController.text);
      if (rawResults.isEmpty) {
        throw Exception('Invalid assessment results format');
      }

      final docId = await _findAssessmentDataDocId(orgId, assessmentId, widget.blockId);
      if (docId == null) {
        throw Exception('No assessment data document found for this block');
      }

      await _updateAssessmentDataRawResults(orgId, assessmentId, docId, rawResults);
    } catch (e) {
      setState(() {
        assessmentResultsError = true;
        assessmentResultsErrorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        isSavingAssessmentResults = false;
      });
    }
  }

  void _onCSVDataExtracted(List<String> emails, bool error) {
    setState(() {
      csvEmails = emails;
      csvError = error;
    });
  }

  List<int> _parseAssessmentResults(String input) {
    if (input.trim().isEmpty) return [];

    // Remove any whitespace and validate only digits
    final cleanInput = input.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d+$').hasMatch(cleanInput)) return [];

    // Convert each character to an integer
    return cleanInput.split('').map((char) => int.parse(char)).toList();
  }

  bool _isValidAssessmentResults(String input) {
    final cleanInput = input.replaceAll(RegExp(r'\s'), '');
    return cleanInput.length == 37 && RegExp(r'^\d+$').hasMatch(cleanInput);
  }

  Future<String?> _findAssessmentDataDocId(String orgId, String assessmentId, String blockId) async {
    try {
      final querySnapshot = await FirestoreService.instance
          .collection('orgs')
          .doc(orgId)
          .collection('assessments')
          .doc(assessmentId)
          .collection('data')
          .where('blockId', isEqualTo: blockId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error finding assessment data doc: $e');
      return null;
    }
  }

  Future<void> _updateAssessmentDataRawResults(String orgId, String assessmentId, String docId, List<int> rawResults) async {
    try {
      await FirestoreService.instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('data').doc(docId).update({'rawResults': rawResults});
    } catch (e) {
      throw Exception('Failed to update assessment data: $e');
    }
  }

  Future<List<int>?> _loadExistingRawResults(String orgId, String assessmentId, String blockId) async {
    try {
      final docId = await _findAssessmentDataDocId(orgId, assessmentId, blockId);
      if (docId == null) return null;

      final docSnapshot = await FirestoreService.instance.collection('orgs').doc(orgId).collection('assessments').doc(assessmentId).collection('data').doc(docId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final rawResults = data?['rawResults'] as List<dynamic>?;
        return rawResults?.cast<int>();
      }
      return null;
    } catch (e) {
      print('Error loading existing raw results: $e');
      return null;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    roleController.dispose();
    departmentController.dispose();
    assessmentResultsController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 20,
          bottom: 80,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 320,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with clear and close buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Block Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _clearAllData,
                              icon: const Icon(Icons.clear_all),
                              iconSize: 20,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              tooltip: 'Clear all fields',
                            ),
                            IconButton(
                              onPressed: widget.onClose,
                              icon: const Icon(Icons.close),
                              iconSize: 20,
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Name field
                    _buildTextField('Name', nameController),
                    const SizedBox(height: 12),

                    // Role field
                    _buildTextField('Role', roleController),
                    const SizedBox(height: 12),

                    // Department field
                    _buildTextField('Department', departmentController),
                    const SizedBox(height: 12),

                    // Assessment Results field
                    _buildAssessmentResultsField(),
                    const SizedBox(height: 12),

                    // Email type selection
                    const Text(
                      'Email Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                isMultipleEmails = false;
                                csvEmails.clear();
                                csvError = false;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !isMultipleEmails ? Colors.blue : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(7),
                                    bottomLeft: Radius.circular(7),
                                  ),
                                ),
                                child: Text(
                                  'Single Email',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !isMultipleEmails ? Colors.white : Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isMultipleEmails = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isMultipleEmails ? Colors.blue : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(7),
                                    bottomRight: Radius.circular(7),
                                  ),
                                ),
                                child: Text(
                                  'Multiple Emails',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isMultipleEmails ? Colors.white : Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Email/Emails field
                    _buildTextField(
                      isMultipleEmails ? 'Emails' : 'Email',
                      emailController,
                      hintText: isMultipleEmails ? 'Enter comma-separated emails' : 'Enter Email',
                    ),

                    // CSV Upload Widget (only show when multiple emails is selected)
                    if (isMultipleEmails) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Or upload CSV file',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      UploadCSVWidget(
                        onDataExtracted: _onCSVDataExtracted,
                        displayErrorCSV: csvError,
                      ),
                      if (csvEmails.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${csvEmails.length} emails loaded from CSV',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onClose,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleSave,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentResultsField() {
    final isValid = _isValidAssessmentResults(assessmentResultsController.text);
    final currentLength = assessmentResultsController.text.replaceAll(RegExp(r'\s'), '').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Assessment Results',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            if (isLoadingAssessmentResults) ...[
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                ),
              ),
            ] else if (isSavingAssessmentResults) ...[
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Saving...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade600,
                ),
              ),
            ] else ...[
              Text(
                '($currentLength/37)',
                style: TextStyle(
                  fontSize: 12,
                  color: isValid ? Colors.green.shade600 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: assessmentResultsController,
          enabled: !isLoadingAssessmentResults && !isSavingAssessmentResults,
          maxLength: 37,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) => setState(() {
            // Clear error when user starts typing
            if (assessmentResultsError) {
              assessmentResultsError = false;
              assessmentResultsErrorMessage = '';
            }
          }),
          decoration: InputDecoration(
            hintText: 'Enter 37 consecutive numbers (e.g., 1234567890...)',
            counterText: '', // Hide default counter since we have custom one
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: assessmentResultsError
                    ? Colors.red.shade300
                    : isValid
                    ? Colors.green.shade300
                    : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: assessmentResultsError
                    ? Colors.red.shade300
                    : isValid
                    ? Colors.green.shade300
                    : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: assessmentResultsError
                    ? Colors.red
                    : isValid
                    ? Colors.green
                    : Colors.blue,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
        if (assessmentResultsError) ...[
          const SizedBox(height: 4),
          Text(
            assessmentResultsErrorMessage,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
            ),
          ),
        ] else if (currentLength > 0 && !isValid && !isLoadingAssessmentResults) ...[
          const SizedBox(height: 4),
          Text(
            currentLength < 37 ? 'Please enter exactly 37 numbers' : 'Too many numbers entered',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: isMultipleEmails && label == 'Emails' ? 3 : 1,
          decoration: InputDecoration(
            hintText: hintText ?? 'Enter $label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }
}
