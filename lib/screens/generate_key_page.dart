import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fe/data/repository/digital_signature_repository.dart';

class GenerateKeyPage extends StatefulWidget {
  @override
  _GenerateKeyPageState createState() => _GenerateKeyPageState();
}

class _GenerateKeyPageState extends State<GenerateKeyPage> {
  final DigitalSignatureRepository _repository = DigitalSignatureRepository();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> _downloadKey() async {
    final startTime = DateTime.now();
    String message;
    Color backgroundColor;

    try {
      await _repository.downloadKeyPair();
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      message = 'Key pair downloaded successfully in $duration ms';
      backgroundColor = Colors.black;
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      message = 'Failed to download key pair in $duration ms';
      backgroundColor = Colors.black;
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
          children: [
            Text(
              'Press the button below to generate and download the key',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _downloadKey,
              child: Text('Download Key'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
