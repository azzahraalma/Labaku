import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/offline_screen.dart';
import '../core/ui_kit.dart';
import '../core/widgets.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'akun_screen.dart';
import 'all_products_screen.dart';
import 'karyawan_home_screen.dart';
import 'laporan_screen.dart';
import 'login_screen.dart';
import 'product_card.dart';
import 'product_detail_screen.dart';
import 'produk_tab.dart';
import 'wizard/add_product_wizard.dart';

/// Halaman utama
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ds = DataService.instance;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _ds.addListener(_onData);
    if (_ds.home == null && !_ds.loading) {
      _ds.load();
    }
  }

  @override
  void dispose() {
    _ds.removeListener(_onData);
    super.dispose();
  }

  void _onData() {
    if (mounted) setState(() {});
  }

  Future<void> _openAddProduct() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddProductWizard()),
    );
    if (saved == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _logout() async {
    final yes = await showConfirmLogoutDialog(context);
    if (!yes || !mounted) return;
    _ds.clear();
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    if (_ds.home != null && !_ds.home!.isBos) {
      return OfflineGuard(child: KaryawanHomeScreen(onLogout: _logout));
    }

    return OfflineGuard(
      child: Scaffold(
        backgroundColor: UiColors.page,
        body: PageBg(
          child: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _tab,
              children: [
                _BerandaTab(
                  ds: _ds,
                  onTapUser: () => setState(() => _tab = 3),
                  onAddProduct: _openAddProduct,
                  onEditBusiness: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UsahaSayaScreen()),
                  ),
                  onSeeAll: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AllProductsScreen()),
                    );
                    _ds.load();
                  },
                ),
                ProdukTab(onAddProduct: _openAddProduct),
                const LaporanTab(),
                AkunTab(onLogout: _logout),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _BottomNav(
          index: _tab,
          onTap: (i) => setState(() => _tab = i),
        ),
      ),
    );
  }
}

