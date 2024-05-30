import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class DigitalSignatureRepository {
  final String baseUrl = "http://192.168.100.62:3000";
  final Dio _dio = Dio();

  Future<String> _getDownloadDirectoryPath() async {
    try {
      if (Platform.isAndroid) {
        Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          String downloadPath = '${externalDir.path}';
          return downloadPath;
        }
      }
    } catch (e) {
      print('Error getting download directory path: $e');
    }
    Directory appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir.path;
  }

  Future<void> downloadKeyPair() async {
    try {
      Response response = await _dio.get("$baseUrl/keypair",
          options: Options(responseType: ResponseType.bytes));

      String downloadPath = await _getDownloadDirectoryPath();
      String savePath = '$downloadPath/file.zip';
      print(savePath);
      File file = File(savePath);
      await file.writeAsBytes(response.data, flush: true);
    } catch (error) {
      print("Error downloading key pair: $error");
      throw Exception("Failed to download key pair");
    }
  }

  Future<void> signDetached(String pdfFilePath, String privateKeyPath) async {
    try {
      // Menyiapkan URL endpoint API Anda
      Uri apiUrl = Uri.parse("$baseUrl/sign-detached");

      // Membuat request multipart
      var request = http.MultipartRequest('POST', apiUrl);

      // Menambahkan file PDF ke dalam request
      request.files.add(await http.MultipartFile.fromPath('pdfFile', pdfFilePath));

      // Menambahkan file kunci pribadi ke dalam request
      request.files.add(await http.MultipartFile.fromPath('privateKeyFile', privateKeyPath));

      // Mengirim request
      var response = await request.send();

      // Memeriksa respon
      if (response.statusCode == 200) {
        // Menyimpan respon sebagai file signature
        String downloadPath = await _getDownloadDirectoryPath();
        String savePath = '$downloadPath/signature.json';
        var file = File(savePath);
        await file.writeAsBytes(await response.stream.toBytes(), flush: true);
        print("Signature file downloaded successfully: $savePath");
      } else {
        // Menangani jika terjadi kesalahan
        print("Failed to download signature file. Status code: ${response.statusCode}");
        throw Exception("Failed to sign detached");
      }
    } catch (error) {
      print("Error signing detached: $error");
      throw Exception("Failed to sign detached");
    }
  }

  Future<Map> verifyDetached(String pdfFilePath, String signaturePath, String publicKeyPath) async {
    try {
      // Mencetak path file untuk debug
      print(pdfFilePath);
      print(signaturePath);
      print(publicKeyPath);

      // Memastikan file paths tidak null
      if (pdfFilePath == null || signaturePath == null || publicKeyPath == null) {
        throw Exception("File paths cannot be null");
      }

      // Memastikan file paths valid
      if (!File(pdfFilePath).existsSync() || !File(signaturePath).existsSync() || !File(publicKeyPath).existsSync()) {
        throw Exception("One or more files do not exist");
      }

      // Mengirimkan permintaan verifikasi ke server
      Uri apiUrl = Uri.parse("$baseUrl/verify-detached");
      var request = http.MultipartRequest('POST', apiUrl)
        ..files.add(await http.MultipartFile.fromPath('pdfFile', pdfFilePath))
        ..files.add(await http.MultipartFile.fromPath('signatureFile', signaturePath))
        ..files.add(await http.MultipartFile.fromPath('publicKeyFile', publicKeyPath));

      var response = await request.send();

      // Memeriksa respon
      if (response.statusCode == 200) {
        // Memecah JSON respon
        Map<String, dynamic> data = jsonDecode(await response.stream.bytesToString());
        bool verified = data['verified'];
        String executionTime = data['executionTime'];
        Map<String, String> fileSizes = Map<String, String>.from(data['fileSizes']);

        print(verified);
        return {
          'verified': verified,
          'executionTime': executionTime,
          'fileSizes': fileSizes
        };
      } else {
        // Menangani jika terjadi kesalahan
        print("Failed to verify signature. Status code: ${response.statusCode}");
        return {
          'verified': false
        };
      }
    } catch (error) {
      print("Error verifying signature: $error");
      throw Exception("Failed to verify signature: $error");
    }
  }
}

