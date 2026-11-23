import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/calc.dart';
import '../../core/format.dart';
import '../../core/ui_kit.dart';
import '../../core/widgets.dart';
import '../../services/data_service.dart';
import 'draft.dart';
import 'wizard_dialogs.dart';

// LANGKAH 4/6 : BIAYA OVERHEAD
class Step4Overhead extends StatefulWidget {
  final ProductDraft draft;
  final VoidCallback onChanged;
  const Step4Overhead(
      {super.key, required this.draft, required this.onChanged});

  @override
  State<Step4Overhead> createState() => _Step4OverheadState();
}

class _Step4OverheadState extends State<Step4Overhead> {
  late final _pct = TextEditingController(
      text: widget.draft.overheadPct == null
          ? ''
          : Fmt.plain(widget.draft.overheadPct!));

  @override
  void dispose() {
    _pct.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final it = await showAppDialog<OverheadItem>(
      context,
      (_) => OverheadItemDialog(
        productQty: widget.draft.jumlah,
        productUnit: widget.draft.unit?.nama ?? 'pcs',
      ),
      dismissible: true,
    );
    if (it != null) {
      setState(() => widget.draft.overheads.add(it));
      widget.onChanged();
    }
  }

  Future<void> _editItem(int i) async {
    final it = await showAppDialog<OverheadItem>(
      context,
      (_) => OverheadItemDialog(
        initial: widget.draft.overheads[i],
        productQty: widget.draft.jumlah,
        productUnit: widget.draft.unit?.nama ?? 'pcs',
      ),
      dismissible: true,
    );
    if (it != null) {
      setState(() => widget.draft.overheads[i] = it);
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final r = d.result;
    final pctVal = (d.overheadPct ?? 0).clamp(0.0, 100.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Biaya Overhead',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
          const SizedBox(height: 4),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_rounded, size: 15, color: AppColors.blue),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Biaya-biaya rutin di luar bahan baku dan upah pekerja langsung yang tetap harus dikeluarkan agar bisnis bisa terus berjalan, contoh: sewa tempat, listrik, internet, gaji karyawan, dll.',
                  style: TextStyle(
                      fontSize: 11.5, height: 1.35, color: UiColors.textMute),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionLabel('Metode Perhitungan', weight: FontWeight.w600),
          const SizedBox(height: 10),
          SegmentPill(
            labels: const ['Presentase', 'Manual'],
            selected: d.overheadPersen ? 0 : 1,
            height: 38,
            onChanged: (i) {
              setState(() => d.overheadPersen = i == 0);
              widget.onChanged();
            },
          ),
          const SizedBox(height: 18),
          if (d.overheadPersen)
            _persenCard(d, r, pctVal)
          else
            _manualSection(d),
        ],
      ),
    );
  }

  Widget _persenCard(ProductDraft d, CalcResult r, double pctVal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.blue, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: UiColors.blueTint,
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.percent_rounded,
                    size: 20, color: AppColors.blue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Presentase Overhead',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black)),
                    Text('Geser atau masukan nominal',
                        style:
                            TextStyle(fontSize: 11.5, color: UiColors.textMute)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text('Nominal Presentase',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue)),
              ),
              SizedBox(
                width: 108,
                child: OutField(
                  controller: _pct,
                  height: 36,
                  radius: 18,
                  borderColor: AppColors.grey,
                  hint: '......',
                  textAlign: TextAlign.right,
                  keyboard:
                      const TextInputType.numberWithOptions(decimal: true),
                  formatters: [DecimalFormatter(maxInt: 3)],
                  suffix: const Text('%',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue)),
                  onChanged: (v) {
                    if (v.trim().isEmpty) {
                      d.overheadPct = null;
                    } else {
                      d.overheadPct = Fmt.parse(v).clamp(0, 100).toDouble();
                    }
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: UiColors.blueTint,
                borderRadius: BorderRadius.circular(12)),
            child: Text('${Fmt.plain(pctVal)}%',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue)),
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.blue,
              inactiveTrackColor: UiColors.blueTint,
              thumbColor: AppColors.blue,
              trackHeight: 8,
            ),
            child: Slider(
              value: pctVal,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (v) {
                d.overheadPct = v.roundToDouble();
                _pct.text = v.round().toString();
                setState(() {});
                widget.onChanged();
              },
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: TextStyle(fontSize: 11.5, color: UiColors.textMute)),
              Text('50%', style: TextStyle(fontSize: 11.5, color: UiColors.textMute)),
              Text('100%', style: TextStyle(fontSize: 11.5, color: UiColors.textMute)),
            ],
          ),
          const Divider(height: 24, color: AppColors.grey),
          _row('Biaya Bahan Baku', Fmt.rp(r.bahan)),
          const SizedBox(height: 6),
          _row('Biaya Tenaga Kerja', Fmt.rp(r.tenaga)),
          const Divider(height: 20, color: AppColors.grey),
          _row('Total Basis', Fmt.rp(r.basis), boldLeft: true),
          const SizedBox(height: 6),
          _row('Presentase', '${Fmt.plain(pctVal)}%'),
          const Divider(height: 22, color: AppColors.grey),
          Row(
            children: [
              const Expanded(
                child: Text('Biaya Overhead',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black)),
              ),
              Text(Fmt.rp(r.overhead),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v, {bool boldLeft = false}) => Row(
        children: [
          Expanded(
            child: Text(k,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: boldLeft ? FontWeight.w600 : FontWeight.w400,
                    color: boldLeft ? AppColors.black : UiColors.textMute)),
          ),
          Text(v,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue)),
        ],
      );

  Widget _manualSection(ProductDraft d) {
    final list = d.overheads;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Item Overhead',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: Colors.black)),
            ),
            GestureDetector(
              onTap: _addItem,
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
        const SizedBox(height: 16),
        if (list.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 38, 24, 38),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.blue, width: 1.2),
            ),
            child: Column(
              children: [
                const IconBadge(Icons.inventory_2_rounded,
                    size: 86, bg: UiColors.blueTint, fg: AppColors.blue),
                const SizedBox(height: 18),
                const Text('Belum Ada Item',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
                const SizedBox(height: 6),
                const Text(
                  'Tambahkan komponen biaya overhead\nseperti listrik, air, gas, atau sewa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, height: 1.4, color: UiColors.textMute),
                ),
                const SizedBox(height: 22),
                AppButton(
                  text: '+  Tambah Item',
                  width: 190,
                  height: 42,
                  fontSize: 14.5,
                  onTap: _addItem,
                ),
              ],
            ),
          )
        else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.blue, width: 1.4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Biaya Overhead',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue)),
                      Text('${list.length} item overhead',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.blue)),
                    ],
                  ),
                ),
                Text(Fmt.rp(d.overheadManual),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < list.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.blue, width: 1.2),
                ),
                child: Row(
                  children: [
                    const IconBadge(Icons.inventory_2_rounded,
                        size: 46, bg: Color(0xFFC9D5EC), fg: AppColors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(list[i].nama,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black)),
                          Text(Fmt.rp(list[i].harga),
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.black)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _editItem(i),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.edit_rounded,
                            size: 19, color: AppColors.blue),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => list.removeAt(i));
                        widget.onChanged();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 20, color: AppColors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

