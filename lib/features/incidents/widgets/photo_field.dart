
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/selected_photo.dart';

class PhotoField extends StatelessWidget {
  const PhotoField({super.key, required this.photo, required this.onChanged});

  final SelectedPhoto? photo;
  final ValueChanged<SelectedPhoto?> onChanged;

  Future<void> _pick(ImageSource source) async {
    // Downscaled before upload: a 12 MP phone photo is a slow upload on
    // campus wifi and adds nothing to a picture of a broken tap.
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    onChanged(SelectedPhoto(bytes: bytes, filename: picked.name));
  }

  Future<void> _choose(BuildContext context) async {
    // The browser has no camera/gallery distinction, so it goes straight to
    // the file picker.
    if (kIsWeb) {
      await _pick(ImageSource.gallery);
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('Take a photo', style: AppType.body()),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Choose from gallery', style: AppType.body()),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pick(source);
  }

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
            child: Image.memory(
              photo!.bytes,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onChanged(null),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child:
                      Icon(Icons.close_rounded, size: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => _choose(context),
      borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
      child: Container(
        height: 96,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(AppSpacing.radiusControl),
          border: Border.all(color: AppColors.lineStrong),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined,
                color: AppColors.navy, size: 22),
            const SizedBox(height: 6),
            Text('Add a photo', style: AppType.smallStrong()),
            Text('Optional, but it speeds up repairs', style: AppType.caption()),
          ],
        ),
      ),
    );
  }
}
