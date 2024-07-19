import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
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
  List<File> pickedSignatureFile = [];
  String? selectedMessageUrl;
  List? selectedFileName = []; // Added to store selected message URL
  List<FileInfo> messageFileInfos = []; // Added to store message file infos
  List<FileInfo> signatureFileInfos = []; // Added to store signature file infos

  @override
  void initState() {
    super.initState();
    if (widget.isOnline) {
      fetchData();
    }
  }

  Future<void> fetchData() async {
    try {
      messageFileInfos = await documentRepository.fetchDocuments(); // Fetch message FileInfo
      setState(() {});
    } catch (e) {
      print('Failed to fetch documents: $e');
    }
  }

  Future<void> pickFile(BuildContext context, List<File> fileList, List<String> allowedExtensions) async {
    const int maxFileSize = 5 * 1024 * 1024; // 5MB in bytes

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result != null) {
      File pickedFile = File(result.files.single.path!);
      int fileSize = await pickedFile.length();

      if (fileSize > maxFileSize) {
        showErrorDialog(context, "File size exceeds 5MB. Please select a smaller file.");
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
  if (pickedPublicFile.isEmpty || (!widget.isOnline && (pickedMessageFile.isEmpty || pickedSignatureFile.isEmpty))) {
    showErrorDialog(context, "Please select all files.");
    return;
  }

  try {
    File publicFile = pickedPublicFile.first;
    File signatureFile = pickedSignatureFile.first;
    int executionTime;

    if (widget.isOnline) {
      var result = await repository.verifyDetachedUrl(
        selectedMessageUrl!,
        signatureFile.path,
        publicFile.path,
      );
      bool verified = result['verified'];
      executionTime = result['executionTime'];
      showVerificationResultDialogOnline(context, verified, selectedFileName!, publicFile, signatureFile, executionTime);
    } else {
      File messageFile = pickedMessageFile.first;
      var result = await repository.verifyDetached(
        messageFile.path,
        signatureFile.path,
        publicFile.path,
      );
      bool verified = result['verified'];
      executionTime = result['executionTime'];
      showVerificationResultDialogOffline(context, verified, publicFile, messageFile, signatureFile, executionTime);
    }
  } catch (e) {
    showErrorDialog(context, "Failed to verify signature: $e");
  }
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

  void showVerificationResultDialogOnline(BuildContext context, bool verified, List fileName, File publicFile, File signatureFile, int executionTime) {
    QuickAlert.show(
      context: context,
      type: verified ? QuickAlertType.success : QuickAlertType.error,
      title: "Verification Result",
      widget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10),
          Text(verified ? "Signature is Verified." : "Signature verification failed."),
          SizedBox(height: 10),
          buildFileDetailRow("Public Key File:", basename(publicFile.path), '${publicFile.lengthSync()} bytes'),
          buildFileDetailRow("Signed File:", fileName[0], '${fileName[1]} bytes'),
          buildFileDetailRow("Signature File:", basename(signatureFile.path), '${signatureFile.lengthSync()} bytes'),
          SizedBox(height: 10),
          Text("Execution Time: $executionTime μs"),
        ],
      ),
      confirmBtnText: "OK",
      confirmBtnColor: verified ? Color(0xFF18c46c) : Color(0xFFDE0339),
      onConfirmBtnTap: () => Navigator.of(context).pop(),
    );
  }

  void showVerificationResultDialogOffline(BuildContext context, bool verified, File publicFile, File messageFile, File signatureFile, int executionTime) {
    QuickAlert.show(
      context: context,
      type: verified ? QuickAlertType.success : QuickAlertType.error,
      title: "Verification Result",
      widget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10),
          Text(verified ? "Signature is Verified." : "Signature verification failed."),
          SizedBox(height: 10),
          buildFileDetailRow("Public Key File:", basename(publicFile.path), '${publicFile.lengthSync()} bytes'),
          buildFileDetailRow("Message File:", basename(messageFile.path), '${messageFile.lengthSync()} bytes'),
          buildFileDetailRow("Signature File:", basename(signatureFile.path), '${signatureFile.lengthSync()} bytes'),
          SizedBox(height: 10),
          Text("Execution Time: $executionTime μs"),
        ],
      ),
      confirmBtnText: "OK",
      confirmBtnColor: verified ? Color(0xFF18c46c) : Color(0xFFDE0339),
      onConfirmBtnTap: () => Navigator.of(context).pop(),
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
    List<String> signatureFileNames = signatureFileInfos.map((fileInfo) => fileInfo.document.filename).toList();
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
                      child: Text('Select Message File'),
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
                    onPressed: () => pickFile(context, pickedSignatureFile, ["sig"]),
                    child: Text('Select Signature File'),
                  ),
                  SizedBox(height: 10),
                  FileListView(fileList: pickedSignatureFile, icon: Icons.check_circle),
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
