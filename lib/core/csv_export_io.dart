import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Simpan file .csv ke penyimpanan HP (folder Downloads / Documents) lalu buka
/// lembar simpan/bagikan agar user bisa langsung membuka atau menyimpan file-nya.
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
  // Tambah UTF-8 BOM agar Excel langsung membaca karakter & kolom dengan benar.
  final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)];
  try {
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')],
        subject: fileName);
    return file.path;
  } catch (_) {
    // Fallback ke direktori sementara bila izin penyimpanan terbatas
    final tmp = await getTemporaryDirectory();
    final fallback = File('${tmp.path}/$fileName');
    await fallback.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(fallback.path, mimeType: 'text/csv')],
        subject: fileName);
    return fallback.path;
  }
}
