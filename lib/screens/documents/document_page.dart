import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fe/data/models/document.dart';
import 'package:fe/screens/documents/widgets/document_card.dart';
import 'package:fe/data/repository/document_repository.dart';
import 'package:file_picker/file_picker.dart';

import 'package:particles_fly/particles_fly.dart'; 

class DocumentPage extends StatefulWidget {
  @override
  _DocumentPageState createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  late Future<List<FileInfo>> futureDocuments;
  final DocumentRepository repository = DocumentRepository();
  bool _fileSelected = false;
  late File _selectedFile;

  @override
  void initState() {
    super.initState();
    futureDocuments = repository.fetchDocuments();
  }

  Future<void> _refreshDocuments() async {
    setState(() {
      futureDocuments = repository.fetchDocuments();
    });
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileSelected = true;
        });
      } else {
        // User canceled the picker
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select file: $e')),
      );
    }
  }

  Future<void> _uploadFile() async {
    try {
      await repository.addDocument(_selectedFile);
      _refreshDocuments(); // Refresh document list after adding document
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _fileSelected = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add document: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size; // Get screen size

    return Scaffold(
      appBar: AppBar(
        title: Text('Documents'),
      ),
      body: Stack(
        children: [
          ParticlesFly( // ParticlesFly widget
            height: size.height,
            width: size.width,
            connectDots: true,
            numberOfParticles: 40,
          ),
          FutureBuilder<List<FileInfo>>(
            future: futureDocuments,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No documents found'));
              } else {
                return RefreshIndicator(
                  onRefresh: _refreshDocuments,
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      FileInfo fileInfo = snapshot.data![index];
                      return DocumentCard(
                        fileInfo: fileInfo,
                        onDelete: _refreshDocuments, // Pass onDelete callback
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: _fileSelected
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Confirm Upload'),
                      content: Text('Do you want to upload the selected file?'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('Confirm'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _uploadFile();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: Icon(Icons.cloud_upload),
            )
          : FloatingActionButton(
              onPressed: _pickAndUploadFile,
              child: Icon(Icons.add),
            ),
    );
  }
}
