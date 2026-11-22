import 'dart:math' as math;

class MaterialCost {
  /// Harga efektif per satuan setelah memperhitungkan penyusutan.
  static double unitCost({
    required double hargaBeli,
    required double jumlahBeli,
    double penyusutanPersen = 0,
  }) {
    if (jumlahBeli <= 0 || hargaBeli < 0) return 0;
    final yieldRate = 1 - (penyusutanPersen.clamp(0, 99.99)) / 100;
    return hargaBeli / (jumlahBeli * yieldRate);
  }

  /// Penyusutan (%) dari input "Sisa": jumlah kotor & jumlah bersih.
  static double shrinkFromGross(double kotor, double bersih) {
    if (kotor <= 0 || bersih <= 0 || bersih > kotor) return 0;
    return (kotor - bersih) / kotor * 100;
  }
}

class LaborLine {
  final String employeeId;
  final String name;
  final String metode; // jam | hari | output | manual
  final double qty; // jam / hari / output (manual = 1)
  final double tarif; // tarif per satuan (manual = total biaya)
  const LaborLine({
    required this.employeeId,
    required this.name,
    required this.metode,
    required this.qty,
    required this.tarif,
  });

  double get total => qty * tarif;

  String get metodeLabel {
    switch (metode) {
      case 'jam':
        return 'Tarif per Jam';
      case 'hari':
        return 'Tarif per Hari';
      case 'output':
        return 'Tarif per Output';
      default:
        return 'Input Manual';
    }
  }
}

class OverheadItem {
  final String nama;
  final double harga;
  const OverheadItem(this.nama, this.harga);
}

enum PriceMethod { markup, margin, manual }

class TaxType {
  final String id; // ppn | pb1 | pph
  final String nama;
  final double defaultRate;
  const TaxType(this.id, this.nama, this.defaultRate);

  static const ppn = TaxType('ppn', 'PPN', 11);
  static const pb1 = TaxType('pb1', 'PB1', 10);
  static const pph = TaxType('pph', 'PPh Final', 0.5);
  static const all = [ppn, pb1, pph];
  static TaxType byId(String? id) =>
      all.firstWhere((t) => t.id == id, orElse: () => ppn);
}

/// Input kalkulasi (diisi dari wizard).
class CalcInput {
  double bahanBaku = 0;
  double tenagaKerja = 0;

  bool overheadPersen = true;
  double? overheadPersenNilai; // null = belum diisi
  double overheadManual = 0;

  double qty = 0; // total produksi
  PriceMethod? method;
  double markup = 0; // %
  double margin = 0; // %
  double hargaManualUnit = 0;

  bool serviceOn = false;
  double servicePersen = 0;

  bool taxOn = false;
  TaxType taxType = TaxType.ppn;
  double taxRate = 11;
  bool taxIncluded = false;

  bool roundOn = false;
  double roundStep = 1000;
}

class CalcResult {
  final double bahan;
  final double tenaga;
  final double overhead;
  final double hpp;
  final double basis;

  /// Harga jual sebelum service/pajak/pembulatan (total produksi).
  final double hargaDasar;
  final double hppPerUnit;
  final double hargaDasarPerUnit;
  final double labaDasar;

  /// Margin target (laba / harga dasar) dalam %.
  final double marginTarget;

  /// Setelah service charge & pajak, sebelum pembulatan.
  final double totalSebelumBulat;
  final double perUnitSebelumBulat;
  final double perUnitBulat;

  /// Harga final yang dibayar pelanggan (total produksi).
  final double hargaFinal;
  final double hargaFinalPerUnit;

  /// Harga bersih di luar pajak & layanan.
  final double hargaNet;
  final double labaBersih;
  final double marginAktual;

