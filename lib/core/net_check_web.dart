import 'package:web/web.dart' as web;

Future<bool> hasInternetConnection() async {
  return web.window.navigator.onLine;
}
