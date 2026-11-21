import 'package:flutter_test/flutter_test.dart';
import 'package:labaku/core/calc.dart';

void main() {
  CalcInput base() => CalcInput()
    ..bahanBaku = 132000
    ..tenagaKerja = 30000
    ..overheadPersen = true
    ..overheadPersenNilai = 20
    ..qty = 62;

  test('penyusutan: harga efektif & sisa', () {
    expect(MaterialCost.unitCost(hargaBeli: 50000, jumlahBeli: 1), 50000);
    expect(MaterialCost.unitCost(hargaBeli: 50000, jumlahBeli: 1, penyusutanPersen: 20),
        closeTo(62500, 1e-6));
    expect(MaterialCost.shrinkFromGross(200, 120), closeTo(40, 1e-9));
  });

  test('overhead persen dari basis bahan + tenaga', () {
    final r = PriceCalc.compute(base());
    expect(r.overhead, closeTo(32400, 1e-6)); // 20% x 162.000
    expect(r.hpp, closeTo(194400, 1e-6));
  });

  test('markup vs margin', () {
    final i = CalcInput()
      ..bahanBaku = 132000
      ..overheadPersen = false
      ..overheadManual = 13200
      ..qty = 62;
    expect(PriceCalc.compute(i).hpp, closeTo(145200, 1e-6));
    i
      ..method = PriceMethod.margin
      ..margin = 25;
    final m = PriceCalc.compute(i);
    expect(m.hargaDasar, closeTo(193600, 1e-6)); // 145.200 / 0,75
    expect(m.labaDasar, closeTo(48400, 1e-6));
    expect(m.marginTarget, closeTo(25, 1e-9));
    i
      ..method = PriceMethod.markup
      ..markup = 25;
    final k = PriceCalc.compute(i);
    expect(k.hargaDasar, closeTo(181500, 1e-6));
    expect(k.marginTarget, closeTo(20, 1e-9)); // markup 25% = margin 20%
  });

  test('service 5%, pajak 11% berlipat, pembulatan per unit', () {
    final i = CalcInput()
      ..bahanBaku = 311990 // HPP bebas
      ..overheadPersen = false
      ..qty = 62
      ..method = PriceMethod.manual
      ..hargaManualUnit = 389980 / 62;
    var r = PriceCalc.compute(i);
    expect(r.hargaDasar, closeTo(389980, 1e-6));

    i
      ..serviceOn = true
      ..servicePersen = 5;
    r = PriceCalc.compute(i);
    expect(r.hargaFinal, closeTo(409479, 1e-6));

    i
      ..serviceOn = false
      ..taxOn = true
      ..taxRate = 11;
    r = PriceCalc.compute(i);
    expect(r.hargaFinal, closeTo(432877.8, 1e-6));

    i
      ..taxOn = false
      ..roundOn = true
      ..roundStep = 1000;
    r = PriceCalc.compute(i);
    expect(r.perUnitBulat, 7000); // 6.290 -> 7.000
    expect(r.hargaFinal, 434000); // 7.000 x 62
  });

  test('pajak sudah termasuk: harga tetap, laba dihitung dari harga bersih', () {
    final i = CalcInput()
      ..bahanBaku = 100000
      ..overheadPersen = false
      ..qty = 10
      ..method = PriceMethod.manual
      ..hargaManualUnit = 22200
      ..taxOn = true
      ..taxRate = 11
      ..taxIncluded = true;
    final r = PriceCalc.compute(i);
    expect(r.hargaFinal, closeTo(222000, 1e-6));
    expect(r.hargaNet, closeTo(200000, 1e-6));
    expect(r.labaBersih, closeTo(100000, 1e-6));
  });

  test('ceilTo tidak naik karena error floating point', () {
    expect(PriceCalc.ceilTo(6000.0000000001, 1000), 6000);
    expect(PriceCalc.ceilTo(6001, 1000), 7000);
    expect(PriceCalc.ceilTo(7331, 1000), 8000);
  });
}
