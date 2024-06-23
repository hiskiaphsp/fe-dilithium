import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class DigitalSignatureRepository {
  // final String baseUrl = "http://127.0.0.1:3000";
  final String baseUrl = "http://127.0.0.1:8080";

  final Dio _dio = Dio();

  Future<String> _getDownloadDirectoryPath() async {
    try {
      // Get the document directory
      Directory appDocDir = await getApplicationDocumentsDirectory();

      // For iOS, use the Documents directory
      if (Platform.isIOS) {
        return '${appDocDir.path}/'; // This goes up one level to "On My iPhone"
      }

      // For Android and other platforms, use the application documents directory
      return appDocDir.path;
    } catch (e) {
      print('Error getting download directory path: $e');
      throw Exception('Error getting download directory path');
    }
  }

  Future<void> downloadKeyPair(String mode) async {
    try {
      String downloadPath = await _getDownloadDirectoryPath();
      String savePath = '$downloadPath/keypair.zip';

      // Check if file already exists
      File file = File(savePath);
      if (await file.exists()) {
        // If file already exists, find a unique name
        int count = 1;
        String newSavePath;
        do {
          newSavePath = '$downloadPath/$mode-keypair-$count.zip';
          file = File(newSavePath);
          count++;
        } while (await file.exists());
        savePath = newSavePath;
      }

      // Send the POST request with the mode in the request body
      Response response = await _dio.download(
        "$baseUrl/generate-keypair",
        savePath,
        options: Options(method: 'POST'),
        data: {
          "mode": mode,
        },
        onReceiveProgress: (received, total) {
          // Update progress indicator (optional)
          if (total != -1) {
            print('Download Progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      print("Key pair downloaded successfully to: $savePath");
    } catch (error) {
      print("Error downloading key pair: $error");
      throw Exception("Failed to download key pair");
    }
  }

  Future<void> signDetached(String pdfFilePath, String privateKeyPath, String mode) async {
    try {
      // Preparing the API endpoint URL
      Uri apiUrl = Uri.parse("$baseUrl/sign-message");

      // Creating multipart request
      var request = http.MultipartRequest('POST', apiUrl);

      // Adding PDF file to the request
      File pdfFile = File(pdfFilePath);
      if (!pdfFile.existsSync()) {
        throw Exception("PDF file does not exist");
      }
      request.files.add(await http.MultipartFile.fromPath('message', pdfFilePath));

      // Adding private key file to the request
      File privateKeyFile = File(privateKeyPath);
      if (!privateKeyFile.existsSync()) {
        throw Exception("Private key file does not exist");
      }
      request.files.add(await http.MultipartFile.fromPath('privateKey', privateKeyPath));

      // Adding mode to the request
      request.fields['mode'] = mode;

      // Sending the request
      var response = await request.send();

      // Checking the response
      if (response.statusCode == 200) {
        // Saving the response as signature file
        String downloadPath = await _getDownloadDirectoryPath();
        String savePath = '$downloadPath/signature.sig';

        // Check if file already exists
        File file = File(savePath);
        if (await file.exists()) {
          // If file already exists, find a unique name
          int count = 1;
          String newSavePath;
          do {
            newSavePath = '$downloadPath/signature-$count.sig';
            file = File(newSavePath);
            count++;
          } while (await file.exists());
          savePath = newSavePath;
        }

        var bytes = await response.stream.toBytes();
        await File(savePath).writeAsBytes(bytes, flush: true);
        print("Signature file downloaded successfully: $savePath");
      } else {
        // Handling errors
        print("Failed to download signature file. Status code: ${response.statusCode}");
        throw Exception("Failed to sign detached");
      }
    } catch (error) {
      print("Error signing detached: $error");
      throw Exception("Failed to sign detached");
    }
  }

  Future<Map> verifyDetached(String pdfFilePath, String signaturePath, String publicKeyPath, String mode) async {
    try {
      // Printing file paths for debugging
      print(pdfFilePath);
      print(signaturePath);
      print(publicKeyPath);

      // Ensuring file paths are not null
      if (pdfFilePath.isEmpty || signaturePath.isEmpty || publicKeyPath.isEmpty) {
        throw Exception("File paths cannot be null or empty");
      }

      // Ensuring files exist
      if (!File(pdfFilePath).existsSync() || !File(signaturePath).existsSync() || !File(publicKeyPath).existsSync()) {
        throw Exception("One or more files do not exist");
      }

      // Sending verification request to the server
      Uri apiUrl = Uri.parse("$baseUrl/verify-signature");
      var request = http.MultipartRequest('POST', apiUrl)
        ..files.add(await http.MultipartFile.fromPath('message', pdfFilePath))
        ..files.add(await http.MultipartFile.fromPath('signature', signaturePath))
        ..files.add(await http.MultipartFile.fromPath('publicKey', publicKeyPath))
        ..fields['mode'] = mode;  // Adding mode to the request

      var response = await request.send();

      // Checking the response
      if (response.statusCode == 200) {
        // Parsing JSON response
        Map<String, dynamic> data = jsonDecode(await response.stream.bytesToString());
        bool verified = data['valid'];
        // String executionTime = data['executionTime'];
        // Map<String, String> fileSizes = Map<String, String>.from(data['fileSizes']);

        print(verified);
        return {
          'verified': verified,
          // 'executionTime': executionTime,
          // 'fileSizes': fileSizes
        };
      } else {
        // Handling errors
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
