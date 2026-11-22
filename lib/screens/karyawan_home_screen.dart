import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/ui_kit.dart';
import '../core/widgets.dart';
import '../services/data_service.dart';
import 'terms_screen.dart';
import 'wizard/wizard_dialogs.dart';

class KaryawanHomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const KaryawanHomeScreen({super.key, required this.onLogout});

  @override
  State<KaryawanHomeScreen> createState() => _KaryawanHomeScreenState();
}

class _KaryawanHomeScreenState extends State<KaryawanHomeScreen> {
  final _ds = DataService.instance;
  final _search = TextEditingController();
  int _tab = 0;
  String _selectedCat = 'Semua';
  List<ProductSummary> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ds.addListener(_onData);
    _loadProducts();
  }

  @override
  void dispose() {
    _ds.removeListener(_onData);
    _search.dispose();
    super.dispose();
  }

  void _onData() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProducts() async {
    try {
      final list = await _ds.listProducts();
      if (mounted) {
        setState(() {
          _products = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      backgroundColor: UiColors.page,
      body: PageBg(
        child: SafeArea(
          bottom: false,
          child: _tab == 0 ? _buildHome() : _buildProfil(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: UiColors.shadow, blurRadius: 12, offset: Offset(0, -3))
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = 0),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            _tab == 0
                                ? Icons.home_rounded
                                : Icons.home_outlined,
                            size: 28,
                            color: AppColors.blue),
                        const SizedBox(height: 2),
                        Text('Beranda',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: _tab == 0
                                    ? FontWeight.w600
                                    : FontWeight.w400)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = 1),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            _tab == 1
                                ? Icons.person_rounded
                                : Icons.person_outline_rounded,
                            size: 28,
                            color: AppColors.blue),
                        const SizedBox(height: 2),
                        Text(_tab == 1 ? 'Profil' : 'Akun',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: _tab == 1
                                    ? FontWeight.w600
                                    : FontWeight.w400)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHome() {
    final h = _ds.home;
    final q = _search.text.trim().toLowerCase();
    final cats = ['Semua', ..._ds.categories.map((c) => c.nama)];
    final filtered = _products.where((p) {
      final okCat = _selectedCat == 'Semua' || p.kategori == _selectedCat;
      final okQ = q.isEmpty || p.nama.toLowerCase().contains(q);
      return okCat && okQ;
    }).toList();

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.blue,
          onRefresh: () async {
            await _ds.load();
            await _loadProducts();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              // Avatar + Nama Karyawan (klik -> Profil)
              GestureDetector(
                onTap: () => setState(() => _tab = 1),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                          color: Color(0xFFE0E0E0), shape: BoxShape.circle),
                      child: (h?.fotoUrl != null && h!.fotoUrl!.isNotEmpty)
                          ? Image.network(h.fotoUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.person_rounded,
                              size: 28, color: AppColors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(h?.username ?? 'Karyawan',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kartu Usaha 
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: AppColors.blue, width: 1.3),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.blue, width: 1.4),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          size: 26, color: AppColors.darkYellow),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h?.businessName ?? '-',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black)),
                          Text(h?.businessCategory ?? '-',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Daftar Produk
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(6),
                          bottomRight: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Daftar Produk',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                ],
              ),
              const SizedBox(height: 12),

              OutField(
                controller: _search,
                height: 44,
                radius: 10,
                borderColor: AppColors.blue,
                prefix: const Icon(Icons.search_rounded,
                    size: 22, color: AppColors.grey),
                hint: 'Cari Produk',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = cats[i];
                    final sel = c == _selectedCat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCat = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel ? AppColors.blue : AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: sel ? AppColors.blue : AppColors.grey),
                        ),
                        child: Text(c,
                            style: TextStyle(
                                fontSize: 12,
                                color: sel ? AppColors.white : AppColors.grey)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text('${filtered.length} Produk',
                  style: const TextStyle(fontSize: 12, color: AppColors.blue)),
              const SizedBox(height: 10),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.blue)),
                )
              else if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('Belum ada produk',
                        style: TextStyle(color: UiColors.textMute)),
                  ),
                )
              else
                for (final p in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.blue, width: 1.3),
                      ),
                      child: Row(
                        children: [
                          _ProductThumb(
                            fotoUrl: p.fotoUrl,
                            kategori: p.kategori,
                            size: 46,
                            iconSize: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.nama,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black)),
                                Text(p.kategori,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: UiColors.textMute)),
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _StockBox(
                                        stok: p.sisaStok, unit: p.unit),
                                    if (p.hasDiscount)
                                      _DiscountTag(
                                          label: p.diskonLabel ?? 'Diskon'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (p.hasDiscount)
                                Text(
                                  Fmt.rp(p.hargaJualPerUnit),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: UiColors.textMute,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                Fmt.rp(p.effectivePricePerUnit),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: p.hasDiscount
                                      ? AppColors.blue
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),

        // Tambah Penjualan
        Positioned(
          left: 0,
          right: 0,
          bottom: 18,
          child: Center(
            child: AppButton(
              text: '+  Tambah Penjualan',
              width: 220,
              height: 44,
              fontSize: 14.5,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TambahPenjualanScreen(products: _products),
                  ),
                );
                if (mounted) await _loadProducts();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfil() {
    final h = _ds.home;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        const Text('Profil',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.blue)),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () async {
              try {
                final f = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 70);
                if (f == null) return;
                final bytes = await f.readAsBytes();
                await _ds.updateProfile(foto: bytes);
                if (mounted) {
                  showResultDialog(context,
                      title: 'Foto Diperbarui',
                      message: 'Foto profil kamu berhasil diubah');
                }
              } catch (_) {}
            },
            child: Column(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE0E0E0), shape: BoxShape.circle),
                        child: (h?.fotoUrl != null && h!.fotoUrl!.isNotEmpty)
                            ? Image.network(h.fotoUrl!, fit: BoxFit.cover)
                            : const Icon(Icons.person_rounded,
                                size: 54, color: AppColors.grey),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                              color: AppColors.blue, shape: BoxShape.circle),
                          child: const Icon(Icons.edit_rounded,
                              size: 16, color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Edit Foto Profil',
                    style:
                        TextStyle(fontSize: 12.5, color: UiColors.textMute)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: UiColors.shadow, blurRadius: 10, offset: Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nama',
                  style: TextStyle(fontSize: 12, color: UiColors.textMute)),
              const SizedBox(height: 4),
              Text(h?.username ?? '-',
                  style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black)),
              const Divider(height: 16, color: AppColors.blue),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TermsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.blue, width: 1.2),
            ),
            child: Row(
              children: [
                IconBadge(
                  Icons.description_rounded,
                  size: 42,
                  bg: UiColors.lavender,
                  fg: AppColors.blue,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Syarat & Ketentuan',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.black,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: widget.onLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              backgroundColor: AppColors.white,
              side: const BorderSide(color: AppColors.red, width: 1),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Log Out',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// TAMBAH PENJUALAN 
class TambahPenjualanScreen extends StatefulWidget {
  final List<ProductSummary> products;
  const TambahPenjualanScreen({super.key, required this.products});

  @override
  State<TambahPenjualanScreen> createState() => _TambahPenjualanScreenState();
}

class _TambahPenjualanScreenState extends State<TambahPenjualanScreen> {
  final _ds = DataService.instance;
  final _search = TextEditingController();
  String _selectedCat = 'Semua';
  final Map<String, int> _selected = {}; // productId -> qty

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.containsKey(id)) {
        _selected.remove(id);
      } else {
        _selected[id] = 1;
      }
    });
  }

  Future<void> _openConfirm() async {
    if (_selected.isEmpty) return;
    final picked = widget.products
        .where((p) => _selected.containsKey(p.id))
        .toList();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      barrierColor: AppColors.overlay,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => _OrderSheet(products: picked, quantities: _selected),
    );
    if (saved == true && mounted) {
      await showResultDialog(
        context,
        title: 'Penjualan Tersimpan',
        message: 'Transaksi penjualan berhasil dicatat ke laporan',
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final cats = ['Semua', ..._ds.categories.map((c) => c.nama)];
    final filtered = widget.products.where((p) {
      final okCat = _selectedCat == 'Semua' || p.kategori == _selectedCat;
      final okQ = q.isEmpty || p.nama.toLowerCase().contains(q);
      return okCat && okQ;
    }).toList();
    final hasAny = _selected.isNotEmpty;

    return Scaffold(
      backgroundColor: UiColors.page,
      body: PageBg(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
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
                        const Text('Tambah Penjualan',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blue)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutField(
                          controller: _search,
                          height: 44,
                          radius: 10,
                          borderColor: AppColors.blue,
                          prefix: const Icon(Icons.search_rounded,
                              size: 22, color: AppColors.grey),
                          hint: 'Cari Produk',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 30,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: cats.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final c = cats[i];
                              final sel = c == _selectedCat;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCat = c),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                        sel ? AppColors.blue : AppColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: sel
                                            ? AppColors.blue
                                            : AppColors.grey),
                                  ),
                                  child: Text(c,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: sel
                                              ? AppColors.white
                                              : AppColors.grey)),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('${filtered.length} Produk',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.blue)),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.76,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        final added = _selected.containsKey(p.id);
                        final outOfStock = p.sisaStok <= 0;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.blue, width: 1.3),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ProductThumb(
                                fotoUrl: p.fotoUrl,
                                kategori: p.kategori,
                                size: 54,
                                iconSize: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(p.nama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black)),
                              const SizedBox(height: 3),
                              _StockBox(
                                stok: p.sisaStok,
                                unit: p.unit,
                                compact: true,
                              ),
                              if (p.hasDiscount) ...[
                                const SizedBox(height: 3),
                                _DiscountTag(
                                    label: p.diskonLabel ?? 'Diskon',
                                    compact: true),
                                Text(
                                  Fmt.rp(p.hargaJualPerUnit),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: UiColors.textMute,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                              Text(Fmt.rp(p.effectivePricePerUnit),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.blue)),
                              const Spacer(),
                              GestureDetector(
                                onTap: outOfStock ? null : () => _toggle(p.id),
                                child: Container(
                                  width: double.infinity,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: outOfStock
                                        ? AppColors.surface
                                        : added
                                            ? UiColors.blueTint
                                            : AppColors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                    border: added && !outOfStock
                                        ? Border.all(color: AppColors.blue)
                                        : null,
                                  ),
                                  child: Text(
                                    outOfStock
                                        ? 'Habis'
                                        : added
                                            ? 'Ditambah'
                                            : '+ Tambah',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: outOfStock
                                            ? UiColors.textMute
                                            : added
                                                ? AppColors.blue
                                                : AppColors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Konfirmasi Pesanan
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(
                  child: GestureDetector(
                    onTap: hasAny ? _openConfirm : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 13),
                      decoration: BoxDecoration(
                        color: hasAny ? AppColors.yellow : AppColors.surface,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(
                              color: UiColors.shadow,
                              blurRadius: 10,
                              offset: Offset(0, 4))
                        ],
                      ),
                      child: const Text('Konfirmasi Pesanan',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black)),
                    ),
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

class _OrderSheet extends StatefulWidget {
  final List<ProductSummary> products;
  final Map<String, int> quantities;
  const _OrderSheet({required this.products, required this.quantities});

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  bool _saving = false;

  double get _total => widget.products.fold<double>(
      0, (s, p) => s + (widget.quantities[p.id] ?? 0) * p.effectivePricePerUnit);

  Future<void> _save() async {
    final items = <Map<String, dynamic>>[];
    for (final p in widget.products) {
      final q = widget.quantities[p.id] ?? 0;
      if (q > 0) {
        items.add({
          'product_id': p.id,
          'qty': q,
          'harga_satuan': p.effectivePricePerUnit,
        });
      }
    }
    if (items.isEmpty) return;
    setState(() => _saving = true);
    try {
      await DataService.instance.createSale(items);
      if (mounted) Navigator.of(context, rootNavigator: true).pop(true);
    } on DataFailure catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        final msg = e.code == 'out_of_stock'
            ? 'Stok produk tidak mencukupi, cek sisa stok terbaru ya!'
            : 'Gagal menyimpan penjualan';
        showWarning(context, msg, top: 72);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showWarning(context, 'Gagal menyimpan penjualan', top: 72);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Pesanan',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue)),
                ),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context, rootNavigator: true).pop(false),
                  child: const Icon(Icons.close_rounded, size: 26),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.products.length,
                separatorBuilder: (_, __) => const Divider(height: 18),
                itemBuilder: (_, i) {
                  final p = widget.products[i];
                  final q = widget.quantities[p.id] ?? 0;
                  return Row(
                    children: [
                      _ProductThumb(
                        fotoUrl: p.fotoUrl,
                        kategori: p.kategori,
                        size: 44,
                        iconSize: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nama,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            Text(Fmt.rp(p.effectivePricePerUnit),
                                style: const TextStyle(
                                    fontSize: 13.5, color: AppColors.blue)),
                            if (p.hasDiscount)
                              _DiscountTag(
                                  label: p.diskonLabel ?? 'Diskon',
                                  compact: true),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _qtyBtn(
                                Icons.remove_rounded,
                                active: q > 0,
                                onTap: () => setState(() {
                                  if (q > 0) widget.quantities[p.id] = q - 1;
                                }),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('$q',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                              ),
                              _qtyBtn(
                                Icons.add_rounded,
                                active: q < p.sisaStok.floor(),
                                onTap: () => setState(() {
                                  if (q < p.sisaStok.floor()) {
                                    widget.quantities[p.id] = q + 1;
                                  }
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(Fmt.rp(q * p.effectivePricePerUnit),
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.blue)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text('Total Pesanan',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                ),
                Text(Fmt.rp(total),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black)),
              ],
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'Simpan',
              loading: _saving,
              style: total > 0 ? BtnStyle.primary : BtnStyle.disabledSoft,
              onTap: total > 0
                  ? _save
                  : () => showWarning(
                      context, 'Lengkapin data nya dulu ya!',
                      top: 72),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon,
          {required bool active, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: active ? AppColors.blue : UiColors.blueTint,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon,
              size: 18, color: active ? AppColors.white : AppColors.blue),
        ),
      );
}

class _ProductThumb extends StatelessWidget {
  final String? fotoUrl;
  final String kategori;
  final double size;
  final double iconSize;
  const _ProductThumb({
    required this.fotoUrl,
    required this.kategori,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(categoryIcon(kategori),
        size: iconSize, color: AppColors.grey);
    final hasUrl = fotoUrl != null && fotoUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFDCDCDC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: hasUrl
          ? Image.network(
              fotoUrl!,
              width: size,
              height: size,
              cacheWidth: (size * 2).round(),
              cacheHeight: (size * 2).round(),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(child: fallback),
            )
          : Center(child: fallback),
    );
  }
}

class _StockBox extends StatelessWidget {
  final double stok;
  final String unit;
  final bool compact;
  const _StockBox({
    required this.stok,
    required this.unit,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final habis = stok <= 0;
    final text = habis
        ? 'Stok habis'
        : compact
            ? 'Sisa stok: ${Fmt.plain(stok)}'
            : 'Sisa stok: ${Fmt.plain(stok)} $unit';
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: habis ? AppColors.redSoft : UiColors.blueTint,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: habis ? AppColors.red : AppColors.blue,
          width: 0.9,
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: habis ? AppColors.red : AppColors.blue,
        ),
      ),
    );
  }
}

class _DiscountTag extends StatelessWidget {
  final String label;
  final bool compact;
  const _DiscountTag({required this.label, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_rounded,
              size: compact ? 11 : 12, color: AppColors.blue),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
