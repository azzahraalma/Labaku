import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_KEY'] ?? '';

  static const pinLength = 6;
  static const minPasswordLength = 6;
}

class AppImages {
  static const _b = 'lib/assets/images';
  static const logo = '$_b/logo.png';
  static const mascot = '$_b/mascot.png';
}
