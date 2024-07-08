import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';
import 'package:fe/data/repository/digital_signature_repository.dart';
import 'package:flutter_custom_selector/flutter_custom_selector.dart';
import 'package:fe/screens/widgets/file_list_view.dart';
import 'package:fe/data/repository/document_repository.dart';
import 'package:fe/data/models/document.dart';
import 'package:quickalert/quickalert.dart';
import 'package:particles_fly/particles_fly.dart';

class SignPage extends StatefulWidget {
  final bool isOnline;

  SignPage({required this.isOnline});
  @override
  _SignPageState createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  final DigitalSignatureRepository repository = DigitalSignatureRepository();
  final DocumentRepository documentRepository = DocumentRepository();
  List<File> pickedPrivateFile = [];
  List<File> pickedMessageFile = [];
  String? selectedMode;
  String? selectedUrl;
  List<FileInfo> fileInfos = [];
  List? selectedFileName = [];

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

  Future<void> pickFile(List<File> fileList) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        fileList.clear();
        fileList.add(File(result.files.single.path!));
      });
    }
  }

  void openFile(File file) {
    OpenFile.open(file.path);
  }

  Future<void> generateSignature(BuildContext context) async {
    try {
      File privateFile = pickedPrivateFile.first;
      if (widget.isOnline) {
        await repository.signDetachedUrl(selectedUrl!, privateFile.path, selectedMode!);
        showSuccessDialogOnline(context, privateFile, selectedFileName!);
      } else {
        File messageFile = pickedMessageFile.first;
        await repository.signDetached(messageFile.path, privateFile.path, selectedMode!);
        showSuccessDialogOffline(context, privateFile, messageFile);
      }
    } catch (e) {
      showErrorDialog(context, "Failed to generate signature: $e");
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      text: message,
      confirmBtnColor: Color(0xFFDE0339),
      confirmBtnText: 'OK',
    );
  }

  void showSuccessDialogOnline(BuildContext context, File privateFile, List fileName) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: "Signature generated successfully",
      widget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildFileDetailRow("Private Key File:", basename(privateFile.path), '${privateFile.lengthSync()} bytes'),
          buildFileDetailRow("Signed File:", fileName[0], '${fileName[1]} bytes'),
        ],
      ),
      confirmBtnColor: Color(0xFF18c46c),
      confirmBtnText: 'OK',
    );
  }

  void showSuccessDialogOffline(BuildContext context, File privateFile, File messageFile) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: "Signature generated successfully",
      widget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildFileDetailRow("Private Key File:", basename(privateFile.path), '${privateFile.lengthSync()} bytes'),
          buildFileDetailRow("Message File:", basename(messageFile.path), '${messageFile.lengthSync()} bytes'),
        ],
      ),
      confirmBtnColor: Color(0xFF18c46c),
      confirmBtnText: 'OK',
    );
  }

  Widget buildFileDetailRow(String label, String fileName, String fileSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  fileName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text(
                fileSize,
                style: TextStyle(color: Colors.grey),
              ),
            ],
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
        title: Text('Sign Page'),
      ),
      body: Stack(
        children: [
          ParticlesFly(
            height: size.height,
            width: size.width,
            connectDots: true,
            numberOfParticles: 30,
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
                  SizedBox(height: 10,),
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
                  ElevatedButton(
                    onPressed: () => pickFile(pickedPrivateFile),
                    child: Text('Select Private Key File'),
                  ),
                  SizedBox(height: 10),
                  FileListView(fileList: pickedPrivateFile, icon: Icons.lock),
                  if (!widget.isOnline) // Tampilkan hanya jika isOnline false
                    ElevatedButton(
                      onPressed: () => pickFile(pickedMessageFile),
                      child: Text('Select Message File (PDF)'),
                    ),
                  SizedBox(height: 10),
                  FileListView(fileList: pickedMessageFile, icon: Icons.message),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => generateSignature(context),
                    child: Text('Generate Signature'),
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