// LANGKAH 5/6 : HASIL & MARGIN
class Step5HasilMargin extends StatefulWidget {
  final ProductDraft draft;
  final VoidCallback onChanged;
  const Step5HasilMargin(
      {super.key, required this.draft, required this.onChanged});

  @override
  State<Step5HasilMargin> createState() => _Step5HasilMarginState();
}

class _Step5HasilMarginState extends State<Step5HasilMargin> {
  final _ds = DataService.instance;
  late final _qty = TextEditingController(
      text: widget.draft.jumlah > 0 ? Fmt.plain(widget.draft.jumlah) : '');
  late final _pct = TextEditingController();
  late final _manual = TextEditingController(
      text: (widget.draft.manualUnit ?? 0) > 0
          ? Fmt.number(widget.draft.manualUnit!)
          : '');

  @override
  void initState() {
    super.initState();
    _syncPctText();
  }

  void _syncPctText() {
    final d = widget.draft;
    if (d.method == PriceMethod.markup && d.markup != null) {
      _pct.text = Fmt.plain(d.markup!);
    } else if (d.method == PriceMethod.margin && d.margin != null) {
      _pct.text = Fmt.plain(d.margin!);
    } else {
      _pct.clear();
    }
  }

  @override
  void dispose() {
    _qty.dispose();
    _pct.dispose();
    _manual.dispose();
    super.dispose();
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
    final r = d.result;
    final unitNames = _ds.units.map((u) => u.nama).toList();
    final hasPrice = d.step5Valid;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Hitung Keuntungan',
              size: 18, weight: FontWeight.w600),
          const SizedBox(height: 14),

