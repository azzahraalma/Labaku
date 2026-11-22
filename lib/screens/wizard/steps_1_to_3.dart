import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_theme.dart';
import '../../core/calc.dart';
import '../../core/format.dart';
import '../../core/ui_kit.dart';
import '../../core/widgets.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import 'draft.dart';
import 'labor_dialog.dart';
import 'material_dialog.dart';
import 'wizard_dialogs.dart';

// LANGKAH 1/6 : INFO DASAR
class Step1InfoDasar extends StatefulWidget {
  final ProductDraft draft;
  final VoidCallback onChanged;
  const Step1InfoDasar(
      {super.key, required this.draft, required this.onChanged});

  @override
  State<Step1InfoDasar> createState() => _Step1InfoDasarState();
}

class _Step1InfoDasarState extends State<Step1InfoDasar> {
  final _ds = DataService.instance;
  late final _nama = TextEditingController(text: widget.draft.nama);
  late final _qty = TextEditingController(
      text: widget.draft.jumlah > 0 ? Fmt.plain(widget.draft.jumlah) : '');

  @override
  void initState() {
    super.initState();
    if (widget.draft.unit == null && _ds.units.isNotEmpty) {
      widget.draft.unit = _ds.units.first;
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _qty.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final f = await ImagePicker().pickImage(
          source: ImageSource.gallery, maxWidth: 640, maxHeight: 640, imageQuality: 75);
      if (f != null) {
        final b = await f.readAsBytes();
        if (mounted) {
          setState(() => widget.draft.foto = b);
          widget.onChanged();
        }
      }
    } catch (_) {}
  }

  Future<void> _pickCategory() async {
    final c = await showAppDialog<CategoryItem>(
        context, (_) => const CategoryPickDialog(),
        dismissible: true);
    if (c != null && mounted) {
      setState(() => widget.draft.category = c);
      widget.onChanged();
    }
  }

