import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class UploadService {
  final String baseUrl = "http://13.49.224.36:5000/api/v1";

  /// Returns MIME type based on file extension
  String _getMimeType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    const mimeTypes = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.mp4': 'video/mp4',
      '.mov': 'video/quicktime',
      '.avi': 'video/x-msvideo',
      '.webm': 'video/webm',
      '.mpeg': 'video/mpeg',
      '.mpg': 'video/mpeg',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
  }

  /// Upload file using presigned URL approach
  /// Returns the final uploaded file URL
  Future<String> uploadFile({
    required String token,
    required File file,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final mimeType = _getMimeType(fileName);  // 👈 detect MIME type
      debugPrint("✅ Uploading file: $fileName (type: $mimeType)");

      final fileBytes = await file.readAsBytes();

      final url = Uri.parse("$baseUrl/upload/image");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": mimeType,  // 👈 send correct MIME type
          "x-file-name": fileName,
        },
        body: fileBytes,
      );

      debugPrint("✅ Presign Upload Status: ${response.statusCode}");
      debugPrint("✅ Presign Upload Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);

        String? uploadedUrl;

        if (result['success'] == true) {
          uploadedUrl = result['data']?['view_url'] ??
              result['data']?['fileUrl'] ??
              result['data']?['uploadUrl'] ??
              result['data']['url'] ??
              result['fileUrl'];
        }

        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          debugPrint("✅ File uploaded successfully: $uploadedUrl");
          return uploadedUrl;
        } else {
          throw Exception("Upload URL not found in response");
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Failed to upload file");
      }
    } catch (e) {
      debugPrint("❌ Upload File Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Failed to upload file. Please try again.");
    }
  }
}
