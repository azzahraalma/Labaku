import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String> exportCsvFile(String fileName, String csvContent) async {
  Directory? dir;
  if (Platform.isAndroid) {
    final dl = Directory('/storage/emulated/0/Download');
    if (await dl.exists()) {
      dir = dl;
    } else {
      dir = await getExternalStorageDirectory();
    }
  }
  dir ??= await getApplicationDocumentsDirectory();

  final file = File('${dir.path}/$fileName');
  final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)];
  try {
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')],
        subject: fileName);
    return file.path;
  } catch (_) {
    final tmp = await getTemporaryDirectory();
    final fallback = File('${tmp.path}/$fileName');
    await fallback.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(fallback.path, mimeType: 'text/csv')],
        subject: fileName);
    return fallback.path;
  }
}