  Future<void> _addUnit() async {
    final u = await showAppDialog<UnitItem>(context, (_) => const UnitAddDialog());
    if (u != null && mounted) {
      setState(() => widget.draft.unit = u);
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final unitNames = _ds.units.map((u) => u.nama).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      child: Column(
        children: [
          DashedBox(
            width: 146,
            height: 152,
            onTap: _pickPhoto,
            child: d.foto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(d.foto!,
                        width: 146, height: 152, fit: BoxFit.cover),
                  )
                : (d.existingFotoUrl != null && d.existingFotoUrl!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          d.existingFotoUrl!,
                          width: 146,
                          height: 152,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded,
                                  size: 36, color: AppColors.grey),
                              SizedBox(height: 8),
                              Text('Tambah Foto Produk',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: UiColors.textMute)),
                            ],
                          ),
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded,
                              size: 36, color: AppColors.grey),
                          SizedBox(height: 8),
                          Text('Tambah Foto Produk',
                              style: TextStyle(
                                  fontSize: 11.5, color: UiColors.textMute)),
                        ],
                      ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: UiColors.shadow, blurRadius: 12, offset: Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Nama Produk', weight: FontWeight.w600),
                const SizedBox(height: 10),
                OutField(
                  controller: _nama,
                  icon: Icons.inventory_2_outlined,
                  hint: 'Contoh : Roti Tawar Premium',
                  height: 50,
                  onChanged: (v) {
                    d.nama = v;
                    widget.onChanged();
                  },
                ),
                const SizedBox(height: 18),
                const SectionLabel('Kategori', weight: FontWeight.w600),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickCategory,
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: UiColors.lavender,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: UiColors.blueTint, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: const Color(0xFFC9D5EC),
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(
                            d.category == null
                                ? Icons.grid_view_rounded
                                : categoryIcon(d.category!.nama),
                            size: 22,
                            color: AppColors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.category?.nama ?? 'Lainnya',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.black)),
                              const Text('Tap untuk mengubah',
                                  style: TextStyle(
                                      fontSize: 12, color: UiColors.textMute)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            size: 24, color: AppColors.black),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SectionLabel('Jumlah Produksi', weight: FontWeight.w600),
                const SizedBox(height: 6),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.info_rounded,
                          size: 17, color: AppColors.blue),
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Jumlah produksi otomatis menjadi stok awal produk dan bisa ditambah kapan saja.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: UiColors.textMute,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: OutField(
                        controller: _qty,
                        icon: Icons.layers_outlined,
                        hint: 'Jumlah',
                        height: 50,
                        keyboard: const TextInputType.numberWithOptions(decimal: true),
                        formatters: [DecimalFormatter()],
                        onChanged: (v) {
                          d.jumlah = Fmt.parse(v);
                          widget.onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: UnitDropdown(
                        height: 50,
                        items: unitNames,
                        value: d.unit?.nama ?? 'pcs',
                        onSelected: (v) {
                          final found =
                              _ds.units.where((u) => u.nama == v).firstOrNull;
                          setState(() => d.unit = found);
                          widget.onChanged();
                        },
                        onAddUnit: _addUnit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// LANGKAH 2/6 : BAHAN BAKU
class Step2BahanBaku extends StatelessWidget {
  final ProductDraft draft;
  final bool showMinWarning;
  final VoidCallback onChanged;
  const Step2BahanBaku({
    super.key,
    required this.draft,
    required this.showMinWarning,
    required this.onChanged,
  });

  Future<void> _addMaterial(BuildContext context, {bool createFirst = false}) async {
    final exclude = draft.recipe.map((r) => r.material.id).toSet();
    final line = await showAppDialog<RecipeLine>(
      context,
      (_) => MaterialDialog(excludeIds: exclude, startOnCreate: createFirst),
      dismissible: true,
    );
    if (line != null) {
      draft.recipe.add(line);
      onChanged();
    }
  }

  Future<void> _editQty(BuildContext context, int index) async {
    final line = draft.recipe[index];
    final q = await showAppDialog<double>(
      context,
      (_) => QtyDialog(material: line.material, initial: line.qty),
      dismissible: true,
    );
    if (q != null && q > 0) {
      draft.recipe[index].qty = q;
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = draft.recipe;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Daftar Bahan Baku',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                    Text(
                      list.isEmpty
                          ? 'Belum ada bahan ditambahkan'
                          : '${list.length} bahan',
                      style: const TextStyle(
                          fontSize: 13.5, color: UiColors.textMute),
                    ),
                  ],
                ),
              ),
              if (list.isNotEmpty)
                GestureDetector(
                  onTap: () => _addMaterial(context),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: UiColors.blueTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 20, color: AppColors.blue),
                        SizedBox(width: 4),
                        Text('Tambah\nBahan',
                            style: TextStyle(
                                fontSize: 12.5,
                                height: 1.15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blue)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (showMinWarning && list.isEmpty) ...[
            const SizedBox(height: 14),
            const AlertBanner('Minimal harus ada 1 bahan baku'),
          ],
          const SizedBox(height: 16),
          if (list.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 34),
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
                  const _EmptyIllustration(),
                  const SizedBox(height: 18),
                  const Text('Belum Ada Bahan',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue)),
                  const SizedBox(height: 6),
                  const Text(
                    'Tambahkan bahan baku yang diperlukan\nuntuk membuat produk ini',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, height: 1.4, color: UiColors.textMute),
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    text: '+  Tambah Bahan Pertama',
                    width: 240,
                    height: 44,
                    fontSize: 14.5,
                    onTap: () => _addMaterial(context),
                  ),
                ],
              ),
            )
          else ...[
            // Kartu biru Total Biaya Bahan
            _BlueTotalCard(
              title: 'Total Biaya Bahan',
              subtitle: '${list.length} bahan',
              amount: draft.bahan,
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < list.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecipeCard(
                  line: list[i],
                  onEdit: () => _editQty(context, i),
                  onDelete: () {
                    draft.recipe.removeAt(i);
                    onChanged();
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeLine line;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _RecipeCard(
      {required this.line, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final m = line.material;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
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
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                    Text(unitPriceLabel(m),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.black)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.edit_rounded, size: 20, color: AppColors.blue),
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 21, color: AppColors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(6)),
                child: Text('Jumlah: ${Fmt.plain(line.qty)} ${m.unit}',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white)),
              ),
              const Spacer(),
              Text(Fmt.rp(line.cost),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue)),
            ],
          ),
        ],
      ),
    );
  }
}

// LANGKAH 3/6 : TENAGA KERJA
class Step3TenagaKerja extends StatelessWidget {
  final ProductDraft draft;
  final VoidCallback onChanged;
  const Step3TenagaKerja(
      {super.key, required this.draft, required this.onChanged});

