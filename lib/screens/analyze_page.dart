import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:quickalert/quickalert.dart';
import 'package:path/path.dart';
import 'package:fe/data/repository/digital_signature_repository.dart';
import 'package:flutter_custom_selector/flutter_custom_selector.dart';
import 'package:fe/screens/widgets/file_list_view.dart';
import 'package:fe/data/repository/document_repository.dart';
import 'package:fe/data/models/document.dart';
import 'package:dio/dio.dart';
import 'package:particles_fly/particles_fly.dart';

class AnalyzePage extends StatefulWidget {
  final bool isOnline;

  AnalyzePage({required this.isOnline});
  @override
  _AnalyzePageState createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  final DigitalSignatureRepository repository = DigitalSignatureRepository();
  final DocumentRepository documentRepository = DocumentRepository();

  String? selectedMode;
  String? selectedUrl;
  List<FileInfo> fileInfos = [];
  List? selectedFileName = [];
  List<File> pickedMessageFile = [];

  @override
  void initState() {
    super.initState();
    if (widget.isOnline) {
      fetchData();
    }
  }

  Future<void> fetchData() async {
    try {
      fileInfos = await documentRepository.fetchDocuments(); // Fetch FileInfo
      setState(() {});
    } catch (e) {
      print('Failed to fetch documents: $e');
    }
  }

  Future<void> pickFile(BuildContext context, List<File> fileList, List<String> allowedExtensions) async {
    const int maxFileSize = 5 * 1024 * 1024; // 5MB in bytes

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result != null) {
      File pickedFile = File(result.files.single.path!);
      int fileSize = await pickedFile.length();

      if (fileSize > maxFileSize) {
        showErrorAlert(context, "File size exceeds 5MB. Please select a smaller file.");
        return;
      }

      String extension = pickedFile.path.split('.').last;
      if (!allowedExtensions.contains(extension)) {
        showErrorAlert(context, "Invalid file type. Please select a ${allowedExtensions.join(', ')} file");
        return;
      }

      setState(() {
        fileList.clear();
        fileList.add(pickedFile);
      });
    }
  }



  void openFile(File file) {
    OpenFile.open(file.path);
  }

  Future<void> generateSignature(BuildContext context) async {
    try {
      if (selectedMode == null) {
        showErrorAlert(context, "Please select a mode");
        return;
      }

      Map<String, dynamic> result;
      if (widget.isOnline) {
        if (selectedUrl == null) {
          showErrorAlert(context, "Please select a document");
          return;
        }
        result = await documentRepository.analyzeUrl(selectedUrl!, selectedMode!);
      } else {
        if (pickedMessageFile.isEmpty) {
          showErrorAlert(context, "Please select the required files");
          return;
        }
        File messageFile = pickedMessageFile.first;
        result = await documentRepository.analyze(messageFile, selectedMode!);
      }

      showSuccessAlert(context, result);
    } catch (e) {
      showErrorAlert(context, "Failed to generate signature: $e");
    }
  }

  void showErrorAlert(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Error',
      text: message,
      confirmBtnText: 'OK',
      confirmBtnColor: Color(0xFFDE0339),
    );
  }
  

  void showSuccessAlert(BuildContext context, Map<String, dynamic> result) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: 'Success',
      widget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Time Execution successfully"),
          SizedBox(height: 10),
          // buildFileDetailRow("Key Generation Time:", "${result['key_generation_time']} μs"),
          buildFileDetailRow("Message File Size:", "${result['message_size_bytes']} bytes"),
          buildFileDetailRow("Private Key Size:", "${result['private_key_size_bytes']} bytes"),
          buildFileDetailRow("Public Key Size:", "${result['public_key_size_bytes']} bytes"),
          buildFileDetailRow("Signature Size:", "${result['signature_size_bytes']} bytes"),
          buildFileDetailRow("Signing Time:", "${result['signing_time']} μs"),
          buildFileDetailRow("Verification Time:", "${result['verification_time']} μs"),
          buildFileDetailRow("Valid:", "${result['valid']}"),
        ],
      ),
      confirmBtnColor: Color(0xFF18c46c),
      confirmBtnText: 'OK',
    );
  }

  Widget buildFileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> fileNames = fileInfos.map((fileInfo) => fileInfo.document.filename).toList();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Time Execution Page'),
      ),
      body: Stack(
        children: [
          ParticlesFly(
            height: size.height,
            width: size.width,
            connectDots: true,
            numberOfParticles: 40,
          ),
          SingleChildScrollView(
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
                  if (widget.isOnline) // Tampilkan hanya jika isOnline true
                    CustomSingleSelectField<String>(
                      items: fileNames, // Gunakan fileNames sebagai items
                      title: "Select Online Document File",
                      onSelectionDone: (fileName) {
                        // Temukan URL yang sesuai
                        FileInfo selectedFileInfo = fileInfos.firstWhere((fileInfo) => fileInfo.document.filename == fileName);
                        setState(() {
                          selectedUrl = selectedFileInfo.url; // Simpan URL yang dipilih
                          selectedFileName = [fileName, selectedFileInfo.size.toString()]; // Simpan nama file yang dipilih
                        });
                      },
                      itemAsString: (item) => item,
                    ),
                  SizedBox(height: 10),
                  if (!widget.isOnline) // Tampilkan hanya jika isOnline false
                    ElevatedButton(
                      onPressed: () => pickFile(context, pickedMessageFile, ["pdf"]),
                      child: Text('Select Message File (PDF)'),
                    ),
                  SizedBox(height: 10),
                  FileListView(fileList: pickedMessageFile, icon: Icons.message),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => generateSignature(context),
                    child: Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
