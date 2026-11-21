import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/ui_kit.dart';
import '../services/data_service.dart';

/// Kartu ringkasan produk (dipakai di Beranda "Aktivitas terakhir" dan "Semua Produk Kamu").
class ProductCard extends StatelessWidget {
  final ProductSummary product;
  final VoidCallback? onTap;
  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final tag = p.tambahanLabel;
    final loss = p.labaBersih < 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.blue, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Fmt.ago(p.createdAt),
                        style: const TextStyle(
                            fontSize: 12.5, color: UiColors.textMute),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Keuntungan Aktual',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.black)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: loss ? AppColors.red : AppColors.blue,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(
                            loss
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 16,
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
                          child: Text(
                            Fmt.pct(p.keuntunganAktual),
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Margin ${Fmt.pct(p.marginTarget)}',
                        style: const TextStyle(
                            fontSize: 12, color: UiColors.textMute)),
                  ],
                ),
              ],
            ),
            if (tag != null) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: UiColors.chipGrey,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tag,
                    style: const TextStyle(
                        fontSize: 12, color: UiColors.textMute)),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _metric('HPP (Modal)', Fmt.rp(p.totalHpp), Colors.black),
                ),
                Expanded(
                  child: _metric('Harga Jual', Fmt.rp(p.hargaJual), Colors.black,
                      align: CrossAxisAlignment.center),
                ),
                Expanded(
                  child: _metric(
                    'Laba Bersih',
                    Fmt.rp(p.labaBersih),
                    loss ? AppColors.red : AppColors.blue,
                    align: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
            if (p.hasService || p.hasTax || p.pembulatan) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Harga Jual Sebelum Pajak/Layanan: ${Fmt.rp(p.hargaNet)}',
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: UiColors.textMute),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String val, Color color,
      {CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12.5, color: UiColors.textMute)),
        const SizedBox(height: 2),
        Text(
          val,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 14.5, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
