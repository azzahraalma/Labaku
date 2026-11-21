import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/calc.dart';
import '../core/format.dart';
import '../core/ui_kit.dart';
import '../core/widgets.dart';
import '../services/data_service.dart';
import 'wizard/wizard_dialogs.dart';

/// Halaman "Bahan Baku" (dibuka dari pill "X Bahan >" di Tab Produk).
class BahanBakuScreen extends StatefulWidget {
  const BahanBakuScreen({super.key});

  @override
  State<BahanBakuScreen> createState() => _BahanBakuScreenState();
}

class _BahanBakuScreenState extends State<BahanBakuScreen> {
  final _ds = DataService.instance;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ds.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _ds.removeListener(_onUpdate);
    _search.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _openForm([MaterialItem? editing]) async {
    await showAppDialog<void>(
      context,
      (_) => _MaterialFormDialog(editing: editing),
      dismissible: true,
    );
  }

  Future<void> _delete(MaterialItem m) async {
    final yes = await showConfirmDeleteDialog(context);
    if (!yes || !mounted) return;
    try {
      await _ds.deleteMaterial(m.id);
    } catch (_) {
      if (mounted) showWarning(context, 'Gagal menghapus bahan', top: 72);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    final q = _search.text.trim().toLowerCase();
    final all = _ds.materials;
    final items = q.isEmpty
        ? all
        : all.where((m) => m.nama.toLowerCase().contains(q)).toList();
    final totalNilai = all.fold<double>(0, (s, m) => s + m.hargaBeli);

    return Scaffold(
      backgroundColor: UiColors.page,
      body: SafeArea(
        child: Column(
          children: [
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
                  const Text('Bahan Baku',
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: PageBg(
                child: Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                      children: [
                        // 2 Kartu ringkasan: Total Bahan & Total Nilai
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.blue, width: 1.2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.inventory_2_rounded,
                                        size: 24, color: AppColors.blue),
                                    const SizedBox(height: 4),
                                    const Text('Total Bahan',
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.black)),
                                    const SizedBox(height: 8),
                                    Text('${all.length}',
                                        style: const TextStyle(
                                            fontSize: 22,
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
                                  color: AppColors.blue,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.account_balance_rounded,
                                        size: 24, color: AppColors.white),
                                    const SizedBox(height: 4),
                                    const Text('Total Nilai',
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFFD6E3FA))),
                                    const SizedBox(height: 8),
                                    Text(
                                      Fmt.rp(totalNilai),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Search bar
                        OutField(
                          controller: _search,
                          height: 44,
                          radius: 10,
                          borderColor: AppColors.blue,
                          prefix: const Icon(Icons.search_rounded,
                              size: 22, color: AppColors.grey),
                          hint: 'Cari Bahan',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 6),
                        Text('${items.length} Bahan',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.blue)),
                        const SizedBox(height: 10),

                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: Text('Belum ada bahan baku',
                                  style: TextStyle(
                                      fontSize: 14.5,
                                      color: UiColors.textMute)),
                            ),
                          )
                        else
                          for (final m in items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 12, 14, 12),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.blue, width: 1.2),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const IconBadge(
                                            Icons.inventory_2_rounded,
                                            size: 50,
                                            bg: Color(0xFFC9D5EC),
                                            fg: AppColors.darkYellow),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(m.nama,
                                                  style: const TextStyle(
                                                      fontSize: 16.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.black)),
                                              Text(
                                                m.usedCount > 0
                                                    ? 'Digunakan ${m.usedCount} Produk'
                                                    : 'Belum Digunakan',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.blue),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _openForm(m),
                                          child: const Padding(
                                            padding: EdgeInsets.all(5),
                                            child: Icon(Icons.edit_rounded,
                                                size: 19,
                                                color: AppColors.blue),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _delete(m),
                                          child: const Padding(
                                            padding: EdgeInsets.all(5),
                                            child: Icon(
                                                Icons.delete_outline_rounded,
                                                size: 20,
                                                color: AppColors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(Fmt.rp(m.unitCost),
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.blue)),
                                          Text('per ${m.unit}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: UiColors.textMute)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),

                    // Tombol melayang "+ Tambah Bahan"
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 20,
                      child: Center(
                        child: AppButton(
                          text: '+  Tambah Bahan',
                          width: 190,
                          height: 44,
                          fontSize: 14.5,
                          onTap: () => _openForm(),
                        ),
                      ),
                    ),
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

class _MaterialFormDialog extends StatefulWidget {
  final MaterialItem? editing;
  const _MaterialFormDialog({this.editing});

  @override
  State<_MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends State<_MaterialFormDialog> {
  final _ds = DataService.instance;
  late final _name = TextEditingController(text: widget.editing?.nama ?? '');
  late final _price = TextEditingController(
      text: widget.editing == null ? '' : Fmt.number(widget.editing!.hargaBeli));
  late final _count = TextEditingController(
      text: widget.editing == null ? '' : Fmt.plain(widget.editing!.jumlahBeli));
  late final _pct = TextEditingController(
      text: (widget.editing?.penyusutan ?? 0) > 0
          ? Fmt.plain(widget.editing!.penyusutan)
          : '');
  final _gross = TextEditingController();
  final _net = TextEditingController();
  final _unitNew = TextEditingController();

  late String? _unitName = widget.editing?.unit ??
      (_ds.units.isNotEmpty ? _ds.units.first.nama : 'pcs');
  bool _addingUnit = false;
  late int _shrink = (widget.editing?.penyusutan ?? 0) > 0 ? 1 : 0;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _price, _count, _pct, _gross, _net, _unitNew]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _ok {
    if (_name.text.trim().isEmpty ||
        Fmt.parse(_price.text) <= 0 ||
        Fmt.parse(_count.text) <= 0) {
      return false;
    }
    if (_addingUnit && _unitNew.text.trim().isEmpty) return false;
    if (_shrink == 1 &&
        (_pct.text.trim().isEmpty || Fmt.parse(_pct.text) >= 100)) {
      return false;
    }
    if (_shrink == 2) {
      final k = Fmt.parse(_gross.text), b = Fmt.parse(_net.text);
      if (k <= 0 || b <= 0 || b > k) return false;
    }
    return true;
  }

  double get _shrinkPct {
    if (_shrink == 1) return Fmt.parse(_pct.text);
    if (_shrink == 2) {
      return MaterialCost.shrinkFromGross(
          Fmt.parse(_gross.text), Fmt.parse(_net.text));
    }
    return 0;
  }

  Future<void> _save() async {
    if (!_ok) {
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
        id: widget.editing?.id,
        nama: _name.text.trim(),
        harga: Fmt.parse(_price.text),
        jumlah: Fmt.parse(_count.text),
        unitId: unitId,
        penyusutan: _shrinkPct,
      );
      if (mounted) closeDialog(context);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        warnDialog(context, 'Gagal menyimpan bahan, coba lagi ya');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitNames = _ds.units.map((u) => u.nama).toList();
    return AppDialogCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DialogTitleRow(
              title: widget.editing == null ? 'Tambah Bahan' : 'Edit Bahan',
              onClose: () => closeDialog(context),
            ),
            const SizedBox(height: 14),
            const SectionLabel('Nama Bahan Baku', weight: FontWeight.w600),
            const SizedBox(height: 8),
            OutField(
              controller: _name,
              icon: Icons.inventory_2_outlined,
              hint: 'Contoh : Beras',
              height: 46,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            const SectionLabel('Harga Beli Total', weight: FontWeight.w600),
            const SizedBox(height: 8),
            OutField(
              controller: _price,
              icon: Icons.toll_outlined,
              hint: 'Contoh : 40.000',
              height: 46,
              keyboard: TextInputType.number,
              formatters: [ThousandsFormatter()],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: OutField(
                    controller: _count,
                    floatLabel: 'Jumlah Beli',
                    icon: Icons.scale_outlined,
                    hint: '10',
                    height: 46,
                    keyboard:
                        const TextInputType.numberWithOptions(decimal: true),
                    formatters: [DecimalFormatter()],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: UnitDropdown(
                    height: 46,
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
              const SizedBox(height: 18),
              OutField(
                controller: _unitNew,
                floatLabel: 'Nama Satuan',
                hint: 'Contoh: loyang, kaleng',
                height: 46,
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 16),
            const SectionLabel('Penyusutan', weight: FontWeight.w600),
            const SizedBox(height: 8),
            SegmentPill(
              labels: const ['Tidak ada', 'Persen', 'Sisa'],
              selected: _shrink,
              height: 40,
              onChanged: (i) => setState(() => _shrink = i),
            ),
            if (_shrink == 1) ...[
              const SizedBox(height: 18),
              OutField(
                controller: _pct,
                floatLabel: 'Presentase Penyusutan',
                hint: 'Contoh: 20',
                height: 44,
                keyboard:
                    const TextInputType.numberWithOptions(decimal: true),
                formatters: [DecimalFormatter(maxInt: 2)],
                suffix: const Text('%',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (_shrink == 2) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutField(
                      controller: _gross,
                      floatLabel: 'Jumlah Kotor',
                      hint: '200',
                      height: 44,
                      keyboard:
                          const TextInputType.numberWithOptions(decimal: true),
                      formatters: [DecimalFormatter()],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutField(
                      controller: _net,
                      floatLabel: 'Jumlah Bersih',
                      hint: '120',
                      height: 44,
                      keyboard:
                          const TextInputType.numberWithOptions(decimal: true),
                      formatters: [DecimalFormatter()],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            DialogButtons(
              ready: _ok,
              loading: _busy,
              onCancel: () => closeDialog(context),
              onConfirm: _save,
            ),
          ],
        ),
      ),
    );
  }
}
