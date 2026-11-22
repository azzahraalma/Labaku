import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/calc.dart';
import '../../core/format.dart';
import '../../core/ui_kit.dart';
import '../../core/widgets.dart';
import '../../services/data_service.dart';
import 'draft.dart';
import 'wizard_dialogs.dart';

enum _Stage { stock, create, qty }

class MaterialDialog extends StatefulWidget {
  final Set<String> excludeIds;
  final bool startOnCreate;
  const MaterialDialog(
      {super.key, this.excludeIds = const {}, this.startOnCreate = false});

  @override
  State<MaterialDialog> createState() => _MaterialDialogState();
}

class _MaterialDialogState extends State<MaterialDialog> {
  final _ds = DataService.instance;
  late _Stage _stage = widget.startOnCreate ? _Stage.create : _Stage.stock;

  // stok
  final _search = TextEditingController();
  MaterialItem? _picked;
  final _qty = TextEditingController();

  // form baru
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _count = TextEditingController();
  final _unitNew = TextEditingController();
  final _pct = TextEditingController();
  final _gross = TextEditingController();
  final _net = TextEditingController();
  String? _unitName;
  bool _addingUnit = false;
  int _shrink = 0; // 0 tidak ada, 1 persen, 2 sisa
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _unitName = _ds.units.isNotEmpty ? _ds.units.first.nama : 'pcs';
  }

  @override
  void dispose() {
    for (final c in [_search, _qty, _name, _price, _count, _unitNew, _pct, _gross, _net]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- validasi form baru ----------
  double get _priceV => Fmt.parse(_price.text);
  double get _countV => Fmt.parse(_count.text);

  bool get _shrinkOk {
    switch (_shrink) {
      case 1:
        return _pct.text.trim().isNotEmpty && Fmt.parse(_pct.text) < 100;
      case 2:
        final k = Fmt.parse(_gross.text), b = Fmt.parse(_net.text);
        return k > 0 && b > 0 && b <= k;
      default:
        return true;
    }
  }

  bool get _formOk =>
      _name.text.trim().isNotEmpty &&
      _priceV > 0 &&
      _countV > 0 &&
      (!_addingUnit || _unitNew.text.trim().isNotEmpty) &&
      _shrinkOk;

  double get _shrinkPct {
    switch (_shrink) {
      case 1:
        return Fmt.parse(_pct.text);
      case 2:
        return MaterialCost.shrinkFromGross(
            Fmt.parse(_gross.text), Fmt.parse(_net.text));
      default:
        return 0;
    }
  }

  Future<void> _saveNew() async {
    if (!_formOk) {
      warnDialog(context);
      return;
    }
    setState(() => _busy = true);
    try {
      String? unitId;
      if (_addingUnit) {
        final u = await _ds.addUnit(_unitNew.text.trim());
        unitId = u.id;
      } else {
        unitId = _ds.units.where((u) => u.nama == _unitName).firstOrNull?.id;
      }
      await _ds.saveMaterial(
        nama: _name.text.trim(),
        harga: _priceV,
        jumlah: _countV,
        unitId: unitId,
        penyusutan: _shrinkPct,
      );
      if (!mounted) return;
      _name.clear();
      _price.clear();
      _count.clear();
      _pct.clear();
      _gross.clear();
      _net.clear();
      _unitNew.clear();
      setState(() {
        _busy = false;
        _addingUnit = false;
        _shrink = 0;
        _stage = _Stage.stock;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      warnDialog(context, 'Gagal menyimpan bahan, coba lagi ya');
    }
  }

  // ---------- build ----------
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Dialog(
      backgroundColor: AppColors.white,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: h * 0.9),
        child: _stage == _Stage.qty
            ? SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                child: qtyBody(
                  material: _picked!,
                  controller: _qty,
                  qty: Fmt.parse(_qty.text),
                  onBack: () => setState(() => _stage = _Stage.stock),
                  onChanged: () => setState(() {}),
                  onSave: () {
                    final q = Fmt.parse(_qty.text);
                    if (q <= 0) {
                      warnDialog(context);
                      return;
                    }
                    closeDialog(context, RecipeLine(_picked!, q));
                  },
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 22, 20, 0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Pilih Bahan',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black)),
                        ),
                        GestureDetector(
                          onTap: () => closeDialog(context),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close_rounded,
                                size: 30, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  _tabs(),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                      child: _stage == _Stage.stock ? _stockTab() : _createTab(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _tabs() {
    Widget tab(IconData icon, String label, bool active, VoidCallback onTap) =>
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Icon(icon,
                    size: 28, color: active ? AppColors.blue : AppColors.blue),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color: AppColors.blue)),
                const SizedBox(height: 6),
                Container(
                    height: 3,
                    color: active ? const Color(0xFF1B3F86) : UiColors.blueTint),
              ],
            ),
          ),
        );
    return Row(
      children: [
        tab(Icons.inventory_2_rounded, 'Pilih Stok', _stage == _Stage.stock,
            () => setState(() => _stage = _Stage.stock)),
        tab(Icons.add_rounded, 'Tambah Baru', _stage == _Stage.create,
            () => setState(() => _stage = _Stage.create)),
      ],
    );
  }

  // ---------------------------------------------------------------- stok
  Widget _stockTab() {
    final q = _search.text.trim().toLowerCase();
    final items = _ds.materials
        .where((m) => !widget.excludeIds.contains(m.id))
        .where((m) => q.isEmpty || m.nama.toLowerCase().contains(q))
        .toList();
    final emptyStock = _ds.materials.where((m) => !widget.excludeIds.contains(m.id)).isEmpty;

    return Column(
      children: [
        OutField(
          controller: _search,
          hint: 'Cari Bahan...',
          height: 42,
          radius: 22,
          borderColor: AppColors.black,
          prefix: const Icon(Icons.search_rounded, size: 26, color: Colors.black),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        if (emptyStock)
          Column(
            children: [
              const SizedBox(height: 6),
              const IconBadge(Icons.inventory_2_outlined,
                  size: 78, bg: UiColors.blueTint, fg: AppColors.blue),
              const SizedBox(height: 18),
              const Text('Belum Ada Bahan Tersedia',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.blue)),
              const SizedBox(height: 2),
              const Text('Tambahkan bahan baku terlebih dahulu',
                  style: TextStyle(fontSize: 11.5, color: UiColors.textMute)),
              const SizedBox(height: 18),
              AppButton(
                text: '+  Buat Bahan Baru',
                width: 210,
                height: 36,
                fontSize: 13.5,
                onTap: () => setState(() => _stage = _Stage.create),
              ),
            ],
          )
        else if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Bahan tidak ditemukan',
                style: TextStyle(fontSize: 14, color: UiColors.textMute)),
          )
        else
          for (final m in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() {
                  _picked = m;
                  _qty.clear();
                  _stage = _Stage.qty;
                }),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.blue, width: 1),
                  ),
                  child: Row(
                    children: [
                      const IconBadge(Icons.inventory_2_rounded,
                          size: 48, bg: Color(0xFFC9D5EC), fg: AppColors.darkYellow),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.nama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 17,
                                    height: 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black)),
                            Text(unitPriceLabel(m),
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 22, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }

  // ---------------------------------------------------------------- tambah baru
  Widget _info() => const Padding(
        padding: EdgeInsets.fromLTRB(2, 6, 0, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_rounded, size: 16, color: AppColors.blue),
            SizedBox(width: 6),
            Expanded(
              child: Text('Dari total pembelian, berapa banyak yang bersih/bisa diolah?',
                  style: TextStyle(fontSize: 11.5, height: 1.3, color: UiColors.textMute)),
            ),
          ],
        ),
      );

  Widget _createTab() {
    final unitNames = _ds.units.map((u) => u.nama).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Nama Bahan Baku', weight: FontWeight.w600),
        const SizedBox(height: 8),
        OutField(
          controller: _name,
          icon: Icons.inventory_2_outlined,
          hint: 'Contoh : Beras',
          height: 50,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        const SectionLabel('Harga Beli Total', weight: FontWeight.w600),
        const SizedBox(height: 8),
        OutField(
          controller: _price,
          icon: Icons.toll_outlined,
          hint: 'Contoh : 40.000',
          height: 50,
          keyboard: TextInputType.number,
          formatters: [ThousandsFormatter()],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 11,
              child: OutField(
                controller: _count,
                floatLabel: 'Jumlah Beli',
                icon: Icons.scale_outlined,
                hint: 'Contoh: 10',
                height: 50,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                formatters: [DecimalFormatter()],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 10,
              child: UnitDropdown(
                height: 50,
                items: unitNames,
                value: _addingUnit ? 'Satuan baru' : _unitName,
                onSelected: (v) => setState(() {
                  _unitName = v;
                  _addingUnit = false;
                }),
                onAddUnit: () => setState(() => _addingUnit = true),
              ),
            ),
          ],
        ),
        if (_addingUnit) ...[
          const SizedBox(height: 22),
          OutField(
            controller: _unitNew,
            floatLabel: 'Nama Satuan',
            hint: 'Contoh: loyang, kaleng, box',
            height: 50,
            borderColor: AppColors.blue,
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 18),
        const SectionLabel('Penyusutan', weight: FontWeight.w600),
        _info(),
        SegmentPill(
          labels: const ['Tidak ada', 'Persen', 'Sisa'],
          selected: _shrink,
          height: 48,
          onChanged: (i) => setState(() => _shrink = i),
        ),
        if (_shrink == 1) ...[
          const SizedBox(height: 24),
          OutField(
            controller: _pct,
            floatLabel: 'Presentase Penyusutan',
            hint: 'Contoh: 20',
            height: 48,
            radius: 14,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
            formatters: [DecimalFormatter(maxInt: 2)],
            suffix: const Text('%',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
            onChanged: (_) => setState(() {}),
          ),
        ],
        if (_shrink == 2) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutField(
                  controller: _gross,
                  floatLabel: 'Jumlah Kotor',
                  hint: 'Contoh: 200',
                  height: 48,
                  radius: 14,
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                  formatters: [DecimalFormatter()],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: OutField(
                  controller: _net,
                  floatLabel: 'Jumlah Bersih',
                  hint: 'Contoh: 120',
                  height: 48,
                  radius: 14,
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                  formatters: [DecimalFormatter()],
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Batal',
                height: 38,
                fontSize: 15,
                style: BtnStyle.disabledSoft,
                onTap: () => closeDialog(context),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppButton(
                text: 'Simpan',
                height: 38,
                fontSize: 15,
                loading: _busy,
                style: _formOk ? BtnStyle.primary : BtnStyle.disabledSoft,
                onTap: _saveNew,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