  Future<void> _addLabor(BuildContext context) async {
    final exclude = draft.labors.map((l) => l.employeeId).toSet();
    final line = await showAppDialog<LaborLine>(
      context,
      (_) => LaborDialog(excludeEmployeeIds: exclude),
      dismissible: true,
    );
    if (line != null) {
      draft.labors.add(line);
      onChanged();
    }
  }

  Future<void> _editLabor(BuildContext context, int i) async {
    final line = await showAppDialog<LaborLine>(
      context,
      (_) => LaborDialog(editing: draft.labors[i]),
      dismissible: true,
    );
    if (line != null) {
      draft.labors[i] = line;
      onChanged();
    }
  }

  IconData _methodIcon(String m) {
    switch (m) {
      case 'jam':
        return Icons.access_time_rounded;
      case 'hari':
        return Icons.calendar_today_outlined;
      case 'output':
        return Icons.inventory_2_outlined;
      default:
        return Icons.edit_outlined;
    }
  }

  String _detailSubtitle(LaborLine l) {
    switch (l.metode) {
      case 'jam':
        return '${Fmt.plain(l.qty)} jam x ${Fmt.rp(l.tarif)}/jam';
      case 'hari':
        return '${Fmt.plain(l.qty)} hari x ${Fmt.rp(l.tarif)}/hari';
      case 'output':
        return '${Fmt.plain(l.qty)} output x ${Fmt.rp(l.tarif)}/output';
      default:
        return 'Total biaya langsung';
    }
  }

  Future<void> _addSelfLabor(BuildContext context) async {
    final uid = AuthService.instance.userId;
    if (uid == null) return;
    final myName = '${DataService.instance.home?.username ?? 'Pemilik'} (Saya)';
    final existingIdx = draft.labors.indexWhere((l) => l.employeeId == uid);
    final initial = existingIdx >= 0
        ? draft.labors[existingIdx]
        : LaborLine(
            employeeId: uid,
            name: myName,
            metode: 'jam',
            qty: 1,
            tarif: 0,
          );
    final line = await showAppDialog<LaborLine>(
      context,
      (_) => LaborDialog(editing: initial),
      dismissible: true,
    );
    if (line != null) {
      final fixed = LaborLine(
        employeeId: uid,
        name: myName,
        metode: line.metode,
        qty: line.qty,
        tarif: line.tarif,
      );
      if (existingIdx >= 0) {
        draft.labors[existingIdx] = fixed;
      } else {
        draft.labors.insert(0, fixed);
      }
      onChanged();
    }
  }

