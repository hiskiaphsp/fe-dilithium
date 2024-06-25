import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:fe/data/models/document.dart';

class DocumentRepository {
  final Dio _dio;
  final String baseUrl;

  DocumentRepository({Dio? dio, this.baseUrl = 'http://127.0.0.1:8080'})
      : _dio = dio ?? Dio();

  Future<List<FileInfo>> fetchDocuments() async {
    try {
      final response = await _dio.get('$baseUrl/documents');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return parseFileInfoList(data);
      } else {
        throw Exception('Failed to load documents');
      }
    } catch (e) {
      throw Exception('Failed to load documents: $e');
    }
  }

 Future<void> addDocument(File file) async {
    try {
      String fileName = file.path.split('/').last; // Extract filename from path

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post('$baseUrl/documents', data: formData);

      if (response.statusCode != 201) {
        throw Exception('Failed to add document');
      }
    } catch (e) {
      throw Exception('Failed to add document: $e');
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      final response = await _dio.delete('$baseUrl/documents/$documentId');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete document');
      }
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  Future<List<String>> fetchDocumentUrls() async {
    try {
      final response = await _dio.get('$baseUrl/documents');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        List<FileInfo> fileInfoList = parseFileInfoList(data);

        List<String> urls = fileInfoList.map((fileInfo) => fileInfo.url).toList();
        return urls;
      } else {
        throw Exception('Failed to load documents');
      }
    } catch (e) {
      throw Exception('Failed to load documents: $e');
    }
  }

  Future<List<String>> fetchDocumentFileNames() async {
    try {
      final response = await _dio.get('$baseUrl/documents');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        List<FileInfo> fileInfoList = parseFileInfoList(data);

        List<String> filenames = fileInfoList.map((fileInfo) => fileInfo.document.filename).toList();
        return filenames;
      } else {
        throw Exception('Failed to load documents');
      }
    } catch (e) {
      throw Exception('Failed to load documents: $e');
    }
  }
}
