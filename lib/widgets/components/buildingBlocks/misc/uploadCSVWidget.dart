import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:logging/logging.dart';

class UploadCSVWidget extends StatefulWidget {
  final Function(List<String>, bool error) onDataExtracted;
  final bool displayErrorCSV;

  const UploadCSVWidget({super.key, required this.onDataExtracted, required this.displayErrorCSV});

  @override
  State<UploadCSVWidget> createState() => _UploadCSVWidgetState();
}

class _UploadCSVWidgetState extends State<UploadCSVWidget> {
  Logger logger = Logger('UploadCSVWidget');
  List<String> validEmails = [];
  String displayText = "Click or drag CSV file here";
  late DropzoneViewController controller;
  String csvContent = '';
  bool isLoading = false;
  bool isHovering = false;
  bool success = false;
  bool uploadError = false;

  @override
  void dispose() {
    super.dispose();
  }

  // Email validation regex
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void didUpdateWidget(UploadCSVWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.displayErrorCSV != oldWidget.displayErrorCSV) {
      setState(() {
        if (widget.displayErrorCSV) {
          success = false;
        }
      });
    }
  }

  Future<void> handleDrop(DropzoneFileInterface file) async {
    setState(() {
      isHovering = false;
      isLoading = true;
      uploadError = false;
      success = false;
    });

    try {
      // Check if it's a CSV file
      final mime = await controller.getFileMIME(file);
      if (!mime.contains('csv') && !mime.contains('text/plain')) {
        throw 'Please upload a CSV file';
      }

      // Get the file data as bytes
      final data = await controller.getFileData(file);

      // Convert bytes to string
      csvContent = String.fromCharCodes(data);

      // Parse CSV content and validate emails
      final rows = csvContent.split('\n');

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i].trim();
        if (row.isEmpty) continue;

        final columns = row.split(',');
        if (columns.length != 1) {
          displayText = 'Row ${i + 1} contains multiple columns';
          throw 'CSV validation failed:\n$displayText';
        }

        final email = columns[0].trim();
        if (!emailRegex.hasMatch(email)) {
          throw CSVValidationException('CSV validation failed:\nInvalid email format in row ${i + 1}: ${email.substring(0, 10)}');
        }

        validEmails.add(email);
      }

      if (validEmails.isEmpty) {
        throw NoEmailsFoundException('No valid emails found in the CSV file');
      }

      // Send valid emails back to parent
      widget.onDataExtracted(validEmails, false);
      setState(() {
        displayText = "Successfully loaded ${validEmails.length} emails";
        uploadError = false;
        success = true;
      });
    } catch (e) {
      print(e);
      widget.onDataExtracted([], true);
      setState(() {
        if (e is CSVValidationException) {
          displayText = e.message; // Use message property instead of toString()
        } else if (e is NoEmailsFoundException) {
          displayText = e.message; // Use message property instead of toString()
        } else {
          print('Unexpected error: $e');
          displayText = 'Invalid CSV file';
        }
        success = false;
        uploadError = true;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> handleClick() async {
    final files = await controller.pickFiles(
      multiple: false,
      mime: ['text/csv', 'text/plain'],
    );
    if (files.isNotEmpty) {
      await handleDrop(files.first);
    }
  }

  Color handleColor() {
    if (uploadError || widget.displayErrorCSV) {
      return Colors.red;
    } else if (success) {
      return Colors.blue;
    } else if (isHovering) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uploadError || success) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildCSVWidget(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    success = false;
                    uploadError = false;
                    displayText = "Click or drag CSV file here";
                    csvContent = '';
                    validEmails = [];
                  });
                  widget.onDataExtracted([], false);
                },
                icon: const Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return _buildCSVWidget();
    }
  }

  SizedBox _buildCSVWidget() {
    return SizedBox(
      height: 95,
      child: Stack(
        children: [
          Positioned.fill(
            child: DropzoneView(
              operation: DragOperation.copy,
              cursor: CursorType.pointer,
              onCreated: (ctrl) => controller = ctrl,
              onDropFile: handleDrop,
              onHover: () => setState(() => isHovering = true),
              onLeave: () => setState(() => isHovering = false),
              onError: (err) => debugPrint('Dropzone error: $err'),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: handleClick,
              child: DottedBorder(
                options: RectDottedBorderOptions(
                  dashPattern: [10, 5],
                  strokeWidth: 2,
                  padding: EdgeInsets.all(16),
                ),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isLoading ? Icons.hourglass_empty : Icons.upload_file,
                        size: 32,
                        color: handleColor(),
                      ),
                      if (isLoading)
                        const CircularProgressIndicator()
                      else if (csvContent.isEmpty)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            displayText,
                            style: TextStyle(
                              color: handleColor(),
                            ),
                          ),
                        )
                      else
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            displayText,
                            style: TextStyle(
                              color: handleColor(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CSVValidationException implements Exception {
  final String message;
  CSVValidationException(this.message);

  @override
  String toString() => message;
}

class NoEmailsFoundException implements Exception {
  final String message;
  NoEmailsFoundException(this.message);

  @override
  String toString() => message;
}
