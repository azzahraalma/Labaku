import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../core/ui_kit.dart';
import '../../core/widgets.dart';
import '../../core/calc.dart';
import '../../services/data_service.dart';

const kWarnTop = 72.0; // toast di atas halaman
const kWarnTopDialog = 113.0; // toast di atas dialog
const kIncomplete = 'Lengkapin dulu informasinya ya!';

DataService get _ds => DataService.instance;

void warnPage(BuildContext c, [String m = kIncomplete]) =>
    showWarning(c, m, top: kWarnTop);
void warnDialog(BuildContext c, [String m = kIncomplete]) =>
    showWarning(c, m, top: kWarnTopDialog);

void closeDialog(BuildContext c, [Object? v]) =>
    Navigator.of(c, rootNavigator: true).pop(v);

/// Tombol dialog: Batal (outline) + Simpan/Lanjut.
class DialogButtons extends StatelessWidget {
  final String confirmText;
  final bool ready;
  final bool loading;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final MainAxisAlignment alignment;
  final double cancelWidth;
  final double confirmWidth;
  const DialogButtons({
    super.key,
    this.confirmText = 'Simpan',
    required this.ready,
    this.loading = false,
    required this.onCancel,
    required this.onConfirm,
    this.alignment = MainAxisAlignment.center,
    this.cancelWidth = 100,
    this.confirmWidth = 112,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        AppButton(
          text: 'Batal',
          width: cancelWidth,
          height: 38,
          fontSize: 16,
          style: BtnStyle.outline,
          onTap: onCancel,
        ),
        const SizedBox(width: 16),
        AppButton(
          text: confirmText,
          width: confirmWidth,
          height: 38,
          fontSize: 16,
          loading: loading,
          style: ready ? BtnStyle.primary : BtnStyle.disabledSoft,
          onTap: onConfirm,
        ),
      ],
    );
  }
}

// Pilih Kategori  (+ Kategori Lain)
IconData categoryIcon(String name) {
  switch (name.toLowerCase()) {
    case 'makanan':
      return Icons.restaurant_rounded;
    case 'minuman':
      return Icons.local_cafe_rounded;
    case 'pakaian':
      return Icons.checkroom_rounded;
    case 'elektronik':
      return Icons.electrical_services_rounded;
    default:
      return Icons.category_rounded;
  }
}

class CategoryPickDialog extends StatelessWidget {
  const CategoryPickDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final cats = _ds.categories;
    return AppDialogCard(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DialogTitleRow(
                title: 'Pilih Kategori', onClose: () => closeDialog(context)),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (_, cs) {
              final w = (cs.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in cats)
                    GestureDetector(
                      onTap: () => closeDialog(context, c),
                      child: Container(
                        width: w,
                        height: w * 1.0,
                        decoration: BoxDecoration(
                            color: AppColors.blue,
                            borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: const BoxDecoration(
                                  color: AppColors.white, shape: BoxShape.circle),
                              child: Icon(categoryIcon(c.nama),
                                  size: 30, color: AppColors.blue),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(c.nama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () async {
                final r = await showAppDialog<CategoryItem>(
                    context, (_) => const CustomCategoryDialogP());
                if (r != null && context.mounted) closeDialog(context, r);
              },
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 1)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 18, color: AppColors.black),
                    SizedBox(width: 6),
                    Text('Tambah Kategori',
                        style: TextStyle(fontSize: 13.5, color: AppColors.black)),
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

class CustomCategoryDialogP extends StatefulWidget {
  const CustomCategoryDialogP({super.key});

  @override
  State<CustomCategoryDialogP> createState() => _CustomCategoryDialogPState();
}

class _CustomCategoryDialogPState extends State<CustomCategoryDialogP> {
  final _c = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _ok => _c.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_ok) {
      warnDialog(context);
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await _ds.addCategory(_c.text.trim());
      if (mounted) closeDialog(context, r);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        warnDialog(context, 'Koneksi bermasalah, coba lagi ya');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogCard(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DialogTitleRow(
              title: 'Kategori Lain', onClose: () => closeDialog(context)),
          const SizedBox(height: 12),
          const Text('Masukkan nama kategori baru',
              style: TextStyle(fontSize: 12.5, color: Colors.black)),
          const SizedBox(height: 14),
          OutField(
            controller: _c,
            icon: Icons.inventory_2_outlined,
            hint: 'Contoh : Aksesoris',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 22),
          DialogButtons(
            ready: _ok,
            loading: _busy,
            onCancel: () => closeDialog(context),
            onConfirm: _save,
          ),
        ],
      ),
    );
  }
}

// Satuan Lain
class UnitAddDialog extends StatefulWidget {
  const UnitAddDialog({super.key});

  @override
  State<UnitAddDialog> createState() => _UnitAddDialogState();
}

class _UnitAddDialogState extends State<UnitAddDialog> {
  final _c = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _ok => _c.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_ok) {
      warnDialog(context);
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await _ds.addUnit(_c.text.trim());
      if (mounted) closeDialog(context, r);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        warnDialog(context, 'Koneksi bermasalah, coba lagi ya');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogCard(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DialogTitleRow(
              title: 'Satuan Lain', onClose: () => closeDialog(context)),
          const SizedBox(height: 12),
          const Text('Masukkan nama satuan baru',
              style: TextStyle(fontSize: 12.5, color: Colors.black)),
          const SizedBox(height: 14),
          OutField(
            controller: _c,
            icon: Icons.inventory_2_outlined,
            hint: 'Contoh : Loyang',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 22),
          DialogButtons(
            ready: _ok,
            loading: _busy,
            onCancel: () => closeDialog(context),
            onConfirm: _save,
          ),
        ],
      ),
    );
  }
}

