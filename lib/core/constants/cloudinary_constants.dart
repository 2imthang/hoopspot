/// Cloudinary account config — unsigned upload preset lets the app upload
/// images directly without a server-side secret key (see CLAUDE.md: no
/// Firebase Storage/Blaze plan needed for image hosting).
class CloudinaryConstants {
  const CloudinaryConstants._();

  static const String cloudName = 'nmt9h370';
  static const String uploadPreset = 'hoopspot_unsigned';

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}
