import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Kredensial dibaca dari file .env (SUPABASE_URL, SUPABASE_KEY).
class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_KEY'] ?? '';

  static const pinLength = 6;
  static const minPasswordLength = 6;
}

/// Path gambar yang dipakai aplikasi.
/// Hanya logo dan maskot (untuk starter screen & loading screen) yang memakai gambar.
/// Taruh file-nya di lib/assets/images/ dengan nama persis seperti di bawah.
class AppImages {
  static const _b = 'lib/assets/images';
  static const logo = '$_b/logo.png';
  static const mascot = '$_b/mascot.png';
}
