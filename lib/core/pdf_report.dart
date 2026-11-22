import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../services/data_service.dart';
import 'app_config.dart';
import 'format.dart';
import 'pdf_export.dart';

const _blue = PdfColor.fromInt(0xFF2255A4);
const _blueLight = PdfColor.fromInt(0xFFEAF0FD);
const _yellow = PdfColor.fromInt(0xFFF8C423);
const _dark = PdfColor.fromInt(0xFF1F242D);
const _muted = PdfColor.fromInt(0xFF6B7280);
const _border = PdfColor.fromInt(0xFFD6DCE5);
const _rowAlt = PdfColor.fromInt(0xFFF8FAFE);
const _green = PdfColor.fromInt(0xFF15803D);
const _red = PdfColor.fromInt(0xFFB91C1C);

String _fmtDateTime(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${m[d.month - 1]} ${d.year}, $hh:$mm';
}

Future<pw.MemoryImage?> _loadAssetImage(String path) async {
  try {
    final data = await rootBundle.load(path);
    return pw.MemoryImage(data.buffer.asUint8List());
  } catch (_) {
    return null;
  }
}

Future<pw.MemoryImage?> _loadNetworkImage(String? url) async {
  if (url == null || url.trim().isEmpty) return null;
  try {
    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 5));
    if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
      return pw.MemoryImage(res.bodyBytes);
    }
  } catch (_) {}
  return null;
}

