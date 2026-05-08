class CloudinaryConfig {
  static const String cloudName = 'drposqmf0';      // Real value from registration_screen.dart
  static const String uploadPreset = 'flutter_uploads'; // Real value from registration_screen.dart
  
  static String get uploadUrl => 
    'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}
