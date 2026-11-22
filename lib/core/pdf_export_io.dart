import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String> exportPdfFile(String fileName, Uint8List pdfBytes) async {
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
  try {
    await file.writeAsBytes(pdfBytes, flush: true);
    await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')],
        subject: fileName);
    return file.path;
  } catch (_) {
    final tmp = await getTemporaryDirectory();
    final fallback = File('${tmp.path}/$fileName');
    await fallback.writeAsBytes(pdfBytes, flush: true);
    await Share.shareXFiles([XFile(fallback.path, mimeType: 'application/pdf')],
        subject: fileName);
    return fallback.path;
  }
}
