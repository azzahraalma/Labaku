import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/ui_kit.dart';
import '../core/widgets.dart';
import '../services/data_service.dart';
import 'bahan_baku_screen.dart';
import 'product_detail_screen.dart';
import 'wizard/wizard_dialogs.dart';

/// Tab Produk (sesuai Tampilan halaman produk.jpg).
class ProdukTab extends StatefulWidget {
  final VoidCallback onAddProduct;
  const ProdukTab({super.key, required this.onAddProduct});

  @override
  State<ProdukTab> createState() => _ProdukTabState();
}

class _ProdukTabState extends State<ProdukTab> {
  final _ds = DataService.instance;
  final _search = TextEditingController();
  String _selectedCategory = 'Semua';
  List<ProductSummary> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ds.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    _ds.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final list = await _ds.listProducts();
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final cats = ['Semua', ..._ds.categories.map((c) => c.nama)];
    final filtered = _items.where((p) {
      final matchCat =
          _selectedCategory == 'Semua' || p.kategori == _selectedCategory;
      final matchQ = q.isEmpty || p.nama.toLowerCase().contains(q);
      return matchCat && matchQ;
    }).toList();

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.blue,
          onRefresh: () async {
            await _ds.load();
            await _refresh();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              const Text('Produk',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue)),
              const SizedBox(height: 14),

              // Cari Produk
              OutField(
                controller: _search,
                height: 46,
                radius: 10,
                borderColor: AppColors.blue,
                prefix: const Icon(Icons.search_rounded,
                    size: 22, color: AppColors.grey),
                hint: 'Cari Produk',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),

              // Pill Bahan Baku ("X Bahan >")
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BahanBakuScreen()),
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.blue, width: 1.1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_rounded,
                            size: 22, color: AppColors.grey),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_ds.materials.length}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.1,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.blue)),
                            const Text('Bahan',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.1,
                                    color: UiColors.textMute)),
                          ],
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: AppColors.black),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Filter kategori horizontal
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = cats[i];
                    final sel = c == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel ? AppColors.blue : AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: sel ? AppColors.blue : AppColors.grey),
                        ),
                        child: Text(c,
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
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
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.blue)),
                )
              else if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text('Belum ada produk',
                        style: TextStyle(
                            fontSize: 14.5, color: UiColors.textMute)),
                  ),
                )
              else
                for (final p in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _CompactProductCard(
                      product: p,
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(summary: p)),
                        );
                        if (changed == true) {
                          await _ds.load();
                          await _refresh();
                        }
                      },
                    ),
                  ),
            ],
          ),
        ),

        // Tombol melayang "+ Tambah Produk"
        Positioned(
          left: 0,
          right: 0,
          bottom: 18,
          child: Center(
            child: AppButton(
              text: '+  Tambah Produk',
              width: 196,
              height: 44,
              fontSize: 14.5,
              onTap: widget.onAddProduct,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactProductCard extends StatelessWidget {
  final ProductSummary product;
  final VoidCallback onTap;
  const _CompactProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final loss = p.labaBersih < 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.blue, width: 1.4),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCDCDC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(categoryIcon(p.kategori),
                      size: 26, color: AppColors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(p.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(Fmt.rp(p.hargaJual),
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.black)),
                        const Text('Harga Akhir',
                            style: TextStyle(
                                fontSize: 11.5, color: UiColors.textMute)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Keuntungan Aktual',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: loss ? AppColors.red : AppColors.blue,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Icon(
                              loss
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              size: 15,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.yellow,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(Fmt.pct(p.keuntunganAktual),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('Margin ${Fmt.pct(p.marginTarget)}',
                          style: const TextStyle(
                              fontSize: 11.5, color: UiColors.textMute)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HPP (Modal)',
                          style: TextStyle(
                              fontSize: 12, color: UiColors.textMute)),
                      Text(Fmt.rp(p.totalHpp),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Laba Bersih',
                        style: TextStyle(
                            fontSize: 12, color: UiColors.textMute)),
                    Text(Fmt.rp(p.labaBersih),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: loss ? AppColors.red : AppColors.blue)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
