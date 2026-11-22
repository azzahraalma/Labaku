import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<String> exportPdfFile(String fileName, Uint8List pdfBytes) async {
  final blob = web.Blob(
    <JSAny>[pdfBytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return fileName;
}
