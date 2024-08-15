import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fe/data/repository/digital_signature_repository.dart';
import 'package:flutter_custom_selector/flutter_custom_selector.dart';
import 'package:fe/screens/widgets/file_list_view.dart';
import 'package:path/path.dart';
import 'package:fe/data/repository/document_repository.dart';
import 'package:fe/data/models/document.dart';
import 'package:quickalert/quickalert.dart';
import 'package:particles_fly/particles_fly.dart';

class VerificationPage extends StatefulWidget {
  final bool isOnline;

  VerificationPage({required this.isOnline});

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final DigitalSignatureRepository repository = DigitalSignatureRepository();
  final DocumentRepository documentRepository = DocumentRepository();
  List<File> pickedPublicFile = [];
  List<File> pickedMessageFile = [];
  String? selectedMessageUrl;
  List? selectedFileName = [];
  List<FileInfo> messageFileInfos = [];

  @override
  void initState() {
    super.initState();
    if (widget.isOnline) {
      fetchData();
    }
  }

  Future<void> fetchData() async {
    try {
      messageFileInfos = await documentRepository.fetchDocuments();
      setState(() {});
    } catch (e) {
      print('Failed to fetch documents: $e');
    }
  }

  Future<void> pickFile(BuildContext context, List<File> fileList, List<String> allowedExtensions) async {
    const int maxFileSize = 2 * 1024 * 1024;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result != null) {
      File pickedFile = File(result.files.single.path!);
      int fileSize = await pickedFile.length();

      if (fileSize > maxFileSize) {
        showErrorDialog(context, "File size exceeds 2MB. Please select a smaller file.");
        return;
      }

      String extension = pickedFile.path.split('.').last;
      if (!allowedExtensions.contains(extension)) {
        showErrorDialog(context, "Invalid file type. Please select a ${allowedExtensions.join(', ')} file");
        return;
      }

      setState(() {
        fileList.clear();
        fileList.add(pickedFile);
      });
    }
  }

  void verifySignature(BuildContext context) async {
    if (pickedPublicFile.isEmpty || (!widget.isOnline && pickedMessageFile.isEmpty)) {
      showErrorDialog(context, "Please select all files.");
      return;
    }


      File publicFile = pickedPublicFile.first;

      if (widget.isOnline) {
        var result = await repository.verifyDetachedUrl(
          selectedMessageUrl!,
          publicFile.path,
        );
        handleVerificationResult(context, result, selectedFileName!, publicFile);
      } else {
        File messageFile = pickedMessageFile.first;
        var result = await repository.verifyDetached(
          messageFile.path,
          publicFile.path,
        );
        handleVerificationResult(context, result, [basename(messageFile.path), messageFile.lengthSync().toString()], publicFile);
      }
    
  }

  void handleVerificationResult(BuildContext context, Map<String, dynamic> result, List fileName, File publicFile) {
    bool verified = result['verified'];
    String message = (verified ? "Signature is Verified." : "Signature verification failed.");
    int frontendExecutionTime = result['frontendExecutionTime'] ?? 0;
    int serverExecutionTime = result['serverExecutionTime'] ?? 0;
    int verificationTime = result['verificationTime'] ?? 0;
    int communicationSize = result['communicationSize'] ?? 0;
    int memoryUsage = result['memoryUsage'] ?? 0;
    String variant = result['variant'] ?? null;

    QuickAlert.show(
      context: context,
      type: verified ? QuickAlertType.success : QuickAlertType.error,
      title: "Verification Result",
      text: message,
      widget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10),
          Text(verified ? '': result['message']),
          SizedBox(height: 10),
          buildFileDetailRow("Public Key File:", basename(publicFile.path), '${publicFile.lengthSync()} bytes'),
          buildFileDetailRow("Message File:", fileName[0], '${fileName[1]} bytes'),
          SizedBox(height: 10),
          Text("Variant: $variant"),
          Text("Frontend Execution Time: $frontendExecutionTime μs"),
          Text("Server Execution Time: $serverExecutionTime μs"),
          if (verified) Text("Communication Size: $communicationSize bytes"),
          if (verified) Text("Memory Usage: $memoryUsage bytes"),
        ],
      ),
      confirmBtnText: "OK",
      confirmBtnColor: verified ? Color(0xFF18c46c) : Color(0xFFDE0339),
      onConfirmBtnTap: () => Navigator.of(context).pop(),
    );
  }

  void showErrorDialog(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: "Error",
      text: message,
      confirmBtnText: "OK",
      confirmBtnColor: Color(0xFFDE0339),
    );
  }

  Widget buildFileDetailRow(String label, String fileName, String fileSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  fileName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text(
                fileSize,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> messageFileNames = messageFileInfos.map((fileInfo) => fileInfo.document.filename).toList();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Verification Page'),
      ),
      body: Stack(
        children: [
          ParticlesFly(
            height: size.height,
            width: size.width,
            connectDots: true,
            numberOfParticles: 30,
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isOnline)
                    CustomSingleSelectField<String>(
                      items: messageFileNames,
                      title: "Select Online Message File",
                      onSelectionDone: (fileName) {
                        FileInfo selectedFileInfo = messageFileInfos.firstWhere((fileInfo) => fileInfo.document.filename == fileName);
                        setState(() {
                          selectedMessageUrl = selectedFileInfo.url;
                          selectedFileName = [fileName, selectedFileInfo.size.toString()];
                        });
                      },
                      itemAsString: (item) => item,
                    ),
                  if (!widget.isOnline)
                    ElevatedButton(
                      onPressed: () => pickFile(context, pickedMessageFile, ["pdf"]),
                      child: Text('Select Message File (PDF)'),
                    ),
                  SizedBox(height: 10),
                  if (!widget.isOnline)
                    FileListView(fileList: pickedMessageFile, icon: Icons.message),
                  ElevatedButton(
                    onPressed: () => pickFile(context, pickedPublicFile, ["key"]),
                    child: Text('Select Public Key File'),
                  ),
                  SizedBox(height: 10),
                  FileListView(fileList: pickedPublicFile, icon: Icons.lock),
                  ElevatedButton(
                    onPressed: () => verifySignature(context),
                    child: Text('Verify Signature'),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