  Widget _selfOptionTile({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? UiColors.blueTint : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.blue : const Color(0xFFD0D5DD),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: selected ? AppColors.blue : AppColors.grey,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.3,
                      color: UiColors.textMute,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = draft.labors;
    final bosId = AuthService.instance.userId;
    final hasSelfLine =
        bosId != null && list.any((l) => l.employeeId == bosId);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Daftar Pekerja',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                    Text(
                        list.isEmpty && draft.selfWorker && !draft.selfIncludeCost
                            ? 'Dikerjakan sendiri (tanpa biaya tenaga kerja)'
                            : '${list.length} pekerja ditambahkan',
                        style: const TextStyle(
                            fontSize: 13, color: UiColors.textMute)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _addLabor(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: UiColors.blueTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.blue, width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 18, color: AppColors.blue),
                      SizedBox(width: 4),
                      Text('Tambah',
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Catatan sesuai diagram use case
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_rounded, size: 15, color: AppColors.blue),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Biaya Tenaga Kerja yang dihitung sesuai dengan tenaga kerja yang digunakan dalam pembuatan produk dan atau proses usaha.',
                  style: TextStyle(
                      fontSize: 11.5, height: 1.35, color: UiColors.textMute),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Switch: Saya adalah karyawannya (tetap bisa tambah karyawan lain)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.blue, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saya adalah karyawannya',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Aktifkan jika kamu ikut turun langsung mengerjakan produk atau menjaga usaha. Kamu tetap bisa tambah karyawan lain.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.35,
                              color: UiColors.textMute,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: draft.selfWorker,
                      activeThumbColor: AppColors.white,
                      activeTrackColor: AppColors.blue,
                      onChanged: (v) {
                        draft.selfWorker = v;
                        if (!v) {
                          draft.selfIncludeCost = false;
                          if (bosId != null) {
                            draft.labors
                                .removeWhere((l) => l.employeeId == bosId);
                          }
                        } else {
                          draft.selfIncludeCost = false;
                        }
                        onChanged();
                      },
                    ),
                  ],
                ),
                if (draft.selfWorker) ...[
                  const SizedBox(height: 12),
                  _selfOptionTile(
                    selected: !draft.selfIncludeCost,
                    title: 'Tanpa biaya tenaga kerja untuk saya',
                    subtitle: 'Tenagamu tidak dimasukkan ke modal (Rp0).',
                    onTap: () {
                      draft.selfIncludeCost = false;
                      if (bosId != null) {
                        draft.labors.removeWhere((l) => l.employeeId == bosId);
                      }
                      onChanged();
                    },
                  ),
                  const SizedBox(height: 8),
                  _selfOptionTile(
                    selected: draft.selfIncludeCost,
                    title: 'Tetap masukkan biaya tenaga kerja saya',
                    subtitle: 'Hitung gaji untuk dirimu sendiri agar masuk ke modal.',
                    onTap: () {
                      draft.selfIncludeCost = true;
                      onChanged();
                      if (!hasSelfLine) {
                        _addSelfLabor(context);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: UiColors.blueTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.info_rounded,
                              size: 16, color: AppColors.blue),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Biaya tenaga kerja dihitung di luar laba usaha. Jadi kamu tetap dapat gaji sendiri + laba bersih usaha.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.4,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (draft.selfIncludeCost && !hasSelfLine) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: AppButton(
                        text: '+  Atur Biaya Tenaga Kerja Saya',
                        width: 250,
                        height: 40,
                        fontSize: 13.5,
                        onTap: () => _addSelfLabor(context),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (list.isEmpty && draft.selfWorker && !draft.selfIncludeCost)
            const SizedBox.shrink()
          else if (list.isEmpty && !draft.selfWorker)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 42, 24, 42),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.blue, width: 1.2),
              ),
              child: Column(
                children: [
                  const IconBadge(Icons.groups_rounded,
                      size: 80, bg: Color(0xFFDCDCDC), fg: AppColors.grey),
                  const SizedBox(height: 18),
                  const Text('Belum Ada Pekerja',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                  const SizedBox(height: 6),
                  const Text(
                    'Tambahkan data pekerja yang\nterlibat dalam pembuatan produk',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, height: 1.4, color: UiColors.textMute),
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    text: '+  Tambah Tenaga Kerja',
                    width: 230,
                    height: 44,
                    fontSize: 14.5,
                    onTap: () => _addLabor(context),
                  ),
                ],
              ),
            )
          else if (list.isNotEmpty) ...[
            _BlueTotalCard(
              title: 'Total Biaya Tenaga Kerja',
              subtitle: '${list.length} Tenaga Kerja',
              amount: draft.tenaga,
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < list.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.blue, width: 1.3),
                  ),
                  child: Row(
                    children: [
                      IconBadge(_methodIcon(list[i].metode),
                          size: 42, bg: const Color(0xFFDCDCDC), fg: AppColors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(list[i].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black)),
                            const SizedBox(height: 2),
                            Text(_detailSubtitle(list[i]),
                                style: const TextStyle(
                                    fontSize: 11.5, color: UiColors.textMute)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: AppColors.yellow,
                                  borderRadius: BorderRadius.circular(5)),
                              child: Text(list[i].metodeLabel,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.blue)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(Fmt.rp(list[i].total),
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.blue)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _editLabor(context, i),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.edit_rounded,
                                      size: 17, color: AppColors.blue),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  draft.labors.removeAt(i);
                                  onChanged();
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.delete_outline_rounded,
                                      size: 18, color: AppColors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// Komponen bersama langkah 2 & 3
class _BlueTotalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  const _BlueTotalCard(
      {required this.title, required this.subtitle, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: UiColors.shadow, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 36,
            margin: const EdgeInsets.only(top: 2),
            decoration: const BoxDecoration(
              color: AppColors.darkYellow,
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFD6E3FA))),
                const SizedBox(height: 6),
                Text(Fmt.rp(amount),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 84,
            decoration: BoxDecoration(
              color: UiColors.blueTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue, width: 2.5),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule_rounded, size: 30, color: AppColors.blue),
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
            right: 8,
            top: 4,
            child: Icon(Icons.send_rounded, size: 22, color: AppColors.darkYellow),
          ),
        ],
      ),
    );
  }
}
