import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/csv_export.dart';
import '../core/format.dart';
import '../core/ui_kit.dart';
import '../core/widgets.dart';
import '../services/data_service.dart';
import 'wizard/wizard_dialogs.dart';

const _ranges = <(String, String)>[
  ('today', 'Hari ini'),
  ('week', 'Minggu ini'),
  ('month', 'Bulan ini'),
  ('year', 'Tahun ini'),
];

String _fmtTxDate(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${m[d.month - 1]} ${d.year}  •  $hh:$mm WIB';
}

/// Laporan 
class LaporanTab extends StatefulWidget {
  const LaporanTab({super.key});

  @override
  State<LaporanTab> createState() => _LaporanTabState();
}

class _LaporanTabState extends State<LaporanTab> {
  String _range = 'today';
  ReportData? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await DataService.instance.getReport(_range);
      if (mounted) {
        setState(() {
          _report = r;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text('Laporan',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue)),
          const SizedBox(height: 14),

          // Kartu Ringkasan
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.blue, width: 1.3),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Ringkasan',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue)),
                    ),
                    _RangeDropdown(
                      value: _range,
                      onChanged: (v) {
                        setState(() => _range = v);
                        _load();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _statTile(
                          '${r?.txCount ?? 0}', 'Transaksi'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statTile(
                          '${Fmt.plain(r?.avgMargin ?? 0)}%',
                          'Rata-Rata Untung'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _blueMetric(Icons.trending_up_rounded, 'Pendapatan',
                    Fmt.rp(r?.pendapatan ?? 0)),
                const SizedBox(height: 8),
                _blueMetric(Icons.savings_outlined, 'Keuntungan',
                    Fmt.rp(r?.keuntungan ?? 0)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Header Laporan Transaksi + Lihat semua
          Row(
            children: [
              Container(
                width: 18,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6)),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Laporan Transaksi',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue)),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          AllTransactionsScreen(initialRange: _range)),
                ),
                child: const Text('Lihat semua',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.blue)),
            )
          else if (r == null || r.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: UiColors.blueTint),
              ),
              child: const Column(
                children: [
                  IconBadge(Icons.receipt_long_rounded,
                      size: 52, bg: UiColors.blueTint, fg: AppColors.blue),
                  SizedBox(height: 10),
                  Text('Belum ada transaksi pada rentang ini',
                      style: TextStyle(
                          fontSize: 14, color: UiColors.textMute)),
                ],
              ),
            )
          else
            for (final it in r.items.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TransactionCard(item: it),
              ),
        ],
      ),
    );
  }

  Widget _statTile(String big, String sub) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.blue, width: 1),
        ),
        child: Column(
          children: [
            Text(big,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue)),
            Text(sub,
                style:
                    const TextStyle(fontSize: 11.5, color: UiColors.textMute)),
          ],
        ),
      );

  Widget _blueMetric(IconData icon, String label, String val) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            IconBadge(icon,
                size: 38, bg: AppColors.white, fg: AppColors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11.5, color: Color(0xFFD6E3FA))),
                  Text(val,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Laporan Transaksi
class AllTransactionsScreen extends StatefulWidget {
  final String initialRange;
  const AllTransactionsScreen({super.key, this.initialRange = 'today'});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  late String _range = widget.initialRange;
  ReportData? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await DataService.instance.getReport(_range);
      if (mounted) {
        setState(() {
          _report = r;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportCsv() async {
    final items = _report?.items ?? [];
    if (items.isEmpty) {
      showWarning(context, 'Belum ada data transaksi untuk diunduh', top: 72);
      return;
    }
    final buf = StringBuffer(
        'Tanggal,Produk,Kategori,Kuantitas,Harga Satuan,Total,Kasir\n');
    for (final it in items) {
      buf.writeln(
          '"${_fmtTxDate(it.createdAt)}","${it.productName}","${it.kategori}",${Fmt.plain(it.kuantitas)},${it.hargaSatuan.round()},${it.total.round()},"${it.kasir}"');
    }
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final fileName = 'laporan_labaku_${_range}_$stamp.csv';
    try {
      await exportCsvFile(fileName, buf.toString());
      if (!mounted) return;
      await showResultDialog(
        context,
        title: 'Laporan Terunduh',
        message: 'File $fileName berhasil dibuat dan siap dibuka.',
      );
    } catch (_) {
      if (mounted) {
        showWarning(context, 'Gagal mengunduh laporan CSV', top: 72);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final items = _report?.items ?? [];
    return Scaffold(
      backgroundColor: UiColors.page,
      body: PageBg(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 20, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back_rounded,
                            size: 28, color: AppColors.blue),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Laporan Transaksi',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Rentang Waktu',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.blue)),
                        ),
                        _RangeDropdown(
                          value: _range,
                          onChanged: (v) {
                            setState(() => _range = v);
                            _load();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _exportCsv,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.file_download_outlined,
                                  size: 18, color: AppColors.white),
                              SizedBox(width: 6),
                              Text('Unduh Laporan',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.blue))
                    : items.isEmpty
                        ? const Center(
                            child: Text('Belum ada transaksi',
                                style: TextStyle(
                                    fontSize: 14.5, color: UiColors.textMute)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: items.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TransactionCard(item: items[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final SaleReportItem item;
  const _TransactionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue, width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCDCDC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(categoryIcon(item.kategori),
                    size: 24, color: AppColors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName,
                        style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                    Text(item.kategori,
                        style: const TextStyle(
                            fontSize: 12, color: UiColors.textMute)),
                  ],
                ),
              ),
              Text('x ${Fmt.plain(item.kuantitas)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Tanggal: ${_fmtTxDate(item.createdAt)}',
              style: const TextStyle(fontSize: 11.5, color: UiColors.textMute)),
          Row(
            children: [
              Expanded(
                child: Text('Nama Kasir: ${item.kasir}',
                    style: const TextStyle(
                        fontSize: 11.5, color: UiColors.textMute)),
              ),
              Text(Fmt.rp(item.total),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _RangeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blue, width: 1.1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.black, size: 20),
          style: const TextStyle(
              fontSize: 13.5, fontFamily: 'Poppins', color: Colors.black),
          items: [
            for (final (k, label) in _ranges)
              DropdownMenuItem(value: k, child: Text(label)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
