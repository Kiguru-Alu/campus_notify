/// Stands in for Firebase Storage, which now requires the Blaze plan.
/// Same contract: send bytes, get back a durable HTTPS URL.
///
/// The unsigned preset is the only credential in the app and carries no read
/// or delete permission, so exposure in the binary grants write-only access
/// to one folder.
class CloudinaryConfig {
  const CloudinaryConfig._();

  /// From your Cloudinary dashboard, e.g. 'dxyz123ab'.
  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'mahuicloudinary',
  );

  /// Settings -> Upload -> Upload presets -> add an *unsigned* preset.
  static const String uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'campus_notify_unsigned',
  );

  static const String folder = 'campus_notify/incidents';

  static Uri get uploadEndpoint => Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

  static bool get isConfigured =>
      cloudName != 'REPLACE_WITH_YOUR_CLOUD_NAME' && cloudName.isNotEmpty;
}
