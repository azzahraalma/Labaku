import 'dart:typed_data';

import '../../core/calc.dart';
import '../../services/data_service.dart';

class RecipeLine {
  final MaterialItem material;
  double qty;
  RecipeLine(this.material, this.qty);

  double get cost => qty * material.unitCost;
}

/// Seluruh data wizard "Tambah Produk" (6 langkah) + perhitungannya.
class ProductDraft {
  // Langkah 1 - Info dasar
  String nama = '';
  Uint8List? foto;
  CategoryItem? category; // null = "Lainnya"
  double jumlah = 0;
  UnitItem? unit;

  // Langkah 2 - Bahan baku
  final List<RecipeLine> recipe = [];

  // Langkah 3 - Tenaga kerja
  final List<LaborLine> labors = [];

  // Langkah 4 - Overhead
  bool overheadPersen = true;
  double? overheadPct;
  final List<OverheadItem> overheads = [];

  // Langkah 5 - Hasil & margin
  PriceMethod? method;
  double? markup;
  double? margin;
  double? manualUnit;

  // Langkah 6 - Pajak & harga final
  bool serviceOn = false;
  double servicePct = 5;
  bool taxOn = false;
  TaxType taxType = TaxType.ppn;
  double taxRate = 11;
  bool taxIncluded = false;
  bool roundOn = false;
  double roundStep = 1000;

  double get bahan => recipe.fold(0.0, (s, r) => s + r.cost);
  double get tenaga => labors.fold(0.0, (s, l) => s + l.total);
  double get overheadManual => overheads.fold(0.0, (s, o) => s + o.harga);

  CalcInput toInput() => CalcInput()
    ..bahanBaku = bahan
    ..tenagaKerja = tenaga
    ..overheadPersen = overheadPersen
    ..overheadPersenNilai = overheadPct
    ..overheadManual = overheadManual
    ..qty = jumlah
    ..method = method
    ..markup = markup ?? 0
    ..margin = margin ?? 0
    ..hargaManualUnit = manualUnit ?? 0
    ..serviceOn = serviceOn
    ..servicePersen = servicePct
    ..taxOn = taxOn
    ..taxType = taxType
    ..taxRate = taxRate
    ..taxIncluded = taxIncluded
    ..roundOn = roundOn
    ..roundStep = roundStep;

  CalcResult get result => PriceCalc.compute(toInput());

  // ---- validasi per langkah ----
  bool get step1Valid => nama.trim().isNotEmpty && jumlah > 0 && unit != null;
  bool get step2Valid => recipe.isNotEmpty;
  bool get step4Valid =>
      overheadPersen ? overheadPct != null : overheads.isNotEmpty;
  bool get step5Valid {
    if (jumlah <= 0 || method == null) return false;
    switch (method!) {
      case PriceMethod.markup:
        return (markup ?? 0) > 0;
      case PriceMethod.margin:
        return (margin ?? 0) > 0;
      case PriceMethod.manual:
        return (manualUnit ?? 0) > 0;
    }
  }

  Map<String, dynamic> toPayload({String? fotoUrl}) {
    final r = result;
    return {
      'nama': nama.trim(),
      'category_id': category?.id,
      'jumlah_produksi': jumlah,
      'unit_id': unit?.id,
      'foto_url': fotoUrl,
      'materials': [
        for (final l in recipe) {'material_id': l.material.id, 'qty': l.qty}
      ],
      'labors': [
        for (final l in labors)
          {
            'employee_id': l.employeeId,
            'metode': l.metode,
            'qty': l.qty,
            'tarif': l.tarif,
          }
      ],
      'overheads': overheadPersen
          ? <Map<String, dynamic>>[]
          : [
              for (final o in overheads) {'komponen': o.nama, 'harga': o.harga}
            ],
      'overhead_mode': overheadPersen ? 'persen' : 'manual',
      'overhead_persen': overheadPersen ? overheadPct : null,
      'margin_metode': method?.name,
      'margin_nilai': method == PriceMethod.markup
          ? markup
          : method == PriceMethod.margin
              ? margin
              : manualUnit,
      'service_charge_persen': serviceOn ? servicePct : 0,
      'pajak_jenis': taxOn ? taxType.id : null,
      'pajak_persen': taxOn ? taxRate : 0,
      'pajak_termasuk': taxOn && taxIncluded,
      'pembulatan': roundOn,
      'pembulatan_step': roundOn ? roundStep : null,
      'total_hpp': r.hpp,
      'harga_jual': r.hargaFinal,
      'laba_bersih': r.labaBersih,
      'harga_net': r.hargaNet,
      'margin_target': r.marginTarget,
      'hpp_bahan': r.bahan,
      'hpp_tenaga': r.tenaga,
      'hpp_overhead': r.overhead,
    };
  }
}