  const CalcResult({
    required this.bahan,
    required this.tenaga,
    required this.overhead,
    required this.hpp,
    required this.basis,
    required this.hargaDasar,
    required this.hppPerUnit,
    required this.hargaDasarPerUnit,
    required this.labaDasar,
    required this.marginTarget,
    required this.totalSebelumBulat,
    required this.perUnitSebelumBulat,
    required this.perUnitBulat,
    required this.hargaFinal,
    required this.hargaFinalPerUnit,
    required this.hargaNet,
    required this.labaBersih,
    required this.marginAktual,
  });

  double get selisihBulatPerUnit => perUnitBulat - perUnitSebelumBulat;
}

class PriceCalc {
  static const maxPercent = 95.0;

  static double _share(double part, double total) =>
      total <= 0 ? 0 : part / total * 100;

  /// Persentase komponen terhadap total HPP (untuk bar rincian biaya).
  static double share(double part, double hpp) => _share(part, hpp);

  static double ceilTo(double v, double step) {
    if (step <= 0) return v;
    // toleransi floating point: 6290.0000000001 tidak boleh naik ke 7000
    final q = v / step;
    final r = q.roundToDouble();
    final n = (q - r).abs() < 1e-9 ? r : q.ceilToDouble();
    return n * step;
  }

  static CalcResult compute(CalcInput i) {
    final bahan = math.max(0.0, i.bahanBaku);
    final tenaga = math.max(0.0, i.tenagaKerja);
    final basis = bahan + tenaga;

    final overhead = i.overheadPersen
        ? basis * ((i.overheadPersenNilai ?? 0).clamp(0, 100)) / 100
        : math.max(0.0, i.overheadManual);

    final hpp = basis + overhead;
    final qty = i.qty > 0 ? i.qty : 0.0;

    double dasar;
    switch (i.method) {
      case PriceMethod.markup:
        dasar = hpp * (1 + i.markup.clamp(0, maxPercent) / 100);
        break;
      case PriceMethod.margin:
        dasar = hpp / (1 - i.margin.clamp(0, maxPercent) / 100);
        break;
      case PriceMethod.manual:
        dasar = math.max(0.0, i.hargaManualUnit) * qty;
        break;
      case null:
        dasar = hpp;
        break;
    }

    final svc = i.serviceOn ? i.servicePersen.clamp(0, 100) / 100 : 0.0;
    final tax = i.taxOn ? i.taxRate.clamp(0, 100) / 100 : 0.0;
    final factor = (1 + svc) * (1 + tax);

    // Service charge selalu ditambahkan di atas harga. Pajak ditambahkan di atas
    // harga (belum termasuk) atau dianggap sudah ada di dalam harga (sudah termasuk).
    final taxOnTop = i.taxOn && !i.taxIncluded;
    final totalSebelumBulat = dasar * (1 + svc) * (taxOnTop ? (1 + tax) : 1);
    final perUnitSebelum = qty > 0 ? totalSebelumBulat / qty : 0.0;

    double perUnitBulat = perUnitSebelum;
    double hargaFinal = totalSebelumBulat;
    if (i.roundOn && qty > 0) {
      perUnitBulat = ceilTo(perUnitSebelum, i.roundStep);
      hargaFinal = perUnitBulat * qty;
    }

    final net = hargaFinal / factor;
    final laba = net - hpp;

    return CalcResult(
      bahan: bahan,
      tenaga: tenaga,
      overhead: overhead,
      hpp: hpp,
      basis: basis,
      hargaDasar: dasar,
      hppPerUnit: qty > 0 ? hpp / qty : 0,
      hargaDasarPerUnit: qty > 0 ? dasar / qty : 0,
      labaDasar: dasar - hpp,
      marginTarget: dasar > 0 ? (dasar - hpp) / dasar * 100 : 0,
      totalSebelumBulat: totalSebelumBulat,
      perUnitSebelumBulat: perUnitSebelum,
      perUnitBulat: perUnitBulat,
      hargaFinal: hargaFinal,
      hargaFinalPerUnit: qty > 0 ? hargaFinal / qty : 0,
      hargaNet: net,
      labaBersih: laba,
      marginAktual: net > 0 ? laba / net * 100 : 0,
    );
  }
}
