import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/ui_kit.dart';
import '../core/widgets.dart';
import '../services/data_service.dart';

/// Simulasi Diskon
class DiscountSimScreen extends StatefulWidget {
  final ProductSummary product;
  const DiscountSimScreen({super.key, required this.product});

  @override
  State<DiscountSimScreen> createState() => _DiscountSimScreenState();
}

class _DiscountSimScreenState extends State<DiscountSimScreen> {
  bool _isPercent = true;
  final _input = TextEditingController();
  bool _calculated = false;
  bool _err = false;
  bool _saving = false;
  double _discountAmount = 0;

  double get _hppUnit => widget.product.hppPerUnit;
  double get _normalUnit => widget.product.hargaJualPerUnit > 0
      ? widget.product.hargaJualPerUnit
      : widget.product.hargaNetPerUnit;

  Future<void> _applyDiscount() async {
    if (_saving || !_calculated) return;
    final val = Fmt.parse(_input.text);
    final pct = _isPercent
        ? val
        : (_normalUnit > 0 ? (_discountAmount / _normalUnit) * 100 : 0.0);
    setState(() => _saving = true);
    try {
      await DataService.instance.setProductDiscount(
        productId: widget.product.id,
        mode: _isPercent ? 'persen' : 'nominal',
        nilai: val,
        persen: pct,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      await showResultDialog(
        context,
        title: 'Diskon Diterapkan',
        message: 'Harga diskon sudah aktif dan langsung\nterlihat di halaman karyawan',
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showWarning(context, 'Gagal menerapkan diskon, coba lagi ya', top: 72);
      }
    }
  }

  Future<void> _removeDiscount() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await DataService.instance.setProductDiscount(
        productId: widget.product.id,
        mode: null,
        nilai: 0,
        persen: 0,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      await showResultDialog(
        context,
        title: 'Diskon Dihapus',
        message: 'Harga produk kembali ke harga normal',
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showWarning(context, 'Gagal menghapus diskon', top: 72);
      }
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final val = Fmt.parse(_input.text);
    if (val <= 0) {
      setState(() => _err = true);
      showWarning(context, 'Masukkan nilai diskon terlebih dahulu ya!', top: 72);
      return;
    }
    if (_isPercent) {
      if (val >= 100) {
        setState(() => _err = true);
        showWarning(context, 'Diskon persentase harus di bawah 100%', top: 72);
        return;
      }
      setState(() {
        _err = false;
        _discountAmount = _normalUnit * (val / 100);
        _calculated = true;
      });
    } else {
      if (val > _normalUnit) {
        setState(() {
          _err = true;
          _calculated = false;
        });
        showWarning(context, 'Diskon tidak boleh melebihi harga jual!', top: 72);
        return;
      }
      setState(() {
        _err = false;
        _discountAmount = val;
        _calculated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final p = widget.product;
    final afterPrice = (_normalUnit - _discountAmount).clamp(0.0, double.infinity);
    final profitUnit = afterPrice - _hppUnit;
    final marginPct = afterPrice > 0 ? (profitUnit / afterPrice) * 100 : 0.0;
    final isSafe = profitUnit >= 0;

    return Scaffold(
      backgroundColor: UiColors.page,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 10),
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
                  const Text(
                    'Simulasi Diskon',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner kuning
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6D57E),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_rounded,
                              size: 18, color: AppColors.black),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Fitur ini membantu Anda melihat dampak pemberian diskon terhadap keuntungan sebelum benar-benar diterapkan ke pelanggan, termasuk batas aman diskon agar tidak rugi.',
                              style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: AppColors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Kartu biru Produk
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_rounded,
                              size: 32, color: AppColors.white),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Produk',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFFD6E3FA))),
                                Text(p.nama,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Kartu HPP & Harga Jual Normal
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
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
                                child: Text('HPP per Unit',
                                    style: TextStyle(
                                        fontSize: 14, color: AppColors.black)),
                              ),
                              Text(Fmt.rp(_hppUnit),
                                  style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black)),
                            ],
                          ),
                          const Divider(height: 20, color: AppColors.blue),
                          Row(
                            children: [
                              const Expanded(
                                child: Text('Harga Jual Normal',
                                    style: TextStyle(
                                        fontSize: 14, color: AppColors.black)),
                              ),
                              Text(Fmt.rp(_normalUnit),
                                  style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Atur Diskon
                    const Row(
                      children: [
                        Icon(Icons.local_offer_rounded,
                            size: 20, color: AppColors.blue),
                        SizedBox(width: 8),
                        Text('Atur Diskon',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Toggle Persentase 
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.blue, width: 1.2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _isPercent = true;
                                _input.clear();
                                _calculated = false;
                                _err = false;
                              }),
                              child: Container(
                                alignment: Alignment.center,
                                color: _isPercent
                                    ? UiColors.blueTint
                                    : AppColors.white,
                                child: const Text('Persentase',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black)),
                              ),
                            ),
                          ),
                          Container(width: 1, color: AppColors.blue),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _isPercent = false;
                                _input.clear();
                                _calculated = false;
                                _err = false;
                              }),
                              child: Container(
                                alignment: Alignment.center,
                                color: !_isPercent
                                    ? UiColors.blueTint
                                    : AppColors.white,
                                child: const Text('Nominal',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    OutField(
                      controller: _input,
                      height: 48,
                      error: _err,
                      borderColor: _err ? AppColors.red : AppColors.blue,
                      prefix: Text(_isPercent ? '%' : 'Rp',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black)),
                      hint: _isPercent ? 'Contoh: 10' : 'Contoh: 1.000',
                      keyboard: _isPercent
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.number,
                      formatters: [
                        _isPercent
                            ? DecimalFormatter(maxInt: 2)
                            : ThousandsFormatter()
                      ],
                      onChanged: (_) => setState(() => _err = false),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isPercent
                          ? 'Contoh: 20 artinya diskon 20% dari harga jual normal'
                          : 'Contoh: 10000 artinya potongan Rp10.000 per unit',
                      style: const TextStyle(
                          fontSize: 11.5, color: UiColors.textMute),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: Material(
                        color: AppColors.blue,
                        shape: const StadiumBorder(),
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: _calculate,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_offer_rounded,
                                  size: 18, color: AppColors.white),
                              SizedBox(width: 8),
                              Text('Hitung Diskon',
                                  style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (_calculated) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          isSafe ? 'Aman' : 'Rugi',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isSafe
                                ? const Color(0xFF1B9E2E)
                                : AppColors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 22),
                        decoration: BoxDecoration(
                          color: isSafe
                              ? const Color(0xFF7FD187)
                              : const Color(0xFFF4CFD1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Harga Setelah Diskon',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSafe ? Colors.black : AppColors.red,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              Fmt.rp(afterPrice),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: isSafe ? Colors.black : AppColors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Potongan ${Fmt.rp(_discountAmount)} per unit',
                              style: const TextStyle(
                                  fontSize: 13.5, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSafe
                                    ? const Color(0xFF7FD187)
                                    : const Color(0xFFF4CFD1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Keuntungan per Unit',
                                      style: TextStyle(
                                          fontSize: 11.5, color: Colors.black)),
                                  const SizedBox(height: 4),
                                  Text(Fmt.rp(profitUnit),
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: UiColors.blueTint,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Margin',
                                      style: TextStyle(
                                          fontSize: 11.5, color: Colors.black)),
                                  const SizedBox(height: 4),
                                  Text(Fmt.pct(marginPct),
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: 'Terapkan Diskon',
                        height: 44,
                        fontSize: 15,
                        loading: _saving,
                        onTap: _applyDiscount,
                      ),
                    ],
                    if (p.hasDiscount) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _removeDiscount,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red,
                            backgroundColor: AppColors.white,
                            side: const BorderSide(color: AppColors.red),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          label: Text(
                              'Hapus Diskon Aktif (${p.diskonLabel ?? ''})',
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
