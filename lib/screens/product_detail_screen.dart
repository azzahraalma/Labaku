import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/calc.dart';
import '../core/format.dart';
import '../core/ui_kit.dart';
import '../core/widgets.dart';
import '../services/data_service.dart';
import 'discount_sim_screen.dart';
import 'wizard/add_product_wizard.dart';

/// Detail Produk
class ProductDetailScreen extends StatefulWidget {
  final ProductSummary summary;
  const ProductDetailScreen({super.key, required this.summary});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductDetail? _detail;
  bool _loading = true;
  bool _deleting = false;

  bool _openBahan = false;
  bool _openTenaga = false;
  bool _openOverhead = false;
  bool _openService = false;
  bool _openPajak = false;

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

  Future<void> _delete() async {
    final yes = await showConfirmDeleteDialog(context);
    if (!yes || !mounted) return;
    setState(() => _deleting = true);
    try {
      await DataService.instance.deleteProduct(widget.summary.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        showWarning(context, 'Gagal menghapus produk', top: 72);
      }
    }
  }

  Future<void> _editStock(ProductSummary s) async {
    final ctrl = TextEditingController();
    String mode = 'add'; // 'add' | 'set'
    bool saving = false;
    final ok = await showAppDialog<bool>(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AppDialogCard(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DialogTitleRow(
                title: 'Kelola Stok',
                onClose: () => Navigator.of(ctx, rootNavigator: true).pop(false),
              ),
              const SizedBox(height: 6),
              Text(
                'Stok saat ini: ${Fmt.plain(s.sisaStok)} ${s.unit}',
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setS(() => mode = 'add'),
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: mode == 'add'
                              ? AppColors.blue
                              : UiColors.blueTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+ Tambah Stok',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: mode == 'add'
                                ? AppColors.white
                                : AppColors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setS(() => mode = 'set'),
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: mode == 'set'
                              ? AppColors.blue
                              : UiColors.blueTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Atur Stok',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: mode == 'set'
                                ? AppColors.white
                                : AppColors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                mode == 'add'
                    ? 'Jumlah stok tambahan (${s.unit})'
                    : 'Jumlah stok aktual baru (${s.unit})',
                style: const TextStyle(fontSize: 13, color: AppColors.black),
              ),
              const SizedBox(height: 6),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.blue),
                ),
                child: TextField(
                  controller: ctrl,
                  onChanged: (_) => setS(() {}),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: mode == 'add'
                        ? 'Contoh: ${Fmt.plain(s.jumlahProduksi)}'
                        : 'Contoh: 20',
                    hintStyle: const TextStyle(color: UiColors.textMute),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (mode == 'add' && s.jumlahProduksi > 0) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    GestureDetector(
                      onTap: () => setS(() {
                        ctrl.text = Fmt.plain(s.jumlahProduksi);
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: UiColors.blueTint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.blue, width: 0.8),
                        ),
                        child: Text(
                          '+1x Produksi (${Fmt.plain(s.jumlahProduksi)} ${s.unit})',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setS(() {
                        ctrl.text = Fmt.plain(s.jumlahProduksi * 2);
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: UiColors.blueTint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.blue, width: 0.8),
                        ),
                        child: Text(
                          '+2x Produksi (${Fmt.plain(s.jumlahProduksi * 2)} ${s.unit})',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Menambah atau mengatur stok tidak mengubah modal (HPP) per ${s.unit}.',
                style: const TextStyle(fontSize: 11.5, color: UiColors.textMute),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Batal',
                      height: 40,
                      fontSize: 14,
                      style: BtnStyle.outline,
                      onTap: () =>
                          Navigator.of(ctx, rootNavigator: true).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Builder(builder: (_) {
                      final parsed = double.tryParse(
                          ctrl.text.trim().replaceAll(',', '.'));
                      final ready = parsed != null &&
                          (mode == 'add' ? parsed > 0 : parsed >= 0);
                      return AppButton(
                        text: 'Simpan',
                        height: 40,
                        fontSize: 14,
                        loading: saving,
                        style: ready ? BtnStyle.primary : BtnStyle.disabledSoft,
                        onTap: () async {
                          if (!ready) {
                            showWarning(ctx, 'Lengkapin data nya dulu ya!',
                                top: 113);
                            return;
                          }
                          setS(() => saving = true);
                          try {
                            await DataService.instance.updateProductStock(
                              productId: s.id,
                              nilai: parsed,
                              mode: mode,
                            );
                            if (ctx.mounted) {
                              Navigator.of(ctx, rootNavigator: true).pop(true);
                            }
                          } catch (_) {
                            if (ctx.mounted) {
                              setS(() => saving = false);
                              showWarning(ctx, 'Gagal memperbarui stok',
                                  top: 113);
                            }
                          }
                        },
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      dismissible: true,
    );
    ctrl.dispose();
    if (ok == true && mounted) {
      await _load();
    }
  }

  void _showInfo(String title, String body) {
    showAppDialog<void>(
      context,
      (ctx) => AppDialogCard(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DialogTitleRow(
                title: title,
                onClose: () => Navigator.of(ctx, rootNavigator: true).pop()),
            const SizedBox(height: 10),
            Text(body,
                style: const TextStyle(
                    fontSize: 13.5, height: 1.5, color: AppColors.black)),
          ],
        ),
      ),
      dismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final s = _detail?.summary ?? widget.summary;
    final hppUnit = s.hppPerUnit;
    final jualUnit = s.hargaNetPerUnit;
    final akhirUnit = s.hargaJualPerUnit;
    final svcTotal = s.hasService ? s.hargaNet * (s.servicePersen / 100) : 0.0;
    final taxTotal = s.hasTax
        ? (s.hargaNet + svcTotal) * (s.pajakPersen / 100)
        : 0.0;
    final extraTotal = s.hargaJual - s.hargaNet;
    final roundExtra = (extraTotal - svcTotal - taxTotal).clamp(0.0, double.infinity);

    String metodeBadge() {
      switch (s.marginMetode) {
        case 'markup':
          return 'Markup: ${Fmt.plain(s.marginNilai ?? 0)}%';
        case 'margin':
          return 'Margin: ${Fmt.plain(s.marginNilai ?? 0)}%';
        case 'manual':
          return 'Manual: ${Fmt.rp(s.marginNilai ?? jualUnit)}';
        default:
          return 'Margin: ${Fmt.pct(s.marginTarget)}';
      }
    }

    return Scaffold(
      backgroundColor: UiColors.page,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.arrow_back_rounded,
                          size: 28, color: AppColors.blue),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Detail Produk',
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: PageBg(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.nama,
                                          style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.white)),
                                      Text(s.kategori,
                                          style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Color(0xFFD6E3FA))),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.inventory_2_rounded,
                                              size: 18, color: AppColors.white),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Produksi Awal: ${Fmt.plain(s.jumlahProduksi)} ${s.unit.toUpperCase()}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.white),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: s.sisaStok <= 0
                                                  ? AppColors.redSoft
                                                  : UiColors.blueTint,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              s.sisaStok <= 0
                                                  ? 'Stok habis'
                                                  : 'Sisa stok: ${Fmt.plain(s.sisaStok)} ${s.unit}',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: s.sisaStok <= 0
                                                    ? AppColors.red
                                                    : AppColors.blue,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _editStock(s),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.yellow,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                '+ Stok',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.yellow,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(Fmt.pct(s.keuntunganAktual),
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black)),
                                    ),
                                    const SizedBox(height: 3),
                                    Text('margin ${Fmt.pct(s.marginTarget)}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Color(0xFFD6E3FA))),
                                    if (s.hasTax) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: UiColors.blueTint,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          TaxType.byId(s.pajakJenis).nama,
                                          style: const TextStyle(
                                              fontSize: 10.5,
                                              fontStyle: FontStyle.italic,
                                              color: AppColors.blue),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Harga Jual Total',
                                      style: TextStyle(
                                          fontSize: 12, color: AppColors.blue)),
                                  Text(Fmt.rp(s.hargaJual),
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Ringkasan Keuangan
                      const SectionLabel('Ringkasan Keuangan',
                          size: 17, weight: FontWeight.w700),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                                color: UiColors.shadow,
                                blurRadius: 8,
                                offset: Offset(0, 3))
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('Metode Harga',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.black)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: UiColors.blueTint,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(metodeBadge(),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.blue)),
                                ),
                              ],
                            ),
                            const Divider(height: 22, color: AppColors.blue),
                            _finRow('HPP (Modal) per Unit', Fmt.rp(hppUnit),
                                Icons.shopping_basket_rounded, AppColors.blue, Colors.black),
                            const Divider(height: 22, color: AppColors.blue),
                            _finRow('Harga Jual per Unit', Fmt.rp(jualUnit),
                                Icons.local_offer_rounded, AppColors.blue, Colors.black),
                            const Divider(height: 22, color: AppColors.blue),
                            _finRow('Harga Akhir per Unit', Fmt.rp(akhirUnit),
                                Icons.payments_rounded, const Color(0xFF1B9E2E), const Color(0xFF1B9E2E)),
                            const Divider(height: 22, color: AppColors.blue),
                            _finRow(
                              'Keuntungan Bersih',
                              Fmt.rp(s.labaBersih),
                              Icons.trending_up_rounded,
                              s.labaBersih < 0
                                  ? AppColors.red
                                  : const Color(0xFF1B9E2E),
                              s.labaBersih < 0
                                  ? AppColors.red
                                  : const Color(0xFF1B9E2E),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Biaya Tambahan
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: UiColors.blueTint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.blue, width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Biaya Tambahan',
                                style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.blue)),
                            const SizedBox(height: 8),
                            _kv('Service Charge', Fmt.rp(svcTotal)),
                            const SizedBox(height: 4),
                            _kv('Pajak', Fmt.rp(taxTotal)),
                            const SizedBox(height: 4),
                            _kv('Pembulatan Harga', Fmt.rp(roundExtra)),
                            const Divider(height: 20, color: AppColors.blue),
                            _kv('Keuntungan Bersih:', Fmt.rp(s.labaBersih),
                                bold: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Hitung Diskon
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final changed =
                                await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      DiscountSimScreen(product: s)),
                            );
                            if (changed == true && mounted) await _load();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.grey,
                            backgroundColor: AppColors.white,
                            side: const BorderSide(color: AppColors.grey),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.local_offer_rounded, size: 18),
                          label: const Text('Hitung Diskon',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.blue)),
                        )
                      else ...[
                        // 5 Accordion
                        _accordion(
                          icon: Icons.inventory_2_rounded,
                          title:
                              'Komposisi Bahan (${_detail?.materials.length ?? 0})',
                          open: _openBahan,
                          onTap: () => setState(() => _openBahan = !_openBahan),
                          child: _bahanBody(s),
                        ),
                        _accordion(
                          icon: Icons.groups_rounded,
                          title:
                              'Tenaga Kerja (${_detail?.labors.length ?? 0})',
                          open: _openTenaga,
                          onTap: () =>
                              setState(() => _openTenaga = !_openTenaga),
                          child: _tenagaBody(s),
                        ),
                        _accordion(
                          icon: Icons.account_balance_rounded,
                          title: 'Overhead',
                          open: _openOverhead,
                          onInfo: () => _showInfo(
                            'Biaya Overhead',
                            'Biaya rutin di luar bahan baku dan tenaga kerja langsung, seperti sewa tempat, listrik, air, gas, dan internet.',
                          ),
                          onTap: () =>
                              setState(() => _openOverhead = !_openOverhead),
                          child: _overheadBody(s),
                        ),
                        _accordion(
                          icon: Icons.room_service_rounded,
                          title: 'Service Charge',
                          open: _openService,
                          onInfo: () => _showInfo(
                            'Service Charge',
                            'Biaya tambahan yang dibebankan kepada pelanggan atas jasa pelayanan (umumnya 5%–10% pada restoran atau hotel).',
                          ),
                          onTap: () =>
                              setState(() => _openService = !_openService),
                          child: Column(
                            children: [
                              _kv('Tarif:', '${Fmt.plain(s.servicePersen)}%'),
                              const Divider(height: 18, color: AppColors.blue),
                              _kv('Total Service Charge:', Fmt.rp(svcTotal),
                                  bold: true),
                            ],
                          ),
                        ),
                        _accordion(
                          icon: Icons.receipt_long_rounded,
                          title: 'Pajak',
                          open: _openPajak,
                          onTap: () => setState(() => _openPajak = !_openPajak),
                          child: Column(
                            children: [
                              _kv(
                                'Jenis Pajak:',
                                s.hasTax
                                    ? TaxType.byId(s.pajakJenis).nama
                                    : 'Tidak ada',
                              ),
                              const SizedBox(height: 4),
                              _kv('Tarif:', '${Fmt.plain(s.pajakPersen)}%'),
                              const SizedBox(height: 4),
                              _kv(
                                'Metode:',
                                s.pajakTermasuk
                                    ? 'Sudah Termasuk Pajak'
                                    : 'Belum Termasuk Pajak',
                              ),
                              const Divider(height: 18, color: AppColors.blue),
                              _kv('Jumlah Pajak:', Fmt.rp(taxTotal),
                                  bold: true),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Rincian Biaya
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                                color: UiColors.shadow,
                                blurRadius: 8,
                                offset: Offset(0, 3))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rincian Biaya',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black)),
                            const SizedBox(height: 10),
                            _kvPlain('Bahan Baku', Fmt.rp(s.hppBahan)),
                            const SizedBox(height: 6),
                            _kvPlain('Tenaga Kerja', Fmt.rp(s.hppTenaga)),
                            const SizedBox(height: 6),
                            _kvPlain('Overhead', Fmt.rp(s.hppOverhead)),
                            const Divider(height: 22, color: AppColors.blue),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('Total HPP',
                                      style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black)),
                                ),
                                Text(Fmt.rp(s.totalHpp),
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.blue)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Edit Produk 
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _detail == null
                              ? null
                              : () async {
                                  final updated =
                                      await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddProductWizard(editing: _detail!),
                                    ),
                                  );
                                  if (updated == true && mounted) {
                                    await _load();
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.grey,
                            backgroundColor: AppColors.white,
                            side: const BorderSide(
                                color: AppColors.grey, width: 1.1),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 19),
                          label: const Text(
                            'Edit Produk',
                            style: TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Hapus Produk
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _deleting ? null : _delete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red,
                            backgroundColor: AppColors.white,
                            side: const BorderSide(
                                color: AppColors.red, width: 1.2),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 20),
                          label: Text(
                            _deleting ? 'Menghapus...' : 'Hapus Produk',
                            style: const TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _finRow(String label, String val, IconData icon, Color iconColor,
      Color valColor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.black)),
              const SizedBox(height: 2),
              Text(val,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: valColor)),
            ],
          ),
        ),
        Icon(icon, size: 32, color: iconColor),
      ],
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) => Row(
        children: [
          Expanded(
            child: Text(k,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: Colors.black)),
          ),
          Text(v,
              style: TextStyle(
                  fontSize: bold ? 14.5 : 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: AppColors.blue)),
        ],
      );

  Widget _kvPlain(String k, String v) => Row(
        children: [
          Expanded(
              child: Text(k,
                  style: const TextStyle(fontSize: 13.5, color: Colors.black))),
          Text(v,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black)),
        ],
      );

  Widget _accordion({
    required IconData icon,
    required String title,
    required bool open,
    required VoidCallback onTap,
    required Widget child,
    VoidCallback? onInfo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: UiColors.shadow, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Icon(icon, size: 24, color: AppColors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(title,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.blue)),
                          ),
                          if (onInfo != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: onInfo,
                              child: const Icon(Icons.info_rounded,
                                  size: 16, color: AppColors.blue),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      open
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.black,
                    ),
                  ],
                ),
              ),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: child,
              ),
          ],
        ),
      ),
    );
  }

  Widget _bahanBody(ProductSummary s) {
    final items = _detail?.materials ?? [];
    return Column(
      children: [
        for (final m in items) ...[
          Builder(builder: (_) {
            final qty = (m['qty'] as num).toDouble();
            final uc = MaterialCost.unitCost(
              hargaBeli: (m['harga_beli'] as num).toDouble(),
              jumlahBeli: (m['jumlah_beli'] as num).toDouble(),
              penyusutanPersen: (m['penyusutan'] as num).toDouble(),
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${m['nama']}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(
                            '${Fmt.plain(qty)} ${m['unit'] ?? ''} x ${Fmt.rp(uc)}',
                            style: const TextStyle(
                                fontSize: 11.5, color: UiColors.textMute)),
                      ],
                    ),
                  ),
                  Text(Fmt.rp(qty * uc),
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
        const Divider(height: 16, color: AppColors.blue),
        _kv('Total Bahan:', Fmt.rp(s.hppBahan), bold: true),
      ],
    );
  }

  Widget _tenagaBody(ProductSummary s) {
    final items = _detail?.labors ?? [];
    return Column(
      children: [
        if (items.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Tidak ada tenaga kerja',
                style: TextStyle(fontSize: 13, color: UiColors.textMute)),
          )
        else
          for (final l in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${l['nama']}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(
                            '${Fmt.plain((l['qty'] as num).toDouble())} ${l['metode'] ?? 'jam'} x ${Fmt.rp((l['tarif'] as num).toDouble())}',
                            style: const TextStyle(
                                fontSize: 11.5, color: UiColors.textMute)),
                      ],
                    ),
                  ),
                  Text(
                    Fmt.rp(((l['qty'] as num) * (l['tarif'] as num)).toDouble()),
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        const Divider(height: 16, color: AppColors.blue),
        _kv('Total Tenaga Kerja:', Fmt.rp(s.hppTenaga), bold: true),
      ],
    );
  }

  Widget _overheadBody(ProductSummary s) {
    final items = _detail?.overheads ?? [];
    return Column(
      children: [
        if (s.overheadMode == 'persen')
          _kv('Tipe: Presentase', '${Fmt.plain(s.overheadPersen ?? 0)}%')
        else if (items.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Tidak ada item overhead',
                style: TextStyle(fontSize: 13, color: UiColors.textMute)),
          )
        else
          for (final o in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _kvPlain(
                  '${o['komponen']}', Fmt.rp((o['harga'] as num).toDouble())),
            ),
        const Divider(height: 16, color: AppColors.blue),
        _kv('Total Overhead:', Fmt.rp(s.hppOverhead), bold: true),
      ],
    );
  }
}
