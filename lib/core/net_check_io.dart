import 'dart:io';

Future<bool> hasInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('supabase.co')
        .timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
