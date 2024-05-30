import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';
import 'package:fe/data/repository/digital_signature_repository.dart';

class VerificationPage extends StatefulWidget {
  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final DigitalSignatureRepository repository = DigitalSignatureRepository();
  List<File> pickedPublicFile = [];
  List<File> pickedMessageFile = [];
  List<File> pickedSignatureFile = [];

  Future<void> pickedFile(List<File> selectFile) async {
    var result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );
    print(result);

    if (result != null) {
      setState(() {
        selectFile.clear();
        selectFile.add(File(result.files.single.path!));
      });
    }
  }

  openFile(File file) {
    OpenFile.open(file.path);
  }

  Future<void> verifySignature(BuildContext context) async {
    if (pickedPublicFile.isEmpty || pickedMessageFile.isEmpty || pickedSignatureFile.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("Please select all files: public key, message, and signature."),
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
      return;
    }

    try {
      File publicFile = pickedPublicFile.first;
      File messageFile = pickedMessageFile.first;
      File signatureFile = pickedSignatureFile.first;

      // Get all information from the server response
      Map<dynamic, dynamic> result = await repository.verifyDetached(messageFile.path, signatureFile.path, publicFile.path);

      bool verified = result['verified'];
      String executionTime = result['executionTime'];
      Map<String, String> fileSizes = Map<String, String>.from(result['fileSizes']);

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
                Text("Execution Time: $executionTime"),
                SizedBox(height: 10),
                Text("Public Key File:"),
                Text("Name: ${basename(publicFile.path)}"),
                Text("Size: ${fileSizes['publicKeyFileSize']}"),
                SizedBox(height: 5),
                Text("Message File:"),
                Text("Name: ${basename(messageFile.path)}"),
                Text("Size: ${fileSizes['pdfFileSize']}"),
                SizedBox(height: 5),
                Text("Signature File:"),
                Text("Name: ${basename(signatureFile.path)}"),
                Text("Size: ${fileSizes['signatureFileSize']}"),
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
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("Failed to verify signature: $e"),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verification Page'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => pickedFile(pickedPublicFile),
                      child: Text('Select Public Key File'),
                    ),
                    SizedBox(height: 20),
                    pickedPublicFile.isNotEmpty
                        ? ListView.builder(
                        itemCount: pickedPublicFile.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => openFile(pickedPublicFile[index]),
                            child: Card(
                              child: ListTile(
                                leading: Icon(Icons.lock),
                                title: Text(basename(pickedPublicFile[index].path)),
                                subtitle: Text('${pickedPublicFile[index].lengthSync()} bytes'),
                              ),
                            ),
                          );
                        })
                        : Container(),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => pickedFile(pickedMessageFile),
                      child: Text('Select Message File'),
                    ),
                    SizedBox(height: 20),
                    pickedMessageFile.isNotEmpty
                        ? ListView.builder(
                        itemCount: pickedMessageFile.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => openFile(pickedMessageFile[index]),
                            child: Card(
                              child: ListTile(
                                leading: Icon(Icons.message),
                                title: Text(basename(pickedMessageFile[index].path)),
                                subtitle: Text('${pickedMessageFile[index].lengthSync()} bytes'),
                              ),
                            ),
                          );
                        })
                        : Container(),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => pickedFile(pickedSignatureFile),
                      child: Text('Select Signature File'),
                    ),
                    SizedBox(height: 20),
                    pickedSignatureFile.isNotEmpty
                        ? ListView.builder(
                        itemCount: pickedSignatureFile.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => openFile(pickedSignatureFile[index]),
                            child: Card(
                              child: ListTile(
                                leading: Icon(Icons.check_circle),
                                title: Text(basename(pickedSignatureFile[index].path)),
                                subtitle: Text('${pickedSignatureFile[index].lengthSync()} bytes'),
                              ),
                            ),
                          );
                        })
                        : Container(),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => verifySignature(context),
                  child: Text('Verify Signature'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