          // Total Produksi card
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: BoxDecoration(
                color: UiColors.blueTint,
                borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.track_changes_rounded,
                        size: 24, color: AppColors.blue),
                    SizedBox(width: 8),
                    Text('Total Produksi',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 12,
                      child: OutField(
                        controller: _qty,
                        hint: 'Contoh: 10',
                        height: 44,
                        fill: UiColors.blueTint,
                        keyboard: const TextInputType.numberWithOptions(
                            decimal: true),
                        formatters: [DecimalFormatter()],
                        onChanged: (v) {
                          d.jumlah = Fmt.parse(v);
                          setState(() {});
                          widget.onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 9,
                      child: UnitDropdown(
                        height: 44,
                        items: unitNames,
                        value: d.unit?.nama ?? 'pcs',
                        onSelected: (v) {
                          final u =
                              _ds.units.where((x) => x.nama == v).firstOrNull;
                          setState(() => d.unit = u);
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
          const SizedBox(height: 16),

          // Metode Perhitungan Harga
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            decoration: BoxDecoration(
                color: const Color(0xFFE6E9F8),
                borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Metode Perhitungan Harga',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black)),
                const SizedBox(height: 12),
                _methodCard(
                  method: PriceMethod.markup,
                  icon: Icons.show_chart_rounded,
                  title: 'Markup',
                  desc: 'Untung berdasarkan presentase dari modal.',
                  formula: 'Rumus: Modal + (Modal x %)',
                ),
                const SizedBox(height: 10),
                _methodCard(
                  method: PriceMethod.margin,
                  icon: Icons.trending_up_rounded,
                  title: 'Margin',
                  desc: 'Untung sesuai persen harga jual final.',
                  formula: 'Rumus: Modal / (1 - %)',
                ),
                const SizedBox(height: 10),
                _methodCard(
                  method: PriceMethod.manual,
                  icon: Icons.edit_rounded,
                  title: 'Harga Manual',
                  desc: 'Isi harga jual sendiri (tanpa rumus).',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Panel input sesuai metode
          if (d.method == PriceMethod.manual)
            _manualPriceCard(d, r)
          else
            _percentCard(d),
          const SizedBox(height: 22),

          // Perhitungan Total Produksi
          const SectionLabel('Perhitungan Total Produksi',
              size: 17, weight: FontWeight.w600),
          const SizedBox(height: 12),
          _hppBreakdownCard(r),

          if (hasPrice) ...[
            const SizedBox(height: 14),
            _totalSummaryCard(r),
            const SizedBox(height: 20),
            const SectionLabel('Harga Jual Per Unit',
                size: 17, weight: FontWeight.w600),
            const SizedBox(height: 12),
            _perUnitBlueCard(r),
          ],
        ],
      ),
    );
  }

  Widget _methodCard({
    required PriceMethod method,
    required IconData icon,
    required String title,
    required String desc,
    String? formula,
  }) {
    final active = widget.draft.method == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.draft.method = method;
          _syncPctText();
        });
        widget.onChanged();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: active ? UiColors.blueTint : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? AppColors.blue : AppColors.grey,
              width: active ? 1.4 : 1),
        ),
        child: Row(
          children: [
            IconBadge(icon,
                size: 40,
                bg: active ? AppColors.blue : UiColors.blueTint,
                fg: active ? AppColors.white : AppColors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue)),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.black)),
                  if (active && formula != null) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF6D98B),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(formula,
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black)),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: active ? AppColors.blue : AppColors.grey,
                    width: 2),
              ),
              alignment: Alignment.center,
              child: active
                  ? Container(
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: AppColors.blue),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _percentCard(ProductDraft d) {
    final isMargin = d.method == PriceMethod.margin;
    final val = isMargin ? (d.margin ?? 0) : (d.markup ?? 0);
    final safeMin = isMargin ? 20 : 30;
    final warnLow = val > 0 && val < safeMin;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: UiColors.shadow, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(Icons.percent_rounded,
                  size: 34, bg: UiColors.blueTint, fg: AppColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(isMargin ? 'Margin keuntungan' : 'Markup',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue)),
              ),
              SizedBox(
                width: 82,
                child: OutField(
                  controller: _pct,
                  height: 36,
                  radius: 8,
                  borderColor: AppColors.black,
                  hint: '....',
                  textAlign: TextAlign.right,
                  keyboard:
                      const TextInputType.numberWithOptions(decimal: true),
                  formatters: [DecimalFormatter(maxInt: 2)],
                  suffix: const Text('%',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black)),
                  onChanged: (v) {
                    final parsed = v.trim().isEmpty
                        ? null
                        : pctClamp(Fmt.parse(v));
                    d.method ??= PriceMethod.markup;
                    if (d.method == PriceMethod.margin) {
                      d.margin = parsed;
                    } else {
                      d.markup = parsed;
                    }
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.blue,
              inactiveTrackColor: UiColors.blueTint,
              thumbColor: AppColors.blue,
              trackHeight: 7,
            ),
            child: Slider(
              value: val.clamp(0, PriceCalc.maxPercent),
              min: 0,
              max: PriceCalc.maxPercent,
              divisions: 95,
              onChanged: (v) {
                final r = v.roundToDouble();
                d.method ??= PriceMethod.markup;
                if (d.method == PriceMethod.margin) {
                  d.margin = r;
                } else {
                  d.markup = r;
                }
                _pct.text = r.toInt().toString();
                setState(() {});
                widget.onChanged();
              },
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: TextStyle(fontSize: 11.5, color: UiColors.textMute)),
              Text('95%', style: TextStyle(fontSize: 11.5, color: UiColors.textMute)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
                color: UiColors.chipGrey,
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_rounded, size: 15, color: AppColors.grey),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isMargin
                        ? 'Harga Jual = Total Biaya / (1 - %margin)'
                        : 'Harga Jual = Total Biaya x (1 + %markup)',
                    style: const TextStyle(fontSize: 11.5, color: UiColors.textMute),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            warnLow
                ? 'Perhatian: di bawah rekomendasi aman ($safeMin% keatas)'
                : 'Rekomendasi aman : $safeMin% keatas',
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: warnLow ? AppColors.red : UiColors.textMute,
            ),
          ),
        ],
      ),
    );
  }

  Widget _manualPriceCard(ProductDraft d, CalcResult r) {
    final labaUnit = (d.manualUnit ?? 0) - r.hppPerUnit;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: UiColors.shadow, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              IconBadge(Icons.percent_rounded,
                  size: 34, bg: UiColors.blueTint, fg: AppColors.blue),
              SizedBox(width: 10),
              Text('Harga Jual Manual',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue)),
            ],
          ),
          const SizedBox(height: 18),
          OutField(
            controller: _manual,
            floatLabel: 'Set Harga Jual Per Unit',
            prefix: const Text('Rp',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black)),
            hint: '0',
            height: 48,
            borderColor: AppColors.grey,
            keyboard: TextInputType.number,
            formatters: [ThousandsFormatter()],
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
            onChanged: (v) {
              d.manualUnit = Fmt.parse(v);
              setState(() {});
              widget.onChanged();
            },
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: UiColors.blueTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estimasi Laba per Unit',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.blue)),
                const SizedBox(height: 4),
                Text(Fmt.rp(labaUnit),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: labaUnit < 0 ? AppColors.red : AppColors.blue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hppBreakdownCard(CalcResult r) {
    Widget item(IconData icon, Color bg, Color fg, String title, double val) {
      final share = PriceCalc.share(val, r.hpp);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            IconBadge(icon, size: 36, bg: bg, fg: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13.5, color: UiColors.textMute)),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (share / 100).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: UiColors.blueTint,
                      valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Fmt.rp(val),
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black)),
                Text('${share.round()}%',
                    style: const TextStyle(
                        fontSize: 11.5, color: UiColors.textMute)),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: UiColors.shadow, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rincian Komponen Biaya',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black)),
          const SizedBox(height: 14),
          item(Icons.inventory_2_rounded, const Color(0xFFDCDCDC), AppColors.grey,
              'Bahan Baku', r.bahan),
          item(Icons.groups_rounded, const Color(0xFFF6D98B), AppColors.black,
              'Tenaga Kerja', r.tenaga),
          item(Icons.settings_rounded, UiColors.blueTint, AppColors.grey,
              'Overhead', r.overhead),
          const Divider(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text('Total HPP',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black)),
              ),
              Text(Fmt.rp(r.hpp),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalSummaryCard(CalcResult r) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blue, width: 1),
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
                    const Text('Total Harga Jual',
                        style: TextStyle(
                            fontSize: 13.5, color: UiColors.textMute)),
                    const SizedBox(height: 2),
                    Text(Fmt.rp(r.hargaDasar),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black)),
                    Text('(${Fmt.rp(r.hargaDasarPerUnit)} / unit)',
                        style: const TextStyle(
                            fontSize: 12, color: UiColors.textMute)),
                  ],
                ),
              ),
              const IconBadge(Icons.payments_rounded,
                  size: 38, bg: UiColors.blueTint, fg: AppColors.blue),
            ],
          ),
          const Divider(height: 22, color: AppColors.blue),
          const Text('Total Keuntungan',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(Fmt.rp(r.labaDasar),
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: r.labaDasar < 0 ? AppColors.red : AppColors.blue)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(Fmt.pct(r.marginTarget),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _perUnitBlueCard(CalcResult r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analisis per Unit',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.arrow_downward_rounded,
                  size: 16, color: Color(0xFFD6E3FA)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('HPP per Unit',
                    style:
                        TextStyle(fontSize: 14, color: Color(0xFFD6E3FA))),
              ),
              Text(Fmt.rp(r.hppPerUnit),
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.arrow_upward_rounded,
                  size: 16, color: AppColors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Harga Jual per Unit',
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white)),
              ),
              Text(Fmt.rp(r.hargaDasarPerUnit),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white)),
            ],
          ),
          const Divider(height: 24, color: Color(0x66FFFFFF)),
          const Text('Laba per Unit',
              style: TextStyle(fontSize: 12.5, color: Color(0xFFD6E3FA))),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(Fmt.rp(r.hargaDasarPerUnit - r.hppPerUnit),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(Fmt.pct(r.marginTarget),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// LANGKAH 6/6 : PAJAK & HARGA FINAL
class Step6PajakFinal extends StatefulWidget {
  final ProductDraft draft;
  final VoidCallback onChanged;
  const Step6PajakFinal(
      {super.key, required this.draft, required this.onChanged});

  @override
  State<Step6PajakFinal> createState() => _Step6PajakFinalState();
}

class _Step6PajakFinalState extends State<Step6PajakFinal> {
  late final _svc = TextEditingController(
      text: Fmt.plain(widget.draft.servicePct));
  late final _tax = TextEditingController(
      text: widget.draft.taxRate.toStringAsFixed(1));

  @override
  void dispose() {
    _svc.dispose();
    _tax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final r = d.result;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pajak & Harga Final',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
          const Text('Pengaturan pajak untuk harga jual',
              style: TextStyle(fontSize: 13, color: UiColors.textMute)),
          const SizedBox(height: 16),

          // 1. Service Charge
          _toggleCard(
            active: d.serviceOn,
            icon: Icons.room_service_rounded,
            title: 'Service Charge',
            italicNote:
                'Biaya tambahan yang dibebankan kepada pelanggan atas jasa pelayanan',
            subtitle: d.serviceOn ? null : 'Tidak ada service charge',
            onToggle: (v) {
              setState(() => d.serviceOn = v);
              widget.onChanged();
            },
            expanded: Column(
              children: [
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Persentase Service Charge',
                          style: TextStyle(
                              fontSize: 13.5, color: AppColors.black)),
                    ),
                    SizedBox(
                      width: 82,
                      child: OutField(
                        controller: _svc,
                        height: 38,
                        radius: 10,
                        borderColor: AppColors.grey,
                        fill: UiColors.blueTint,
                        textAlign: TextAlign.right,
                        keyboard: const TextInputType.numberWithOptions(
                            decimal: true),
                        formatters: [DecimalFormatter(maxInt: 2)],
                        suffix: const Text('%',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.black)),
                        onChanged: (v) {
                          d.servicePct = Fmt.parse(v).clamp(0, 100).toDouble();
                          setState(() {});
                          widget.onChanged();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _yellowHint(
                    'Service charge umum untuk restoran/hotel adalah 5-10%'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Perhitungan Pajak
          _toggleCard(
            active: d.taxOn,
            icon: Icons.receipt_long_rounded,
            title: 'Perhitungan Pajak',
            subtitle: d.taxOn
                ? 'Pajak akan ditambahkan ke harga jual'
                : 'Pajak tidak dihitung',
            onToggle: (v) {
              setState(() => d.taxOn = v);
              widget.onChanged();
            },
          ),
          if (d.taxOn) ...[
            const SizedBox(height: 14),
            _taxTypeSection(d),
            const SizedBox(height: 14),
            _taxRateSection(d),
            const SizedBox(height: 14),
            _taxMethodSection(d),
          ],
          const SizedBox(height: 14),

          // 3. Pembulatan Harga
          _toggleCard(
            active: d.roundOn,
            icon: Icons.calculate_rounded,
            title: 'Pembulatan Harga',
            subtitle: d.roundOn
                ? 'Harga per unit akan dibulatkan ke atas'
                : 'Tanpa pembulatan',
            onToggle: (v) {
              setState(() => d.roundOn = v);
              widget.onChanged();
            },
            expanded: _roundingExpanded(d, r),
          ),
          const SizedBox(height: 20),

          // 4. Kartu Biru Harga Final
          _finalPriceCard(r),
        ],
      ),
    );
  }

  Widget _toggleCard({
    required bool active,
    required IconData icon,
    required String title,
    String? italicNote,
    String? subtitle,
    required ValueChanged<bool> onToggle,
    Widget? expanded,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: active ? UiColors.blueTint : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blue, width: 1.3),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconBadge(icon,
                  size: 46,
                  bg: active ? AppColors.blue : const Color(0xFFC9D5EC),
                  fg: active ? AppColors.white : AppColors.black),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: active ? AppColors.black : AppColors.blue)),
                    if (italicNote != null)
                      Text(italicNote,
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontStyle: FontStyle.italic,
                              height: 1.25,
                              color: AppColors.blue)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: UiColors.textMute)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppSwitch(value: active, onChanged: onToggle),
            ],
          ),
          if (active && expanded != null) expanded,
        ],
      ),
    );
  }

  Widget _yellowHint(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3CF7A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_rounded, size: 16, color: AppColors.black),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 11.5, height: 1.35, color: AppColors.black)),
            ),
          ],
        ),
      );

  Widget _taxTypeSection(ProductDraft d) {
    Widget opt(TaxType t, IconData icon, String title, String sub) {
      final sel = d.taxType.id == t.id;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () {
            setState(() {
              d.taxType = t;
              d.taxRate = t.defaultRate;
              _tax.text = t.defaultRate.toStringAsFixed(1);
            });
            widget.onChanged();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFFEAF0FD) : AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: sel ? AppColors.blue : UiColors.blueTint,
                  width: sel ? 1.4 : 1.2),
            ),
            child: Row(
              children: [
                IconBadge(icon,
                    size: 42,
                    bg: sel ? AppColors.blue : const Color(0xFFC9D5EC),
                    fg: sel ? AppColors.white : AppColors.black),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black)),
                      const SizedBox(height: 2),
                      Text(sub,
                          style: const TextStyle(
                              fontSize: 11, color: UiColors.textMute)),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.blue, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: sel
                      ? Container(
                          width: 11,
                          height: 11,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: AppColors.blue),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: UiColors.shadow, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Jenis Pajak',
              style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black)),
          const SizedBox(height: 12),
          opt(TaxType.ppn, Icons.receipt_long_rounded,
              'PPN (Pajak Pertambahan Nilai)',
              'Pajak yang dikenakan kepada konsumen akhir (umum: 11%)'),
          opt(TaxType.pb1, Icons.restaurant_rounded, 'PB1 / Pajak Restoran',
              'Pajak daerah untuk F&B / Perhotelan (umum: 10%)'),
          opt(TaxType.pph, Icons.account_balance_rounded,
              'PPh Final 0.5% UMKM',
              'Pajak penghasilan final untuk UMKM (0.5% dari omzet)'),
        ],
      ),
    );
  }

  Widget _taxRateSection(ProductDraft d) {
    final presets = d.taxType.id == 'pph'
        ? const [0.5, 1.0, 2.0]
        : d.taxType.id == 'pb1'
            ? const [5.0, 10.0, 11.0]
            : const [10.0, 11.0, 12.0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: UiColors.shadow, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(Icons.percent_rounded,
                  size: 32, bg: AppColors.blue, fg: AppColors.white),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Tarif Pajak',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black)),
              ),
              SizedBox(
                width: 96,
                child: OutField(
                  controller: _tax,
                  height: 38,
                  radius: 10,
                  textAlign: TextAlign.right,
                  keyboard:
                      const TextInputType.numberWithOptions(decimal: true),
                  formatters: [DecimalFormatter(maxInt: 2)],
                  suffix: const Text('%',
                      style: TextStyle(
                          fontSize: 14, color: UiColors.textMute)),
                  onChanged: (v) {
                    d.taxRate = Fmt.parse(v).clamp(0, 100).toDouble();
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final p in presets)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        d.taxRate = p;
                        _tax.text = p.toStringAsFixed(1);
                      });
                      widget.onChanged();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: (d.taxRate - p).abs() < 0.01
                            ? AppColors.blue
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: (d.taxRate - p).abs() < 0.01
                                ? AppColors.blue
                                : AppColors.grey),
                      ),
                      child: Text('${Fmt.plain(p)}%',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: (d.taxRate - p).abs() < 0.01
                                  ? AppColors.white
                                  : AppColors.black)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _yellowHint(
              'Tarif standar untuk ${d.taxType.nama} adalah ${d.taxType.defaultRate.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _taxMethodSection(ProductDraft d) {
    Widget opt(bool inc, String title, String sub) {
      final sel = d.taxIncluded == inc;
      return GestureDetector(
        onTap: () {
          setState(() => d.taxIncluded = inc);
          widget.onChanged();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFEAF0FD) : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: sel ? AppColors.blue : UiColors.blueTint,
                width: sel ? 1.4 : 1.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black)),
                    Text(sub,
                        style: const TextStyle(
                            fontSize: 11.5, color: UiColors.textMute)),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.blue, width: 2),
                ),
                alignment: Alignment.center,
                child: sel
                    ? Container(
                        width: 11,
                        height: 11,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: AppColors.blue),
                      )
                    : null,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: UiColors.shadow, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Metode Perhitungan',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black)),
          const SizedBox(height: 10),
          opt(false, 'Belum Termasuk Pajak',
              'Pajak ditambahkan di atas harga jual'),
          const SizedBox(height: 10),
          opt(true, 'Sudah Termasuk Pajak',
              'Pajak sudah termasuk di dalam harga jual'),
        ],
      ),
    );
  }

  Widget _roundingExpanded(ProductDraft d, CalcResult r) {
    const steps = <(double, String)>[
      (100, 'Rp100'),
      (500, 'Rp500'),
      (1000, 'Rp1rb'),
      (5000, 'Rp5rb'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        const Text('Bulatkan harga per unit ke kelipatan:',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.black)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (step, label) in steps)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => d.roundStep = step);
                      widget.onChanged();
                    },
                    child: Container(
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: d.roundStep == step
                            ? AppColors.blue
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.blue),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: d.roundStep == step
                                  ? AppColors.white
                                  : AppColors.blue)),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _yellowHint(
            'Pembulatan dilakukan pada harga per unit, kemudian dikali jumlah produksi untuk total'),
      ],
    );
  }

  Widget _finalPriceCard(CalcResult r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              IconBadge(Icons.attach_money_rounded,
                  size: 36, bg: AppColors.white, fg: AppColors.blue),
              SizedBox(width: 12),
              Text('Harga Final',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white)),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Harga Jual (sebelum tambahan)',
              style: TextStyle(fontSize: 13.5, color: Color(0xFFD6E3FA))),
          const SizedBox(height: 2),
          Text(Fmt.rp(r.hargaDasar),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white)),
          const Divider(height: 24, color: Color(0x88FFFFFF)),
          const Text('TOTAL HARGA FINAL',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD6E3FA))),
          const SizedBox(height: 4),
          Text(Fmt.rp(r.hargaFinal),
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: UiColors.blueTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Per Unit',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black)),
                ),
                Text(Fmt.rp(r.hargaFinalPerUnit),
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
