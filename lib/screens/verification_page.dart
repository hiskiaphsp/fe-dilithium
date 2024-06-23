import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';
import 'package:fe/data/repository/digital_signature_repository.dart';
import 'package:flutter_custom_selector/flutter_custom_selector.dart';

class VerificationPage extends StatefulWidget {
  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final DigitalSignatureRepository repository = DigitalSignatureRepository();
  List<File> pickedPublicFile = [];
  List<File> pickedMessageFile = [];
  List<File> pickedSignatureFile = [];
  String? selectedMode;

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
    if (pickedPublicFile.isEmpty || pickedMessageFile.isEmpty || pickedSignatureFile.isEmpty || selectedMode == null) {
      showErrorDialog(context, "Please select all files and mode.");
      return;
    }

    try {
      File publicFile = pickedPublicFile.first;
      File messageFile = pickedMessageFile.first;
      File signatureFile = pickedSignatureFile.first;

      var result = await repository.verifyDetached(
        messageFile.path,
        signatureFile.path,
        publicFile.path,
        selectedMode!,
      );

      bool verified = result['verified'];

      showVerificationResultDialog(context, verified, publicFile, messageFile, signatureFile);
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

  void showVerificationResultDialog(BuildContext context, bool verified, File publicFile, File messageFile, File signatureFile) {
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
              ElevatedButton(
                onPressed: () => pickFile(pickedPublicFile),
                child: Text('Select Public Key File'),
              ),
              SizedBox(height: 10),
              buildFileListView(pickedPublicFile, Icons.lock),
              ElevatedButton(
                onPressed: () => pickFile(pickedMessageFile),
                child: Text('Select Message File'),
              ),
              SizedBox(height: 10),

              buildFileListView(pickedMessageFile, Icons.message),
              ElevatedButton(
                onPressed: () => pickFile(pickedSignatureFile),
                child: Text('Select Signature File'),
              ),
              SizedBox(height: 10),
              buildFileListView(pickedSignatureFile, Icons.check_circle),
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

  Widget buildFileListView(List<File> fileList, IconData icon) {
    return fileList.isNotEmpty
        ? ListView.builder(
            itemCount: fileList.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => openFile(fileList[index]),
                child: Card(
                  child: ListTile(
                    leading: Icon(icon),
                    title: Text(
                      basename(fileList[index].path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${fileList[index].lengthSync()} bytes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            },
          )
        : Container();
  }
}