/// Membuat dan mengunduh Laporan Keuangan Profesional dalam format PDF.
Future<String> exportReportPdf({
  required ReportData report,
  required String rangeKey,
  required String rangeLabel,
  HomeData? home,
}) async {
  final fontReg =
      pw.Font.ttf(await rootBundle.load('lib/assets/fonts/Poppins-Regular.ttf'));
  final fontBold =
      pw.Font.ttf(await rootBundle.load('lib/assets/fonts/Poppins-Bold.ttf'));

  final labakuLogo = await _loadAssetImage(AppImages.logo);
  final bizLogo = await _loadNetworkImage(home?.businessLogo);

  final sorted = [...report.items]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final totalQty = sorted.fold<double>(0, (s, e) => s + e.kuantitas);
  final totalHpp =
      sorted.fold<double>(0, (s, e) => s + (e.hppPerUnit * e.kuantitas));
  final totalDiskon =
      sorted.fold<double>(0, (s, e) => s + (e.diskonPerUnit * e.kuantitas));
  final now = DateTime.now();

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: fontReg, bold: fontBold),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(26, 24, 26, 28),
      header: (ctx) => pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: pw.BoxDecoration(
              color: _blue,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Logo Usaha (jika ada)
                if (bizLogo != null) ...[
                  pw.Container(
                    width: 46,
                    height: 46,
                    padding: const pw.EdgeInsets.all(2),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(bizLogo, fit: pw.BoxFit.cover),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        home?.businessName ?? 'Usaha Labaku',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${home?.businessCategory ?? '-'}  •  Periode: $rangeLabel  •  Dicetak: ${_fmtDateTime(now)} WIB',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColor.fromInt(0xFFDCE7FA),
                        ),
                      ),
                      if ((home?.businessDescription ?? '').isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          home!.businessDescription,
                          maxLines: 1,
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColor.fromInt(0xFFBFD4F8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (labakuLogo != null)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Image(labakuLogo, height: 18),
                      ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: _yellow,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'LAPORAN PENJUALAN & LABA RUGI',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
        ],
      ),
      footer: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _border, width: 0.7)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dicetak otomatis oleh Aplikasi Labaku  •  Pemilik: ${home?.username ?? '-'}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
            pw.Text(
              'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      ),
      build: (ctx) => [
        // Kartu Ringkasan KPI
        pw.Row(
          children: [
            _kpiBox(
              'Total Transaksi',
              '${report.txCount} transaksi',
              '${Fmt.plain(totalQty)} item terjual',
              accent: _blue,
            ),
            pw.SizedBox(width: 8),
            _kpiBox(
              'Total Pendapatan',
              Fmt.rp(report.pendapatan),
              totalDiskon > 0
                  ? 'Total diskon: ${Fmt.rp(totalDiskon)}'
                  : 'Tanpa potongan diskon',
              accent: _blue,
            ),
            pw.SizedBox(width: 8),
            _kpiBox(
              'Total Modal (HPP)',
              Fmt.rp(totalHpp),
              'HPP aktual barang terjual',
              accent: _muted,
            ),
            pw.SizedBox(width: 8),
            _kpiBox(
              'Keuntungan Bersih',
              Fmt.rp(report.keuntungan),
              'Rata-rata margin: ${Fmt.plain(report.avgMargin)}%',
              accent: report.keuntungan >= 0 ? _green : _red,
              highlight: true,
            ),
          ],
        ),
        pw.SizedBox(height: 14),

        pw.Text(
          'Rincian Transaksi (${sorted.length} item)',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _blue,
          ),
        ),
        pw.SizedBox(height: 6),

        // Tabel Rincian Transaksi
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.5),
          columnWidths: const {
            0: pw.FixedColumnWidth(24), // No
            1: pw.FixedColumnWidth(84), // Tanggal
            2: pw.FlexColumnWidth(2.1), // Produk
            3: pw.FixedColumnWidth(34), // Qty
            4: pw.FlexColumnWidth(1.2), // Harga Normal
            5: pw.FlexColumnWidth(1.1), // Diskon
            6: pw.FlexColumnWidth(1.2), // Harga Jual
            7: pw.FlexColumnWidth(1.2), // HPP/Unit
            8: pw.FlexColumnWidth(1.3), // Subtotal
            9: pw.FlexColumnWidth(1.3), // Laba
            10: pw.FlexColumnWidth(1.0), // Kasir
          },
          children: [
            // Header tabel
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _blue),
              children: [
                _th('No', align: pw.TextAlign.center),
                _th('Tanggal'),
                _th('Produk / Kategori'),
                _th('Qty', align: pw.TextAlign.right),
                _th('Harga Normal', align: pw.TextAlign.right),
                _th('Diskon/Unit', align: pw.TextAlign.right),
                _th('Harga Jual', align: pw.TextAlign.right),
                _th('HPP/Unit', align: pw.TextAlign.right),
                _th('Pendapatan', align: pw.TextAlign.right),
                _th('Laba Bersih', align: pw.TextAlign.right),
                _th('Kasir'),
              ],
            ),
            // Baris data
            for (var i = 0; i < sorted.length; i++)
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: i.isOdd ? _rowAlt : PdfColors.white,
                ),
                children: [
                  _td('${i + 1}', align: pw.TextAlign.center),
                  _td(_fmtDateTime(sorted[i].createdAt)),
                  _td('${sorted[i].productName}\n(${sorted[i].kategori})',
                      bold: true),
                  _td(Fmt.plain(sorted[i].kuantitas), align: pw.TextAlign.right),
                  _td(
                    sorted[i].hargaNormal > 0
                        ? Fmt.rp(sorted[i].hargaNormal)
                        : Fmt.rp(sorted[i].hargaSatuan),
                    align: pw.TextAlign.right,
                  ),
                  _td(
                    sorted[i].diskonPerUnit > 0
                        ? '-${Fmt.rp(sorted[i].diskonPerUnit)}'
                        : '-',
                    align: pw.TextAlign.right,
                    color: sorted[i].diskonPerUnit > 0 ? _red : _muted,
                  ),
                  _td(Fmt.rp(sorted[i].hargaSatuan), align: pw.TextAlign.right),
                  _td(Fmt.rp(sorted[i].hppPerUnit), align: pw.TextAlign.right),
                  _td(Fmt.rp(sorted[i].total),
                      align: pw.TextAlign.right, bold: true),
                  _td(
                    Fmt.rp(sorted[i].laba),
                    align: pw.TextAlign.right,
                    bold: true,
                    color: sorted[i].laba >= 0 ? _green : _red,
                  ),
                  _td(sorted[i].kasir),
                ],
              ),
            // Baris Grand Total
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _blueLight),
              children: [
                _td('', bold: true),
                _td('TOTAL', bold: true, color: _blue),
                _td('${report.txCount} Transaksi', bold: true, color: _blue),
                _td(Fmt.plain(totalQty),
                    align: pw.TextAlign.right, bold: true, color: _blue),
                _td('', align: pw.TextAlign.right),
                _td(
                  totalDiskon > 0 ? '-${Fmt.rp(totalDiskon)}' : '-',
                  align: pw.TextAlign.right,
                  bold: true,
                  color: totalDiskon > 0 ? _red : _muted,
                ),
                _td('', align: pw.TextAlign.right),
                _td(Fmt.rp(totalHpp),
                    align: pw.TextAlign.right, bold: true, color: _dark),
                _td(Fmt.rp(report.pendapatan),
                    align: pw.TextAlign.right, bold: true, color: _blue),
                _td(
                  Fmt.rp(report.keuntungan),
                  align: pw.TextAlign.right,
                  bold: true,
                  color: report.keuntungan >= 0 ? _green : _red,
                ),
                _td(''),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  final stamp =
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  final fileName = 'Laporan_Labaku_${rangeKey}_$stamp.pdf';
  final bytes = await doc.save();
  return exportPdfFile(fileName, bytes);
}

pw.Widget _kpiBox(
  String label,
  String value,
  String sub, {
  required PdfColor accent,
  bool highlight = false,
}) {
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: highlight ? _blueLight : PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
            color: highlight ? _blue : _border, width: highlight ? 1.1 : 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _muted)),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(sub, style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
        ],
      ),
    ),
  );
}

pw.Widget _th(String text, {pw.TextAlign align = pw.TextAlign.left}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );

pw.Widget _td(
  String text, {
  pw.TextAlign align = pw.TextAlign.left,
  bool bold = false,
  PdfColor color = _dark,
}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
