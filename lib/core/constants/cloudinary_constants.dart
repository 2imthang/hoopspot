/// Cloudinary account config — unsigned upload preset lets the app upload
/// images directly without a server-side secret key (avoids needing the
/// Firebase Storage/Blaze paid plan just for image hosting).
class CloudinaryConstants {
  const CloudinaryConstants._();

  static const String cloudName = 'nmt9h370';
  static const String uploadPreset = 'hoopspot_unsigned';

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}
