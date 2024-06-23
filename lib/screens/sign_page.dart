import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';
import 'package:fe/data/repository/digital_signature_repository.dart';
import 'package:flutter_custom_selector/flutter_custom_selector.dart';

class SignPage extends StatefulWidget {
  @override
  _SignPageState createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  final DigitalSignatureRepository repository = DigitalSignatureRepository();
  List<File> pickedPrivateFile = [];
  List<File> pickedMessageFile = [];
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

  void openFile(File file) {
    OpenFile.open(file.path);
  }

  Future<void> generateSignature(BuildContext context) async {
    if (pickedPrivateFile.isEmpty || pickedMessageFile.isEmpty || selectedMode == null) {
      showErrorDialog(context, "Please select both private key file, message file, and mode.");
      return;
    }

    try {
      File privateFile = pickedPrivateFile.first;
      File messageFile = pickedMessageFile.first;

      await repository.signDetached(messageFile.path, privateFile.path, selectedMode!);

      showSuccessDialog(context, privateFile, messageFile);
    } catch (e) {
      showErrorDialog(context, "Failed to generate signature: $e");
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

  void showSuccessDialog(BuildContext context, File privateFile, File messageFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Success"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Signature generated successfully"),
              SizedBox(height: 10),
              buildFileDetailRow("Private Key File:", basename(privateFile.path), '${privateFile.lengthSync()} bytes'),
              buildFileDetailRow("Message File:", basename(messageFile.path), '${messageFile.lengthSync()} bytes'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Page'),
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
                onPressed: () => pickFile(pickedPrivateFile),
                child: Text('Select Private Key File'),
              ),
              SizedBox(height: 10),
              buildFileListView(pickedPrivateFile, Icons.lock),
              ElevatedButton(
                onPressed: () => pickFile(pickedMessageFile),
                child: Text('Select Message File (PDF)'),
              ),
              SizedBox(height: 10),
              buildFileListView(pickedMessageFile, Icons.message),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => generateSignature(context),
                child: Text('Generate Signature'),
              ),
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
