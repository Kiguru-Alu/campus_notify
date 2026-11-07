import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/config/cloudinary_config.dart';

class ImageUploadFailure implements Exception {
  const ImageUploadFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Uploads a photo and returns an HTTPS URL for the incident document.
/// The contract matches what a Firebase Storage implementation would expose,
/// so swapping back is a one-file change.
///
/// Takes raw bytes rather than a File so the same code path runs on web,
/// Android and iOS without a dart:io dependency.
class ImageRepository {
  ImageRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> uploadIncidentPhoto({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw const ImageUploadFailure(
        'Photo uploads are not configured on this build.',
      );
    }

    print('Cloudinary endpoint: ${CloudinaryConfig.uploadEndpoint}');
    print('Cloudinary preset: ${CloudinaryConfig.uploadPreset}');

    final request = http.MultipartRequest(
      'POST',
      CloudinaryConfig.uploadEndpoint,
    )
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = CloudinaryConfig.folder
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: filename));

    try {
      final streamed =
          await _client.send(request).timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Cloudinary returns the reason in the body; without it a 400 is
        // indistinguishable from a wrong preset, a wrong cloud name or a
        // rejected file type.
        String reason = 'status ${response.statusCode}';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final detail = (body['error'] as Map<String, dynamic>?)?['message'];
          if (detail != null) reason = detail.toString();
        } catch (_) {}
        throw ImageUploadFailure(
          'Photo upload failed: $reason. The report was not sent.',
        );
      } 

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final url = body['secure_url'] as String?;
      if (url == null || url.isEmpty) {
        throw const ImageUploadFailure('Photo upload returned no URL.');
      }
      return url;
    } on http.ClientException {
      throw const ImageUploadFailure(
        'No connection. Your photo could not be uploaded.',
      );
    }
  }

  void dispose() => _client.close();
}
