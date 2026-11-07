import 'dart:typed_data';

/// Carries the bytes rather than a file path, so the preview and the upload
/// work the same way on web, Android and iOS.
class SelectedPhoto {
  const SelectedPhoto({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}
