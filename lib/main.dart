import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'screens/starter_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await dotenv.load(fileName: '.env');

  // Satu-satunya init yang di-await sebelum UI tampil -> start cepat.
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
  );
  await AuthService.instance.init();

  runApp(const LabakuApp());
}

class LabakuApp extends StatelessWidget {
  const LabakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Labaku',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoadingScreen(),
    );
  }
}
