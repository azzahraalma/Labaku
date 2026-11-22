import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/calc.dart';
import '../../core/ui_kit.dart';
import '../../core/widgets.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import 'draft.dart';
import 'steps_1_to_3.dart';
import 'steps_4_to_6.dart';
import 'wizard_dialogs.dart';

class AddProductWizard extends StatefulWidget {
  final ProductDetail? editing;
  const AddProductWizard({super.key, this.editing});

  @override
  State<AddProductWizard> createState() => _AddProductWizardState();
}

class _AddProductWizardState extends State<AddProductWizard> {
  final _draft = ProductDraft();
  int _step = 1; // 1..6
  bool _showMinMatWarn = false;
  bool _saving = false;

  bool get _isEdit => widget.editing != null;

  static const _titles = [
    'Info Dasar',
    'Bahan Baku',
    'Tenaga Kerja',
    'Biaya Overhead',
    'Hasil & Margin',
    'Pajak & Harga Final',
  ];

  @override
  void initState() {
    super.initState();
    final ed = widget.editing;
    if (ed != null) _prefill(ed);
  }

  void _prefill(ProductDetail ed) {
    final ds = DataService.instance;
    final s = ed.summary;

    _draft.nama = s.nama;
    _draft.existingFotoUrl = s.fotoUrl;
    _draft.jumlah = s.jumlahProduksi;
    _draft.category =
        ds.categories.where((c) => c.id == s.categoryId).firstOrNull ??
            ds.categories.where((c) => c.nama == s.kategori).firstOrNull;
    _draft.unit = ds.units.where((u) => u.id == s.unitId).firstOrNull ??
        ds.units.where((u) => u.nama == s.unit).firstOrNull ??
        (ds.units.isNotEmpty ? ds.units.first : null);

    // Bahan baku
    for (final m in ed.materials) {
      final mid = m['material_id'] as String?;
      final found = mid == null
          ? ds.materials.where((x) => x.nama == m['nama']).firstOrNull
          : ds.materials.where((x) => x.id == mid).firstOrNull;
      final item = found ??
          MaterialItem(
            id: mid ?? '',
            nama: (m['nama'] as String?) ?? '',
            hargaBeli: (m['harga_beli'] as num?)?.toDouble() ?? 0,
            jumlahBeli: (m['jumlah_beli'] as num?)?.toDouble() ?? 1,
            unitId: null,
            unit: (m['unit'] as String?) ?? 'pcs',
            penyusutan: (m['penyusutan'] as num?)?.toDouble() ?? 0,
          );
      _draft.recipe
          .add(RecipeLine(item, (m['qty'] as num?)?.toDouble() ?? 1));
    }

    // Tenaga kerja
    final bosId = AuthService.instance.userId;
    final bosName = ds.home?.username;
    for (final l in ed.labors) {
      final nama = (l['nama'] as String?) ?? '';
      var eid = (l['employee_id'] as String?) ??
          ds.employees.where((x) => x.username == nama).firstOrNull?.id ??
          '';
      if (eid.isEmpty &&
          bosId != null &&
          bosName != null &&
          nama.trim() == bosName.trim()) {
        eid = bosId;
      }
      if (eid.isEmpty) continue;
      final isBosSelf = (bosId != null && eid == bosId) ||
          (bosName != null && nama.trim() == bosName.trim());
      _draft.labors.add(LaborLine(
        employeeId: eid,
        name: isBosSelf
            ? '${nama.isNotEmpty ? nama : (bosName ?? 'Pemilik')} (Saya)'
            : nama,
        metode: (l['metode'] as String?) ?? 'jam',
        qty: (l['qty'] as num?)?.toDouble() ?? 1,
        tarif: (l['tarif'] as num?)?.toDouble() ?? 0,
      ));
    }
    if ((bosId != null && _draft.labors.any((l) => l.employeeId == bosId)) ||
        _draft.labors.any((l) => l.name.endsWith('(Saya)'))) {
      _draft.selfWorker = true;
      _draft.selfIncludeCost = true;
    }

    // Overhead
    _draft.overheadPersen = s.overheadMode != 'manual';
    if (_draft.overheadPersen) {
      _draft.overheadPct = s.overheadPersen ?? 0;
    } else {
      for (final o in ed.overheads) {
        _draft.overheads.add(OverheadItem(
          (o['komponen'] as String?) ?? '',
          (o['harga'] as num?)?.toDouble() ?? 0,
        ));
      }
    }

    // Margin / Markup / Manual
    switch (s.marginMetode) {
      case 'markup':
        _draft.method = PriceMethod.markup;
        _draft.markup = s.marginNilai ?? 20;
        break;
      case 'manual':
        _draft.method = PriceMethod.manual;
        _draft.manualUnit = s.marginNilai ?? s.hargaNetPerUnit;
        break;
      default:
        _draft.method = PriceMethod.margin;
        _draft.margin = s.marginNilai ?? s.marginTarget;
    }

    // Pajak, Service Charge, Pembulatan
    _draft.serviceOn = s.hasService;
    _draft.servicePct = s.hasService ? s.servicePersen : 5;
    _draft.taxOn = s.hasTax;
    _draft.taxType = TaxType.byId(s.pajakJenis);
    _draft.taxRate = s.hasTax ? s.pajakPersen : _draft.taxType.defaultRate;
    _draft.taxIncluded = s.pajakTermasuk;
    _draft.roundOn = s.pembulatan;
    _draft.roundStep = s.pembulatanStep ?? 1000;
  }

