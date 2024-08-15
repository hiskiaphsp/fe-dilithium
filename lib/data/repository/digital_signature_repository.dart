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
        // Parsing response data
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseBody);

        // Extracting server execution time
        int serverExecutionTime = jsonResponse['data']['execution_time'];
        int signTime = jsonResponse['data']['sign_time'];
        int communicationSize = jsonResponse['data']['communication_size_bytes'];
        int memoryUsage = jsonResponse['data']['memory_usage_bytes'];
        String variant = jsonResponse['data']['variant'];



        return {
          "frontEndExecutionTime": executionTime.inMicroseconds, // Frontend execution time
          "serverExecutionTime": serverExecutionTime, // Server execution time
          "signTime": signTime, // Signature time
          "communicationSize": communicationSize,
          "memoryUsage": memoryUsage,
          "variant": variant
        };
      } else {
        // Handling errors
        print("Failed to sign file. Status code: ${response.statusCode}");
        throw Exception("Failed to sign detached");
      }
    } catch (error) {
      print("Error signing detached: $error");
      throw Exception("Failed to sign detached");
    }
  }

  Future<Map<String, dynamic>> signDetachedUrl(String messageUrl, String privateKeyPath) async {
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
        // Parsing response data
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseBody);

        // Extracting server execution time
        int serverExecutionTime = jsonResponse['data']['execution_time'];
        int signTime = jsonResponse['data']['sign_time'];
        int communicationSize = jsonResponse['data']['communication_size_bytes'];
        int memoryUsage = jsonResponse['data']['memory_usage_bytes'];
        String variant = jsonResponse['data']['variant'];

        return {
          "frontEndExecutionTime": executionTime.inMicroseconds, // Frontend execution time
          "serverExecutionTime": serverExecutionTime, // Server execution time
          "signTime": signTime, // Signature time
          "communicationSize": communicationSize,
          "memoryUsage": memoryUsage,
          "variant": variant,

        };
      } else {
        // Handling errors
        print("Failed to sign file. Status code: ${response.statusCode}");
        throw Exception("Failed to sign detached");
      }
    } catch (error) {
      print("Error signing detached: $error");
      throw Exception("Failed to sign detached");
    }
  }

  Future<Map<String, dynamic>> verifyDetached(String pdfFilePath, String publicKeyPath) async {
    try {
      final frontendStopwatch = Stopwatch()..start();

      Uri apiUrl = Uri.parse("$baseUrl/verify-signature");
      var request = http.MultipartRequest('POST', apiUrl)
        ..files.add(await http.MultipartFile.fromPath('message', pdfFilePath))
        ..files.add(await http.MultipartFile.fromPath('publicKey', publicKeyPath));

      var response = await request.send();

      frontendStopwatch.stop();
      int frontendExecutionTime = frontendStopwatch.elapsedMicroseconds;

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(await response.stream.bytesToString())['data'];
        bool verified = data['valid'];
        int serverExecutionTime = data['execution_time'];
        int verificationTime = data['verification_time'];
        int communicationSize = data['communication_size_bytes'];
        int memoryUsage = data['memory_usage_bytes'];
        String variant = data['variant'];

        return {
          'verified': verified,
          'frontendExecutionTime': frontendExecutionTime,
          'serverExecutionTime': serverExecutionTime,
          'verificationTime': verificationTime,
          "communicationSize": communicationSize,
          "memoryUsage": memoryUsage,
          "variant": variant,
        };
      } else {
        Map<String, dynamic> errorResponse = jsonDecode(await response.stream.bytesToString());
        String message = errorResponse['message'] ?? 'Failed Data';

        return {
          'verified': false,
          'message': message,
          'status': response.statusCode,
        };
      }
    } catch (error) {
      throw Exception("Failed to verify signature: $error");
    }
  }

  Future<Map<String, dynamic>> verifyDetachedUrl(String messageUrl, String publicKeyPath) async {
    try {
      final frontendStopwatch = Stopwatch()..start();

      Uri apiUrl = Uri.parse("$baseUrl/verify-signature-url");
      var request = http.MultipartRequest('POST', apiUrl)
        ..fields['messageURL'] = messageUrl
        ..files.add(await http.MultipartFile.fromPath('publicKey', publicKeyPath));

      var response = await request.send();

      frontendStopwatch.stop();
      int frontendExecutionTime = frontendStopwatch.elapsedMicroseconds;

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(await response.stream.bytesToString())['data'];
        bool verified = data['valid'];
        int serverExecutionTime = data['execution_time'];
        int verificationTime = data['verification_time'];
        int communicationSize = data['communication_size_bytes'];
        int memoryUsage = data['memory_usage_bytes'];
        String variant = data['variant'];

        return {
          'verified': verified,
          'frontendExecutionTime': frontendExecutionTime,
          'serverExecutionTime': serverExecutionTime,
          'verificationTime': verificationTime,
          "communicationSize": communicationSize,
          "memoryUsage": memoryUsage,
          "variant": variant,
        };
      } else {
        Map<String, dynamic> errorResponse = jsonDecode(await response.stream.bytesToString());
        String message = errorResponse['message'] ?? 'Failed Data';

        return {
          'verified': false,
          'message': message,
          'status': response.statusCode,
        };
      }
    } catch (error) {
      throw Exception("Failed to verify signature: $error");
    }
  }


}
