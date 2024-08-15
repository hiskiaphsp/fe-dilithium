import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fe/data/repository/digital_signature_repository.dart';
import 'package:flutter_custom_selector/flutter_custom_selector.dart';
import 'package:quickalert/quickalert.dart';
import 'package:particles_fly/particles_fly.dart';

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
    bool type;
    int? executionTime;

    try {
      if (selectedString != null) {
        var result = await _repository.downloadKeyPair(selectedString!); // Pass the selected mode
        executionTime = result['executionTime'];
        message = 'Key pair downloaded successfully\nExecution Time: ${executionTime} μs';
        backgroundColor = Colors.white;
        type = true;
      } else {
        message = 'Please select a Variant';
        backgroundColor = Colors.white;
        type = false;
      }
    } catch (e) {
      message = 'Failed to download key pair';
      backgroundColor = Colors.white;
      type = false;
    }

    _showMessageDialog(message, backgroundColor, type);
  }

  void _showMessageDialog(String message, Color backgroundColor, bool typeQ) {
    QuickAlert.show(
      context: context,
      type: typeQ ? QuickAlertType.success : QuickAlertType.error,
      text: message,
      backgroundColor: backgroundColor,
      confirmBtnColor: typeQ ? Color(0xFF18c46c) : Color(0xFFDE0339),
      confirmBtnText: 'OK',
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Key'),
      ),
      body: Stack(
        children: [
          ParticlesFly(
            height: size.height,
            width: size.width,
            connectDots: true,
            numberOfParticles: 30,
          ),
          Center(
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
                    title: "Select Variant",
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
        ],
      ),
    );
  }
}
