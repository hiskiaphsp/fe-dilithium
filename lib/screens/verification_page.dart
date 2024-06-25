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
  String? selectedMode;
  String? selectedMessageUrl; // Added to store selected message URL
  String? selectedSignatureUrl; // Added to store selected signature URL
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

  Future<void> pickFile(List<File> fileList) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        fileList.clear();
        fileList.add(File(result.files.single.path!));
      });
    }
  }

  openFile(File file) {
    OpenFile.open(file.path);
  }

  Future<void> verifySignature(BuildContext context) async {
    if (pickedPublicFile.isEmpty || selectedMode == null || (!widget.isOnline && (pickedMessageFile.isEmpty || pickedSignatureFile.isEmpty))) {
      showErrorDialog(context, "Please select all files and mode.");
      return;
    }

    try {
      File publicFile = pickedPublicFile.first;
      File signatureFile = pickedSignatureFile.first;

      if (widget.isOnline) {
        var result = await repository.verifyDetachedUrl(
          selectedMessageUrl!,
          signatureFile.path,
          publicFile.path,
          selectedMode!,
        );
        bool verified = result['verified'];
        showVerificationResultDialogOnline(context, verified, publicFile);
      } else {
        File messageFile = pickedMessageFile.first;
        File signatureFile = pickedSignatureFile.first;
        var result = await repository.verifyDetached(
          messageFile.path,
          signatureFile.path,
          publicFile.path,
          selectedMode!,
        );
        bool verified = result['verified'];
        showVerificationResultDialogOffline(context, verified, publicFile, messageFile, signatureFile);
      }
    } catch (e) {
      showErrorDialog(context, "Failed to verify signature: $e");
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void showVerificationResultDialogOnline(BuildContext context, bool verified, File publicFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Verification Result"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(verified ? "Signature is verified." : "Signature verification failed."),
              SizedBox(height: 10),
              buildFileDetailRow("Public Key File:", basename(publicFile.path)),
              buildFileDetailRow("Message File:", "Online Document"),
              buildFileDetailRow("Signature File:", "Online Document"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void showVerificationResultDialogOffline(BuildContext context, bool verified, File publicFile, File messageFile, File signatureFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Verification Result"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(verified ? "Signature is verified." : "Signature verification failed."),
              SizedBox(height: 10),
              buildFileDetailRow("Public Key File:", basename(publicFile.path)),
              buildFileDetailRow("Message File:", basename(messageFile.path)),
              buildFileDetailRow("Signature File:", basename(signatureFile.path)),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Widget buildFileDetailRow(String label, String fileName) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Verification Page'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomSingleSelectField<String>(
                items: ["Dilithium2", "Dilithium3", "Dilithium5"],
                title: "Select Mode",
                onSelectionDone: (value) {
                  setState(() {
                    selectedMode = value;
                  });
                },
                itemAsString: (item) => item,
              ),
              SizedBox(height: 10),
              if (widget.isOnline) // Tampilkan hanya jika isOnline true
                CustomSingleSelectField<String>(
                  items: messageFileNames, // Gunakan messageFileNames sebagai items
                  title: "Select Online Message File",
                  onSelectionDone: (fileName) {
                    // Temukan URL yang sesuai
                    FileInfo selectedFileInfo = messageFileInfos.firstWhere((fileInfo) => fileInfo.document.filename == fileName);
                    setState(() {
                      selectedMessageUrl = selectedFileInfo.url; // Simpan URL yang dipilih
                    });
                  },
                  itemAsString: (item) => item,
                ),
              if (!widget.isOnline) // Tampilkan hanya jika isOnline false
                ElevatedButton(
                  onPressed: () => pickFile(pickedMessageFile),
                  child: Text('Select Message File'),
                ),
                SizedBox(height: 10),
              if (!widget.isOnline) // Tampilkan hanya jika isOnline false
                FileListView(fileList: pickedMessageFile, icon: Icons.message),
              ElevatedButton(
                onPressed: () => pickFile(pickedPublicFile),
                child: Text('Select Public Key File'),
              ),
              SizedBox(height: 10),
              FileListView(fileList: pickedPublicFile, icon: Icons.lock),
              ElevatedButton(
                onPressed: () => pickFile(pickedSignatureFile),
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
    );
  }
}