// Tambah Item Overhead (Biaya Rutin & Penyusutan Alat/Mesin)
class OverheadItemDialog extends StatefulWidget {
  final OverheadItem? initial;
  final double productQty;
  final String productUnit;
  const OverheadItemDialog({
    super.key,
    this.initial,
    this.productQty = 1,
    this.productUnit = 'pcs',
  });

  @override
  State<OverheadItemDialog> createState() => _OverheadItemDialogState();
}

class _OverheadItemDialogState extends State<OverheadItemDialog> {
  late final _n = TextEditingController(text: widget.initial?.nama);
  late final _h = TextEditingController(
      text: widget.initial == null ? '' : Fmt.number(widget.initial!.harga));
  final _umur = TextEditingController();
  bool _isAsset = false; // false = Biaya Rutin, true = Alat/Mesin (Penyusutan)
  String _rutinUnit = 'hari'; // 'unit' | 'hari' | 'minggu' | 'bulan' | 'tahun'
  String _umurUnit = 'bulan'; // 'unit' | 'hari' | 'bulan' | 'tahun'

  @override
  void dispose() {
    _n.dispose();
    _h.dispose();
    _umur.dispose();
    super.dispose();
  }

  double get _qty => widget.productQty > 0 ? widget.productQty : 1;
  String get _unitLabel =>
      widget.productUnit.trim().isEmpty ? 'pcs' : widget.productUnit.trim();

  double get _umurValue => Fmt.parse(_umur.text);

  double get _biayaFinal {
    final harga = Fmt.parse(_h.text);
    if (harga <= 0) return 0;
    if (!_isAsset) {
      switch (_rutinUnit) {
        case 'unit':
          return (harga * _qty).ceilToDouble();
        case 'minggu':
          return (harga / 7).ceilToDouble();
        case 'bulan':
          return (harga / 30).ceilToDouble();
        case 'tahun':
          return (harga / 365).ceilToDouble();
        default: // hari (langsung untuk produksi ini)
          return harga;
      }
    }
    final u = _umurValue;
    if (u <= 0) return 0;
    switch (_umurUnit) {
      case 'unit':
        return ((harga / u) * _qty).ceilToDouble();
      case 'tahun':
        return (harga / (u * 365)).ceilToDouble();
      case 'bulan':
        return (harga / (u * 30)).ceilToDouble();
      default: // hari
        return (harga / u).ceilToDouble();
    }
  }

  bool get _ok {
    if (_n.text.trim().isEmpty) return false;
    if (!_isAsset) return Fmt.parse(_h.text) > 0;
    return Fmt.parse(_h.text) > 0 && _umurValue > 0;
  }

  void _save() {
    if (!_ok) {
      warnDialog(context);
      return;
    }
    final rawName = _n.text.trim();
    final name = _isAsset && !rawName.toLowerCase().contains('penyusutan')
        ? 'Penyusutan $rawName'
        : rawName;
    closeDialog(context, OverheadItem(name, _biayaFinal));
  }

