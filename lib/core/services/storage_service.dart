import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StorageService {
  // Server upload endpoint
  static const String uploadUrl = 'https://deepcognix.com/rental/upload.php';
  static const String baseUrl = 'https://deepcognix.com/rental/';

  // Helper function to fix URLs with backslashes (common PHP mistake)
  String _fixUrl(String url) {
    // Replace backslashes with forward slashes
    String fixed = url.replaceAll('\\', '/');
    // Ensure proper double slash after protocol
    fixed = fixed.replaceAll(':/', '://');
    debugPrint('🔧 Fixed URL: $url → $fixed');
    return fixed;
  }

  Future<String> uploadImage(XFile image, String folder) async {
    try {
      // Create a multipart request
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add headers for better compatibility
      request.headers['Accept'] = 'application/json';

      // Add the file to the request
      if (kIsWeb) {
        // For web, use bytes
        final bytes = await image.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: '${DateTime.now().millisecondsSinceEpoch}_${image.name}',
          ),
        );
      } else {
        // For mobile/desktop, use file path
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            image.path,
            filename: '${DateTime.now().millisecondsSinceEpoch}_${image.name}',
          ),
        );
      }

      // Send the request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      // Get the response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse the response to get the file URL
        debugPrint('Upload response: ${response.body}');
        try {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['success'] == true && jsonResponse['url'] != null) {
            String url = jsonResponse['url'];
            url = _fixUrl(url); // Fix backslashes to forward slashes
            debugPrint('✅ Got URL from JSON: $url');
            return url;
          } else if (jsonResponse['filename'] != null) {
            // If server returns just the filename
            String url = '$baseUrl${jsonResponse['filename']}';
            url = _fixUrl(url);
            debugPrint('✅ Constructed URL from filename: $url');
            return url;
          }
        } catch (e) {
          // If response is plain text (filename), construct URL
          final filename = response.body.trim();

          // Check for invalid responses
          if (filename == 'success' ||
              filename == 'ok' ||
              filename == 'uploaded') {
            throw 'Server returned "$filename" but did not provide the image filename or URL. '
                'Server needs to return JSON like: {"success": true, "filename": "image.jpg"} '
                'or just the filename as text: "1234567890_image.jpg"';
          }

          if (filename.isNotEmpty &&
              !filename.startsWith('<') &&
              filename.contains('.')) {
            String url = '$baseUrl$filename';
            url = _fixUrl(url);
            debugPrint('✅ Constructed URL from plain text: $url');
            return url;
          }
        }

        // If we reach here, server response was invalid
        throw 'Server returned success but did not provide image URL or filename. '
            'Response was: "${response.body}". '
            'Server must return either:\n'
            '1. JSON: {"success": true, "filename": "image.jpg"}\n'
            '2. JSON: {"success": true, "url": "https://domain.com/path/image.jpg"}\n'
            '3. Plain text: "1234567890_image.jpg"';
      } else {
        throw 'Server returned status code: ${response.statusCode}';
      }
    } on http.ClientException catch (e) {
      debugPrint('ClientException: $e');
      if (kIsWeb) {
        throw 'CORS Error: Unable to upload from web. Please configure CORS headers on your server (upload.php). See documentation for details.';
      }
      throw 'Network Error: Failed to connect to server. Please check your internet connection.';
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw 'Image Upload Failed: $e';
    }
  }

  Future<List<String>> uploadImages(List<XFile> images, String folder) async {
    List<String> uploadedUrls = [];

    // Upload one by one to better track errors
    for (int i = 0; i < images.length; i++) {
      debugPrint('📤 Uploading image ${i + 1}/${images.length}...');
      try {
        final url = await uploadImage(images[i], folder);
        uploadedUrls.add(url);
        debugPrint('✅ Image ${i + 1} uploaded: $url');
      } catch (e) {
        debugPrint('❌ Failed to upload image ${i + 1}: $e');
        rethrow; // Stop on first error
      }
    }

    return uploadedUrls;
  }
}
