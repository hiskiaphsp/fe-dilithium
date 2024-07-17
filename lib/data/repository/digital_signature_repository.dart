import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class DigitalSignatureRepository {
  // final String baseUrl = "http://127.0.0.1:3000";
  final String baseUrl = "http://127.0.0.1:8080/api/v1";

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

  Future<Map<String, dynamic>> downloadKeyPair(String mode) async {
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

      // Record start time
      DateTime startTime = DateTime.now();

      // Send the POST request with the mode in the request body
      Response response = await _dio.download(
        "$baseUrl/generate-keypair-mode",
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

      // Record end time
      DateTime endTime = DateTime.now();

      // Calculate execution time
      Duration executionTime = endTime.difference(startTime);

      print("Key pair downloaded successfully to: $savePath");
      
      return {
        "savePath": savePath,
        "executionTime": executionTime.inMicroseconds, // Return the execution time in milliseconds
      };
    } catch (error) {
      print("Error downloading key pair: $error");
      throw Exception("Failed to download key pair");
    }
  }

  Future<Map<String, dynamic>> signDetached(String pdfFilePath, String privateKeyPath) async {
    try {
      // Preparing the API endpoint URL
      String apiUrl = "$baseUrl/sign-message-mode";

      // Checking if PDF file exists
      File pdfFile = File(pdfFilePath);
      if (!pdfFile.existsSync()) {
        throw Exception("PDF file does not exist");
      }

      // Checking if private key file exists
      File privateKeyFile = File(privateKeyPath);
      if (!privateKeyFile.existsSync()) {
        throw Exception("Private key file does not exist");
      }

      // Extracting file name from PDF path
      // String pdfFileName = pdfFile.path.split('/').last;

      // Creating multipart form data
      FormData formData = FormData.fromMap({
        'message': await MultipartFile.fromFile(pdfFilePath),
        'privateKey': await MultipartFile.fromFile(privateKeyPath),
      });

      // Record start time
      DateTime startTime = DateTime.now();

      // Sending the request
      Response response = await _dio.post(apiUrl, data: formData);

      // Record end time
      DateTime endTime = DateTime.now();

      // Calculate execution time
      Duration executionTime = endTime.difference(startTime);
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

        // Writing the response data to file
        await file.writeAsBytes(response.data, flush: true);
        print("Signature file downloaded successfully: $savePath");

        return {
          "savePath": savePath,
          "executionTime": executionTime.inMicroseconds, // Return the execution time in microseconds
        };
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

  Future<Map<String, dynamic>> signDetachedUrl(String messageUrl, String privateKeyPath, String mode) async {
    try {
      // Preparing the API endpoint URL
      Uri apiUrl = Uri.parse("$baseUrl/sign-message-url");

      // Creating multipart request
      var request = http.MultipartRequest('POST', apiUrl);

      // Adding private key file to the request
      File privateKeyFile = File(privateKeyPath);
      if (!privateKeyFile.existsSync()) {
        throw Exception("Private key file does not exist");
      }
      request.files.add(await http.MultipartFile.fromPath('privateKey', privateKeyPath));

      // Adding mode to the request
      request.fields['mode'] = mode;

      // Adding messageUrl to the request
      request.fields['messageURL'] = messageUrl;

      // Record start time
      DateTime startTime = DateTime.now();

      // Sending the request
      var response = await request.send();

      // Record end time
      DateTime endTime = DateTime.now();

      // Calculate execution time
      Duration executionTime = endTime.difference(startTime);

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

        return {
          "savePath": savePath,
          "executionTime": executionTime.inMicroseconds, // Return the execution time in milliseconds
        };
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

  Future<Map<String, dynamic>> verifyDetached(String pdfFilePath, String signaturePath, String publicKeyPath, String mode) async {
    try {
      // Ensuring file paths are not null
      if (pdfFilePath.isEmpty || signaturePath.isEmpty || publicKeyPath.isEmpty) {
        throw Exception("File paths cannot be null or empty");
      }

      // Ensuring files exist
      if (!File(pdfFilePath).existsSync() || !File(signaturePath).existsSync() || !File(publicKeyPath).existsSync()) {
        throw Exception("One or more files do not exist");
      }

      // Start time measurement
      final stopwatch = Stopwatch()..start();

      // Sending verification request to the server
      Uri apiUrl = Uri.parse("$baseUrl/verify-signature");
      var request = http.MultipartRequest('POST', apiUrl)
        ..files.add(await http.MultipartFile.fromPath('message', pdfFilePath))
        ..files.add(await http.MultipartFile.fromPath('signature', signaturePath))
        ..files.add(await http.MultipartFile.fromPath('publicKey', publicKeyPath))
        ..fields['mode'] = mode;  // Adding mode to the request

      var response = await request.send();

      // Stop time measurement
      stopwatch.stop();
      int executionTime = stopwatch.elapsedMicroseconds;

      // Checking the response
      if (response.statusCode == 200) {
        // Parsing JSON response
        Map<String, dynamic> data = jsonDecode(await response.stream.bytesToString());
        bool verified = data['valid'];

        print(verified);
        return {
          'verified': verified,
          'executionTime': executionTime,
        };
      } else {
        // Handling errors
        print("Failed to verify signature. Status code: ${response.statusCode}");
        return {
          'verified': false,
          'executionTime': executionTime,
        };
      }
    } catch (error) {
      print("Error verifying signature: $error");
      throw Exception("Failed to verify signature: $error");
    }
  }

  Future<Map<String, dynamic>> verifyDetachedUrl(String messageUrl, String signaturePath, String publicKeyPath, String mode) async {
    try {
      // Start time measurement
      final stopwatch = Stopwatch()..start();

      // Sending verification request to the server
      Uri apiUrl = Uri.parse("$baseUrl/verify-signature-url");
      var request = http.MultipartRequest('POST', apiUrl)
        ..fields['messageURL'] = messageUrl
        ..files.add(await http.MultipartFile.fromPath('signature', signaturePath))
        ..files.add(await http.MultipartFile.fromPath('publicKey', publicKeyPath))
        ..fields['mode'] = mode;

      var response = await request.send();

      // Stop time measurement
      stopwatch.stop();
      int executionTime = stopwatch.elapsedMicroseconds;

      // Checking the response
      if (response.statusCode == 200) {
        // Parsing JSON response
        Map<String, dynamic> data = jsonDecode(await response.stream.bytesToString());
        bool verified = data['valid'];

        print(verified);
        return {
          'verified': verified,
          'executionTime': executionTime,
        };
      } else {
        // Handling errors
        print("Failed to verify signature. Status code: ${response.statusCode}");
        return {
          'verified': false,
          'executionTime': executionTime,
        };
      }
    } catch (error) {
      print("Error verifying signature: $error");
      throw Exception("Failed to verify signature: $error");
    }
  }

}