  Widget _modePill(bool asset, String label) {
    final sel = _isAsset == asset;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isAsset = asset),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? AppColors.blue : UiColors.blueTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: sel ? AppColors.white : AppColors.blue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _choiceChip(String label, bool sel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? AppColors.blue : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blue),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: sel ? AppColors.white : AppColors.blue,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitName = _unitLabel;
    return AppDialogCard(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DialogTitleRow(
                title: 'Tambah Item', onClose: () => closeDialog(context)),
            const SizedBox(height: 14),
            Row(
              children: [
                _modePill(false, 'Biaya Rutin'),
                const SizedBox(width: 8),
                _modePill(true, 'Alat / Mesin'),
              ],
            ),
            const SizedBox(height: 16),
            OutField(
              controller: _n,
              floatLabel:
                  _isAsset ? 'Nama Alat / Mesin' : 'Nama Item Overhead',
              icon: _isAsset
                  ? Icons.precision_manufacturing_outlined
                  : Icons.inventory_2_rounded,
              hint: _isAsset ? 'Contoh: Mesin Press Es Teh' : 'Contoh: Listrik',
              height: 50,
              borderColor: AppColors.grey,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            OutField(
              controller: _h,
              floatLabel: _isAsset ? 'Harga Beli Alat' : null,
              prefix: const Text('Rp',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue)),
              hint: _isAsset ? 'Contoh: 700.000' : 'Jumlah Biaya',
              height: 50,
              borderColor: AppColors.grey,
              keyboard: TextInputType.number,
              formatters: [ThousandsFormatter()],
              onChanged: (_) => setState(() {}),
            ),
            if (!_isAsset) ...[
              const SizedBox(height: 10),
              const Text('Satuan Biaya:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _choiceChip('per $unitName', _rutinUnit == 'unit',
                      () => setState(() => _rutinUnit = 'unit')),
                  _choiceChip('per Hari', _rutinUnit == 'hari',
                      () => setState(() => _rutinUnit = 'hari')),
                  _choiceChip('per Minggu', _rutinUnit == 'minggu',
                      () => setState(() => _rutinUnit = 'minggu')),
                  _choiceChip('per Bulan', _rutinUnit == 'bulan',
                      () => setState(() => _rutinUnit = 'bulan')),
                  _choiceChip('per Tahun', _rutinUnit == 'tahun',
                      () => setState(() => _rutinUnit = 'tahun')),
                ],
              ),
              if (Fmt.parse(_h.text) > 0) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: UiColors.blueTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _rutinUnit == 'unit'
                              ? 'Total (${Fmt.plain(_qty)} $unitName):'
                              : 'Biaya masuk modal / hari:',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.black),
                        ),
                      ),
                      Text(
                        Fmt.rp(_biayaFinal),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 16),
              OutField(
                controller: _umur,
                floatLabel: _umurUnit == 'unit'
                    ? 'Perkiraan Kapasitas Pakai ($unitName)'
                    : 'Perkiraan Lama Pakai',
                icon: Icons.schedule_rounded,
                hint: _umurUnit == 'unit'
                    ? 'Contoh: 10000'
                    : _umurUnit == 'tahun'
                        ? 'Contoh: 2'
                        : _umurUnit == 'bulan'
                            ? 'Contoh: 24'
                            : 'Contoh: 700',
                height: 50,
                borderColor: AppColors.grey,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                formatters: [DecimalFormatter()],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _choiceChip(unitName, _umurUnit == 'unit',
                      () => setState(() => _umurUnit = 'unit')),
                  _choiceChip('Hari', _umurUnit == 'hari',
                      () => setState(() => _umurUnit = 'hari')),
                  _choiceChip('Bulan', _umurUnit == 'bulan',
                      () => setState(() => _umurUnit = 'bulan')),
                  _choiceChip('Tahun', _umurUnit == 'tahun',
                      () => setState(() => _umurUnit = 'tahun')),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: UiColors.blueTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _umurUnit == 'unit'
                                ? 'Penyusutan (${Fmt.plain(_qty)} $unitName):'
                                : 'Biaya penyusutan / hari:',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.black),
                          ),
                        ),
                        Text(
                          Fmt.rp(_biayaFinal),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.info_rounded,
                              size: 14, color: AppColors.blue),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Alat sekali beli dipakai berkali-kali, jadi yang masuk ke modal hanya biaya penyusutannya agar tidak bikin rugi.',
                            style: TextStyle(
                                fontSize: 11,
                                height: 1.35,
                                color: UiColors.textMute),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Batal',
                    height: 40,
                    fontSize: 15,
                    style: BtnStyle.outline,
                    onTap: () => closeDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Simpan',
                    height: 40,
                    fontSize: 15,
                    style: _ok ? BtnStyle.primary : BtnStyle.disabledSoft,
                    onTap: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// edit bahan
