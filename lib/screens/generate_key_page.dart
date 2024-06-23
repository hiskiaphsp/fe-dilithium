import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fe/data/repository/digital_signature_repository.dart';
import 'package:flutter_custom_selector/flutter_custom_selector.dart';

class GenerateKeyPage extends StatefulWidget {
  @override
  _GenerateKeyPageState createState() => _GenerateKeyPageState();
}

class _GenerateKeyPageState extends State<GenerateKeyPage> {
  List<String> dataString = [
    "Dilithium2",
    "Dilithium3",
    "Dilithium5"
  ];
  String? selectedString;

  final DigitalSignatureRepository _repository = DigitalSignatureRepository();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> _downloadKey() async {
    String message;
    Color backgroundColor;

    try {
      if (selectedString != null) {
        await _repository.downloadKeyPair(selectedString!); // Pass the selected mode
        message = 'Key pair downloaded successfully';
        backgroundColor = Colors.black;
      } else {
        message = 'Please select a mode';
        backgroundColor = Colors.red;
      }
    } catch (e) {
      message = 'Failed to download key pair';
      backgroundColor = Colors.red;
    }

    _showMessageDialog(message, backgroundColor);
  }

  void _showMessageDialog(String message, Color backgroundColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(
            message,
            style: TextStyle(color: backgroundColor),
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Key'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Press the button below to generate and download the key',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: CustomSingleSelectField<String>(
                items: dataString,
                title: "Select Mode",
                onSelectionDone: (value) {
                  selectedString = value;
                  setState(() {});
                },
                itemAsString: (item) => item,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _downloadKey,
                child: Text('Download Key'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
