import 'package:flutter/material.dart';
import 'package:fe/data/models/document.dart';
import 'package:fe/screens/documents/widgets/pdf_preview.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:fe/data/repository/document_repository.dart';

class DocumentCard extends StatelessWidget {
  final FileInfo fileInfo;
  final DocumentRepository repository = DocumentRepository();
  final Function onDelete; // Callback to refresh document list

  DocumentCard({required this.fileInfo, required this.onDelete});

  void _deleteDocument(BuildContext context) async {
    try {
      await repository.deleteDocument(fileInfo.document.id);
      onDelete(); // Notify parent to refresh document list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PDF Preview Container
            Container(
              width: 50, // Adjust width as needed
              height: 75, // Adjust height as needed
              child: PDF(
                fitEachPage: true,
                swipeHorizontal: true,
                pageSnap: false,
                onPageChanged: (int? page, int? total) {},
              ).fromUrl(
                fileInfo.url,
                placeholder: (double progress) =>
                    Center(child: CircularProgressIndicator(value: progress)),
                errorWidget: (dynamic error) => Center(child: Text(error.toString())),
              ),
            ),
            SizedBox(width: 16.0), // Add spacing between preview and text
            // Title and "Click here to see" text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileInfo.document.filename,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2, // Limit title to 2 lines
                    overflow: TextOverflow.ellipsis, // Handle long titles
                  ),
                  Text('size: ${fileInfo.size} kb'),
                  SizedBox(height: 8.0),
                  GestureDetector(
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfPreviewPage(url: fileInfo.url),
                        ),
                      );
                    },
                    child: Text(
                      'Click here to see',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteDocument(context),
            ),
          ],
        ),
      ),
    );
  }
}