class QtyDialog extends StatefulWidget {
  final MaterialItem material;
  final double? initial;
  final bool backArrow;
  const QtyDialog(
      {super.key, required this.material, this.initial, this.backArrow = false});

  @override
  State<QtyDialog> createState() => _QtyDialogState();
}

class _QtyDialogState extends State<QtyDialog> {
  late final _q = TextEditingController(
      text: widget.initial == null ? '' : Fmt.plain(widget.initial!));

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  double get _qty => Fmt.parse(_q.text);

  void _save() {
    if (_qty <= 0) {
      warnDialog(context);
      return;
    }
    closeDialog(context, _qty);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.material;
    return AppDialogCard(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: _QtyBody(
        material: m,
        controller: _q,
        qty: _qty,
        onBack: () => closeDialog(context),
        onSave: _save,
        onChanged: () => setState(() {}),
        saveText: 'Simpan',
      ),
    );
  }
}

class _QtyBody extends StatelessWidget {
  final MaterialItem material;
  final TextEditingController controller;
  final double qty;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onChanged;
  final String saveText;
  const _QtyBody({
    required this.material,
    required this.controller,
    required this.qty,
    required this.onBack,
    required this.onSave,
    required this.onChanged,
    required this.saveText,
  });

  @override
  Widget build(BuildContext context) {
    final m = material;
    final cost = qty * m.unitCost;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(right: 14, top: 4, bottom: 4),
                child: Icon(Icons.arrow_back_rounded,
                    size: 28, color: AppColors.black),
              ),
            ),
            const Text('Atur Jumlah',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.black)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const IconBadge(Icons.inventory_2_rounded,
                size: 56, bg: Color(0xFFC9D5EC), fg: AppColors.blue),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 22, height: 1.2, color: AppColors.black)),
                  Text('${Fmt.rp(m.unitCost)} / ${m.unit}',
                      style: const TextStyle(
                          fontSize: 14.5, color: UiColors.textMute)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        OutField(
          controller: controller,
          floatLabel: 'Jumlah Dibutuhkan',
          hint: '0',
          height: 52,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          formatters: [DecimalFormatter()],
          textStyle: const TextStyle(fontSize: 20, color: Colors.black),
          suffix: Text(m.unit,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.blue)),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          decoration: BoxDecoration(
              color: UiColors.blueTint, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Perkiraan Biaya',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.blue)),
              const SizedBox(height: 2),
              Text('${Fmt.plain(qty)} ${m.unit} x ${Fmt.rp(m.unitCost)}',
                  style: const TextStyle(fontSize: 13, color: Colors.black)),
              const SizedBox(height: 4),
              Text(Fmt.rp(cost),
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.black)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: AppButton(
            text: saveText,
            width: 220,
            height: 46,
            fontSize: 15.5,
            style: qty > 0 ? BtnStyle.primary : BtnStyle.disabledSoft,
            onTap: onSave,
          ),
        ),
      ],
    );
  }
}

/// Dipakai MaterialDialog (bahan baru dipilih dari stok) agar tampilan sama.
Widget qtyBody({
  required MaterialItem material,
  required TextEditingController controller,
  required double qty,
  required VoidCallback onBack,
  required VoidCallback onSave,
  required VoidCallback onChanged,
}) =>
    _QtyBody(
      material: material,
      controller: controller,
      qty: qty,
      onBack: onBack,
      onSave: onSave,
      onChanged: onChanged,
      saveText: 'Tambahkan ke Resep',
    );

extension IterableX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

// util kecil
String unitPriceLabel(MaterialItem m) => '${Fmt.rp(m.unitCost)} / ${m.unit}';
bool isDigitsOnly(String s) => RegExp(r'^\d+$').hasMatch(s);
void haptic() => HapticFeedback.selectionClick();
double pctClamp(double v) => v.clamp(0, PriceCalc.maxPercent).toDouble();