// BERANDA (Bos)
class _BerandaTab extends StatelessWidget {
  final DataService ds;
  final VoidCallback onTapUser;
  final VoidCallback onAddProduct;
  final VoidCallback onEditBusiness;
  final VoidCallback onSeeAll;
  const _BerandaTab({
    required this.ds,
    required this.onTapUser,
    required this.onAddProduct,
    required this.onEditBusiness,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final h = ds.home;
    if (ds.loading && h == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.blue));
    }
    if (ds.error != null && h == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: UiColors.textMute),
              const SizedBox(height: 12),
              const Text('Gagal memuat data beranda',
                  style: TextStyle(fontSize: 15, color: AppColors.black)),
              const SizedBox(height: 14),
              AppButton(
                  text: 'Coba Lagi',
                  width: 140,
                  height: 40,
                  fontSize: 14,
                  onTap: ds.load),
            ],
          ),
        ),
      );
    }

    final username = h?.username ?? 'Pengguna';
    final bizName = h?.businessName ?? '-';
    final bizCat = h?.businessCategory ?? '-';
    final count = h?.productCount ?? 0;
    final pendapatan = h?.pendapatan ?? 0;
    final keuntungan = h?.keuntungan ?? 0;
    final recent = h?.recent;

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: ds.load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Nama Pengguna 
            GestureDetector(
              onTap: onTapUser,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                    ),
                    child: (h?.fotoUrl != null && h!.fotoUrl!.isNotEmpty)
                        ? Image.network(h.fotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.person_rounded,
                                size: 28,
                                color: AppColors.grey))
                        : const Icon(Icons.person_rounded,
                            size: 28, color: AppColors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Nama Usaha + Kategori + Edit
            GestureDetector(
              onTap: onEditBusiness,
              child: Container(
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
                      width: 50,
                      height: 50,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.blue, width: 1.4),
                      ),
                      child: (h?.businessLogo != null &&
                              h!.businessLogo!.isNotEmpty)
                          ? Image.network(h.businessLogo!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.storefront_rounded,
                                  size: 28,
                                  color: AppColors.darkYellow))
                          : const Icon(Icons.storefront_rounded,
                              size: 28, color: AppColors.darkYellow),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bizName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.black),
                          ),
                          Text(
                            bizCat,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13.5, color: AppColors.black),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.edit_rounded,
                          size: 22, color: AppColors.blue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Kartu Jumlah Produk + tombol "+ Tambahkan"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.blue, width: 1.3),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E6E6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_rounded,
                        size: 22, color: AppColors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$count',
                            style: const TextStyle(
                                fontSize: 17,
                                height: 1.15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black)),
                        const Text('Produk',
                            style: TextStyle(
                                fontSize: 12.5, color: UiColors.textMute)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onAddProduct,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded,
                              size: 18, color: AppColors.white),
                          SizedBox(width: 4),
                          Text('Tambahkan',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Kartu Biru Ringkasan Bisnis
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(0, 16, 16, 18),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                      color: UiColors.shadow,
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.darkYellow,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ringkasan Bisnis',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white)),
                            Text(Fmt.dateLong(DateTime.now()),
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFFD6E3FA))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _summaryBox('Pendapatan', Fmt.rp(pendapatan)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summaryBox('Keuntungan', Fmt.rp(keuntungan)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Aktivitas terakhir
            Row(
              children: [
                const Expanded(
                  child: SectionLabel('Aktivitas terakhir',
                      size: 16.5, weight: FontWeight.w600, markerHeight: 24),
                ),
                if (recent != null)
                  GestureDetector(
                    onTap: onSeeAll,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Text('Lihat semua',
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.blue)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Isi Aktivitas terakhir (maksimal 10 produk terbaru)
            if (h == null || h.recentList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: UiColors.shadow,
                        blurRadius: 12,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    const _HistoryIllustration(),
                    const SizedBox(height: 16),
                    const Text('Belum Ada Riwayat',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue)),
                    const SizedBox(height: 6),
                    const Text(
                      'Mulai tambah dan hitung HPP produk Anda\nuntuk melihat analisis laba di sini',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: UiColors.textMute),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      text: 'Tambah Produk',
                      width: 196,
                      height: 44,
                      fontSize: 15,
                      onTap: onAddProduct,
                    ),
                  ],
                ),
              )
            else
              for (final item in h.recentList.take(10))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProductCard(
                    product: item,
                    onTap: () async {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(summary: item)),
                      );
                      if (changed == true) ds.load();
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBox(String label, String val) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.blue)),
            const SizedBox(height: 4),
            Text(
              val,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black),
            ),
          ],
        ),
      );
}

class _HistoryIllustration extends StatelessWidget {
  const _HistoryIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      height: 102,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 86,
            decoration: BoxDecoration(
              color: UiColors.blueTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue, width: 2.5),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time_filled_rounded,
                    size: 32, color: AppColors.yellow),
                SizedBox(height: 6),
                SizedBox(
                  width: 34,
                  height: 3,
                  child: DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.blue)),
                ),
                SizedBox(height: 4),
                SizedBox(
                  width: 24,
                  height: 3,
                  child: DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.blue)),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: 4,
            child: Container(
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.blue, width: 2),
              ),
              child: const Icon(Icons.inventory_2_rounded,
                  size: 20, color: AppColors.blue),
            ),
          ),
          const Positioned(
            right: 6,
            top: 4,
            child:
                Icon(Icons.send_rounded, size: 22, color: AppColors.darkYellow),
          ),
        ],
      ),
    );
  }
}

// BOTTOM NAVIGATION BAR (4 tab untuk Bos)
class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = <(IconData, IconData, String)>[
      (Icons.home_rounded, Icons.home_outlined, 'Beranda'),
      (Icons.inventory_2_rounded, Icons.inventory_2_outlined, 'Produk'),
      (Icons.assessment_rounded, Icons.assessment_outlined, 'Laporan'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Akun'),
    ];
    return Container(
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
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          i == index ? items[i].$1 : items[i].$2,
                          size: 28,
                          color: AppColors.blue,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].$3,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                i == index ? FontWeight.w600 : FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ],
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
