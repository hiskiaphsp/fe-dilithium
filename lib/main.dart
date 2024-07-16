import 'package:fe/screens/analyze_page.dart';
import 'package:flutter/material.dart';
import 'package:fe/screens/documents/document_page.dart';
import 'package:fe/screens/generate_key_page.dart';
import 'package:fe/screens/sign_page.dart';
import 'package:fe/screens/verification_page.dart';
import 'package:quickalert/quickalert.dart';
import 'package:particles_fly/particles_fly.dart'; // Import particles_fly package

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Signature App'),
      ),
      body: Stack(
        children: [
          ParticlesFly(
            height: size.height,
            width: size.width,
            connectDots: true,
            numberOfParticles: 40,
          ), // Add particle effects background
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GenerateKeyPage()),
                    );
                  },
                  icon: Icon(Icons.key),
                  label: Text('Generate Key'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(200, 50),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    showDocumentSourceAlert(context, 'Sign', (valueOnline) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignPage(isOnline: valueOnline)),
                      );
                    });
                  },
                  icon: Icon(Icons.edit),
                  label: Text('Sign'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(200, 50),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    showDocumentSourceAlert(context, 'Verification', (valueOnline) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => VerificationPage(isOnline: valueOnline)),
                      );
                    });
                  },
                  icon: Icon(Icons.check),
                  label: Text('Verify'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(200, 50),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        showDocumentSourceAlert(context, 'Time Execution', (valueOnline) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AnalyzePage(isOnline: valueOnline)),
                          );
                        });
                      },
                      icon: Icon(Icons.timelapse),
                      label: Text('Time Execution'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(160, 50), // Adjust the width as needed
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DocumentPage()),
                        );
                      },
                      icon: Icon(Icons.folder),
                      label: Text('Documents'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(160, 50), // Adjust the width as needed
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showDocumentSourceAlert(BuildContext context, String action, Function(bool) onSelected) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.custom,
      title: 'Choose Document Source',
      titleColor: Colors.white,
      backgroundColor: Color(0xFF252526),
      widget: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              onSelected(false);
            },
            child: Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: Text(
                  'From Local Document',
                  style: TextStyle(
                    color: Color(0xFF252526),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              onSelected(true);
            },
            child: Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: Text(
                  'From Online Document',
                  style: TextStyle(
                    color: Color(0xFF252526),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      showCancelBtn: true,
      showConfirmBtn: false,
    );
  }
}
