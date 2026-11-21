import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/ui_kit.dart';
import '../core/widgets.dart';
import '../services/data_service.dart';
import 'product_card.dart';
import 'product_detail_screen.dart';

/// Halaman "Semua Produk Kamu" (bisa dibuka dari "Lihat semua" di Beranda).
class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  List<ProductSummary> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await DataService.instance.listProducts();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat produk';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      backgroundColor: UiColors.page,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.arrow_back_rounded,
                          size: 30, color: AppColors.blue),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Semua Produk Kamu',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.blue))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!,
                                  style: const TextStyle(
                                      color: UiColors.textMute)),
                              const SizedBox(height: 12),
                              AppButton(
                                  text: 'Coba Lagi',
                                  width: 140,
                                  height: 38,
                                  fontSize: 14,
                                  onTap: _load),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.blue,
                          onRefresh: _load,
                          child: _items.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 120),
                                    Center(
                                      child: Text('Belum ada produk',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: UiColors.textMute)),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 10, 20, 28),
                                  itemCount: _items.length + 1,
                                  itemBuilder: (_, i) {
                                    if (i == _items.length) {
                                      return const Padding(
                                        padding: EdgeInsets.only(top: 12),
                                        child: Center(
                                          child: Text(
                                            'Sudah menampilkan semua produk kamu',
                                            style: TextStyle(
                                                fontSize: 12.5,
                                                color: UiColors.textMute),
                                          ),
                                        ),
                                      );
                                    }
                                    final p = _items[i];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
                                      child: ProductCard(
                                        product: p,
                                        onTap: () async {
                                          final changed =
                                              await Navigator.of(context)
                                                  .push<bool>(
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    ProductDetailScreen(
                                                        summary: p)),
                                          );
                                          if (changed == true) _load();
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet detail produk + konfirmasi hapus produk (sesuai diagram use case).
Future<bool?> showProductDetailSheet(
    BuildContext context, ProductSummary summary) {
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    barrierColor: AppColors.overlay,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _ProductDetailSheet(summary: summary),
  );
}

class _ProductDetailSheet extends StatefulWidget {
  final ProductSummary summary;
  const _ProductDetailSheet({required this.summary});

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  ProductDetail? _detail;
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await DataService.instance.getProduct(widget.summary.id);
      if (mounted) {
        setState(() {
          _detail = d;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final yes = await showAppDialog<bool>(
      context,
      (ctx) => AppDialogCard(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconBadge(Icons.delete_outline_rounded,
                size: 56, bg: AppColors.redSoft, fg: AppColors.red),
            const SizedBox(height: 14),
            const Text('Hapus Produk?',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black)),
            const SizedBox(height: 6),
            Text(
              'Produk "${widget.summary.nama}" akan dihapus dari daftar produk kamu.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: UiColors.textMute),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Batal',
                    height: 38,
                    fontSize: 14.5,
                    style: BtnStyle.outline,
                    onTap: () => Navigator.of(ctx, rootNavigator: true).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: Material(
                      color: AppColors.red,
                      shape: const StadiumBorder(),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: () =>
                            Navigator.of(ctx, rootNavigator: true).pop(true),
                        child: const Center(
                          child: Text('Hapus',
                              style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      dismissible: true,
    );
    if (yes != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await DataService.instance.deleteProduct(widget.summary.id);
      if (mounted) Navigator.of(context, rootNavigator: true).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        showWarning(context, 'Gagal menghapus produk', top: 80);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final perUnit = s.jumlahProduksi > 0 ? s.hargaJual / s.jumlahProduksi : 0;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFD0D0D0),
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.nama,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black)),
                        Text(
                            '${s.kategori} • ${Fmt.plain(s.jumlahProduksi)} ${s.unit}',
                            style: const TextStyle(
                                fontSize: 13, color: UiColors.textMute)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                    child: const Icon(Icons.close_rounded, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: UiColors.blueTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _col('Total HPP', Fmt.rp(s.totalHpp)),
                    _col('Harga Jual', Fmt.rp(s.hargaJual)),
                    _col('Per ${s.unit}', Fmt.rp(perUnit)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.blue)),
                )
              else if (_detail != null) ...[
                _listBlock('Bahan Baku', [
                  for (final m in _detail!.materials)
                    '${m['nama']} (${Fmt.plain((m['qty'] as num).toDouble())} ${m['unit'] ?? ''})'
                ]),
                if (_detail!.labors.isNotEmpty)
                  _listBlock('Tenaga Kerja', [
                    for (final l in _detail!.labors)
                      '${l['nama']} • ${Fmt.rp(((l['qty'] as num) * (l['tarif'] as num)).toDouble())}'
                  ]),
                if (_detail!.overheads.isNotEmpty)
                  _listBlock('Overhead Manual', [
                    for (final o in _detail!.overheads)
                      '${o['komponen']} • ${Fmt.rp((o['harga'] as num).toDouble())}'
                  ]),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _deleting ? null : _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: Text(_deleting ? 'Menghapus...' : 'Hapus Produk',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _col(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(fontSize: 11.5, color: AppColors.blue)),
          Text(v,
              style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black)),
        ],
      );

  Widget _listBlock(String title, List<String> rows) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black)),
            const SizedBox(height: 4),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('• $r',
                    style: const TextStyle(
                        fontSize: 13, color: UiColors.textMute)),
              ),
          ],
        ),
      );
}
