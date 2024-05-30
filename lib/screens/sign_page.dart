import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';
import 'package:fe/data/repository/digital_signature_repository.dart';

class SignPage extends StatefulWidget {
  @override
  _SignPageState createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  final DigitalSignatureRepository repository = DigitalSignatureRepository();
  List<File> pickedPrivateFile = [];
  List<File> pickedMessageFile = [];

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

  Future<void> generateSign(BuildContext context) async {
    if (pickedPrivateFile.isEmpty || pickedMessageFile.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("Please select both private key file and message file."),
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

    final startTime = DateTime.now();

    try {
      File privateFile = pickedPrivateFile.first;
      File messageFile = pickedMessageFile.first;

      await repository.signDetached(messageFile.path, privateFile.path);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Success"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Signature generated successfully in $duration milliseconds."),
                SizedBox(height: 10),
                Text("Private Key File:"),
                Text("Name: ${basename(privateFile.path)}"),
                Text("Size: ${privateFile.lengthSync()} bytes"),
                SizedBox(height: 10),
                Text("Message File:"),
                Text("Name: ${basename(messageFile.path)}"),
                Text("Size: ${messageFile.lengthSync()} bytes"),
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
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Failed to generate signature: $e"),
                SizedBox(height: 10),
                Text("Execution time: $duration milliseconds"),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => pickedFile(pickedPrivateFile),
                    child: Text('Select Private Key File'),
                  ),
                  SizedBox(height: 20),
                  pickedPrivateFile.isNotEmpty
                      ? ListView.builder(
                      itemCount: pickedPrivateFile.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => openFile(pickedPrivateFile[index]),
                          child: Card(
                            child: ListTile(
                              leading: Icon(Icons.lock), // Ubah ikon sesuai dengan berkas kunci pribadi
                              title: Text(basename(pickedPrivateFile[index].path)),
                              subtitle: Text('${pickedPrivateFile[index].lengthSync()} bytes'),
                            ),
                          ),
                        );
                      })
                      : Container(),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => pickedFile(pickedMessageFile),
                    child: Text('Select Message File (PDF) '),
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
                              leading: Icon(Icons.message), // Ubah ikon sesuai dengan berkas pesan
                              title: Text(basename(pickedMessageFile[index].path)),
                              subtitle: Text('${pickedMessageFile[index].lengthSync()} bytes'),
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
                onPressed: () => generateSign(context),
                child: Text('Generate Sign'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
