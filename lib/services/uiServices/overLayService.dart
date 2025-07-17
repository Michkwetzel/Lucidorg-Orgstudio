import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/dataClasses/blockData.dart';
import 'package:platform_v2/widgets/components/buildingBlocks/misc/uploadCSVWidget.dart';

class OverlayService {
  static OverlayEntry? _currentOverlay;

  static void openBlockInputBox(
    BuildContext context, {
    Function(BlockData)? onSave,
    VoidCallback? onClose,
    BlockData? initialData,
  }) {
    final overlay = Overlay.of(context);

    // Remove any existing overlay
    _currentOverlay?.remove();

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => BlockInputOverlay(
        initialData: initialData,
        onSave: (data) {
          overlayEntry.remove();
          _currentOverlay = null;
          onSave?.call(data);
        },
        onClose: () {
          overlayEntry.remove();
          _currentOverlay = null;
          onClose?.call();
        },
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);
  }

  static void openAssessmentCreationOverlay(
    BuildContext context, {
    Future<void> Function(String)? onCreate,
    VoidCallback? onClose,
  }) {
    final overlay = Overlay.of(context);

    // Remove any existing overlay
    _currentOverlay?.remove();

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AssessmentCreationOverlay(
        onCreate: (assessmentName) async {
          await onCreate?.call(assessmentName);
          overlayEntry.remove();
          _currentOverlay = null;
        },
        onClose: () {
          overlayEntry.remove();
          _currentOverlay = null;
          onClose?.call();
        },
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);
  }
}

class BlockInputOverlay extends StatefulWidget {
  final Function(BlockData)? onSave;
  final VoidCallback? onClose;
  final BlockData? initialData;

  const BlockInputOverlay({
    super.key,
    this.onSave,
    this.onClose,
    this.initialData,
  });

  @override
  State<BlockInputOverlay> createState() => _BlockInputOverlayState();
}

class _BlockInputOverlayState extends State<BlockInputOverlay> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isMultipleEmails = false;
  List<String> csvEmails = [];
  bool csvError = false;

  @override
  void initState() {
    super.initState();
    _initializeWithData();
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

  void _clearAllData() {
    setState(() {
      nameController.clear();
      roleController.clear();
      departmentController.clear();
      emailController.clear();
      isMultipleEmails = false;
      csvEmails.clear();
      csvError = false;
    });
  }

  void _handleSave() {
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
    widget.onSave?.call(data);
  }

  void _onCSVDataExtracted(List<String> emails, bool error) {
    setState(() {
      csvEmails = emails;
      csvError = error;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    roleController.dispose();
    departmentController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 0,
          bottom: 0,
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

class AssessmentCreationOverlay extends ConsumerStatefulWidget {
  final Future<void> Function(String)? onCreate;
  final VoidCallback? onClose;

  const AssessmentCreationOverlay({
    super.key,
    this.onCreate,
    this.onClose,
  });

  @override
  ConsumerState<AssessmentCreationOverlay> createState() => _AssessmentCreationOverlayState();
}

class _AssessmentCreationOverlayState extends ConsumerState<AssessmentCreationOverlay> {
  final TextEditingController assessmentNameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleCreate() async {
    final assessmentName = assessmentNameController.text.trim();
    if (assessmentName.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onCreate?.call(assessmentName);
      // If we get here, creation was successful
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error creating assessment: ${error.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    assessmentNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final orgName = appState.orgName ?? 'Unknown Organization';

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Assessment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : widget.onClose,
                      icon: const Icon(Icons.close),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Organization info
                Text(
                  'Organization: $orgName',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Assessment name field
                const Text(
                  'Assessment Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: assessmentNameController,
                  autofocus: true,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Enter assessment name',
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
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _isLoading ? null : (_) => _handleCreate(),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : widget.onClose,
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
                        onPressed: _isLoading ? null : _handleCreate,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Create'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
