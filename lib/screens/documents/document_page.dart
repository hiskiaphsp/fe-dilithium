import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fe/data/models/document.dart';
import 'package:fe/screens/documents/widgets/document_card.dart';
import 'package:fe/data/repository/document_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:quickalert/quickalert.dart';
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        if (file.lengthSync() > 5 * 1024 * 1024) { // Check if file size is greater than 5 MB
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File size exceeds 5 MB'),
              backgroundColor: Colors.red, // Set the background color to red
            ),
          );
        } else {
          setState(() {
            _selectedFile = file;
            _fileSelected = true;
          });
        }
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

  void _showUploadConfirmationDialog() {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'Confirm Upload',
      text: 'Do you want to upload the selected file?',
      confirmBtnText: 'Confirm',
      cancelBtnText: 'Cancel',
      confirmBtnColor: Color(0xFF33cdbb),
      onCancelBtnTap: () {
        Navigator.of(context).pop();
        setState(() {
          _fileSelected = false;
        });
      },
      onConfirmBtnTap: () {
        Navigator.of(context).pop();
        _uploadFile();
      },
    );
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
              onPressed: _showUploadConfirmationDialog,
              child: Icon(Icons.cloud_upload),
            )
          : FloatingActionButton(
              onPressed: _pickAndUploadFile,
              child: Icon(Icons.add),
            ),
    );
  }
}
