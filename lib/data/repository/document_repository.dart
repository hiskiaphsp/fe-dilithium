import 'dart:io';
import 'package:dio/dio.dart';
import 'package:fe/data/models/document.dart';

class DocumentRepository {
  final Dio _dio;
  final String baseUrl;

  DocumentRepository({Dio? dio, this.baseUrl = 'http://127.0.0.1:8080/api/v1'})
      : _dio = dio ?? Dio();

  Future<List<FileInfo>> fetchDocuments() async {
    try {
      final response = await _dio.get('$baseUrl/documents');

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
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
      String fileName = file.path.split('/').last;

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

  Future<void> deleteDocument(int documentId) async {
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
        List<dynamic> data = response.data['data'];
        List<FileInfo> fileInfoList = parseFileInfoList(data);

        return fileInfoList.map((fileInfo) => fileInfo.url).toList();
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
        List<dynamic> data = response.data['data'];
        List<FileInfo> fileInfoList = parseFileInfoList(data);

        return fileInfoList.map((fileInfo) => fileInfo.document.filename).toList();
      } else {
        throw Exception('Failed to load documents');
      }
    } catch (e) {
      throw Exception('Failed to load documents: $e');
    }
  }

  Future<Map<String, dynamic>> analyze(File file, String mode) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'message': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'mode': mode,
      });

      final response = await _dio.post('$baseUrl/analyze', data: formData);

      if (response.statusCode != 200) {
        throw Exception('Failed to analyze document');
      }

      return response.data;
    } catch (e) {
      throw Exception('Failed to analyze document: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeUrl(String file, String mode) async {
    try {
      FormData formData = FormData.fromMap({
        'messageURL': file,
        'mode': mode,
      });

      final response = await _dio.post('$baseUrl/analyze-url', data: formData);

      if (response.statusCode != 200) {
        throw Exception('Failed to analyze document');
      }

      return response.data;
    } catch (e) {
      throw Exception('Failed to analyze document: $e');
    }
  }
}
