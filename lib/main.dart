import 'package:flutter/material.dart';
import 'package:fe/screens/documents/document_page.dart';
import 'package:fe/screens/generate_key_page.dart';
import 'package:fe/screens/sign_page.dart';
import 'package:fe/screens/verification_page.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Dilithium App'),
      ),
      body: Center(
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
                // Tampilkan dialog atau modal untuk meminta pengguna memilih sumber dokumen.
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Choose Document Source'),
                      content: SingleChildScrollView(
                        child: ListBody(
                          children: <Widget>[
                            GestureDetector(
                              child: Text('Sign From Local Document'),
                              onTap: () {
                                Navigator.of(context).pop(false); // Pop modal dengan nilai false
                              },
                            ),
                            SizedBox(height: 10),
                            GestureDetector(
                              child: Text('Sign From Online Document'),
                              onTap: () {
                                Navigator.of(context).pop(true); // Pop modal dengan nilai true
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ).then((valueOnline) {
                  // Setelah modal tertutup, valueOnline akan berisi true atau false
                  if (valueOnline != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignPage(isOnline: valueOnline)),
                    );
                  }
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
                // Tampilkan dialog atau modal untuk meminta pengguna memilih sumber dokumen.
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Choose Document Source'),
                      content: SingleChildScrollView(
                        child: ListBody(
                          children: <Widget>[
                            GestureDetector(
                              child: Text('Verification From Local Document'),
                              onTap: () {
                                Navigator.of(context).pop(false); // Pop modal dengan nilai false
                              },
                            ),
                            SizedBox(height: 10),
                            GestureDetector(
                              child: Text('Verification From Online Document'),
                              onTap: () {
                                Navigator.of(context).pop(true); // Pop modal dengan nilai true
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ).then((valueOnline) {
                  // Setelah modal tertutup, valueOnline akan berisi true atau false
                  if (valueOnline != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VerificationPage(isOnline: valueOnline)),
                    );
                  }
                });
              },
              icon: Icon(Icons.check),
              label: Text('Verification'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200, 50),
              ),
            ),
            SizedBox(height: 16),
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
                minimumSize: Size(200, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