  bool get _canNext {
    switch (_step) {
      case 1:
        return _draft.step1Valid;
      case 2:
        return _draft.step2Valid;
      case 3:
        return true;
      case 4:
        return _draft.step4Valid;
      case 5:
        return _draft.step5Valid;
      case 6:
        return true;
      default:
        return false;
    }
  }

  void _back() {
    if (_saving) return;
    if (_step > 1) {
      setState(() => _step--);
    } else {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _next() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();

    if (!_canNext) {
      if (_step == 2) {
        setState(() => _showMinMatWarn = true);
      } else {
        warnPage(context);
      }
      return;
    }

    if (_step < 6) {
      setState(() {
        _showMinMatWarn = false;
        _step++;
      });
      return;
    }

    // Langkah 6 -> Simpan / Update ke Supabase
    setState(() => _saving = true);
    try {
      String? fotoUrl = widget.editing?.summary.fotoUrl;
      if (_draft.foto != null) {
        fotoUrl = await DataService.instance.uploadProductPhoto(_draft.foto!);
      }
      final payload = _draft.toPayload(fotoUrl: fotoUrl);
      if (_isEdit) {
        await DataService.instance
            .updateProduct(widget.editing!.summary.id, payload);
      } else {
        await DataService.instance.saveProduct(payload);
      }
      if (!mounted) return;
      setState(() => _saving = false);
      await showResultDialog(
        context,
        title: _isEdit ? 'Produk Diperbarui' : 'Produk Berhasil Disimpan',
        message: _isEdit
            ? 'Perubahan analisis HPP & harga jual\nberhasil disimpan'
            : 'Analisis HPP & harga jual produkmu\nsudah tersimpan di beranda',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DataFailure catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      warnPage(
          context, e.message.isEmpty ? 'Gagal menyimpan produk' : e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      warnPage(context, 'Koneksi bermasalah, coba lagi ya');
    }
  }

  Widget _stepBody() {
    switch (_step) {
      case 1:
        return Step1InfoDasar(
            draft: _draft, onChanged: () => setState(() {}));
      case 2:
        return Step2BahanBaku(
          draft: _draft,
          showMinWarning: _showMinMatWarn,
          onChanged: () => setState(() {
            if (_draft.recipe.isNotEmpty) _showMinMatWarn = false;
          }),
        );
      case 3:
        return Step3TenagaKerja(
            draft: _draft, onChanged: () => setState(() {}));
      case 4:
        return Step4Overhead(
            draft: _draft, onChanged: () => setState(() {}));
      case 5:
        return Step5HasilMargin(
            draft: _draft, onChanged: () => setState(() {}));
      default:
        return Step6PajakFinal(
            draft: _draft, onChanged: () => setState(() {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return PopScope(
      canPop: _step == 1 && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 1 && !_saving) {
          setState(() => _step--);
        }
      },
      child: Scaffold(
        body: StepScaffold(
          title: _titles[_step - 1],
          step: _step,
          onBack: _back,
          body: _stepBody(),
          bottom: WizardBottomBar(
            onBack: _back,
            onNext: _next,
            nextEnabled: _canNext,
            nextText: _step == 6 ? 'Simpan' : 'Lanjut',
            nextArrow: _step < 6,
            loading: _saving,
          ),
        ),
      ),
    );
  }
}
