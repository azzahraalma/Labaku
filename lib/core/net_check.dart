import 'net_check_io.dart' if (dart.library.js_interop) 'net_check_web.dart'
    as impl;

/// Cek apakah perangkat sedang terhubung ke internet (Wi-Fi / data seluler).
Future<bool> hasInternetConnection() => impl.hasInternetConnection();
