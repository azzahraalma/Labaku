import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

/// Warna tambahan turunan palet (opacity dari biru tua / kuning).
class UiColors {
  static const page = Color(0xFFF8F9FF);
  static const blobYellow = Color(0xFFFCE7C3); // kuning FFC545 @ ~30% di atas putih
  static const blueSoft = Color(0xFF6A89C2); // biru tua @ 70%
  static const blueTint = Color(0xFFCEDFFF); // biru muda
  static const blueCard = Color(0xFFD5E2FA);
  static const field = Color(0xFFF1F1F1);
  static const lavender = Color(0xFFF3F2FD);
  static const chipGrey = Color(0xFFE9E9E9);
  static const textDark = Color(0xFF373737);
  static const textMute = Color(0xFF747474);
  static const shadow = Color(0x14000000);
}

/// Latar halaman: warna dasar + lingkaran kuning lembut (kanan atas & kiri bawah).
class PageBg extends StatelessWidget {
  final Widget child;
  final bool blobs;
  const PageBg({super.key, required this.child, this.blobs = true});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: UiColors.page,
      child: Stack(
        children: [
          if (blobs) ...[
            Positioned(
              right: -70,
              top: -80,
              child: Container(
                width: 190,
                height: 190,
                decoration: const BoxDecoration(
                    color: UiColors.blobYellow, shape: BoxShape.circle),
              ),
            ),
            Positioned(
              left: -90,
              bottom: -60,
              child: Container(
                width: 190,
                height: 190,
                decoration: const BoxDecoration(
                    color: UiColors.blobYellow, shape: BoxShape.circle),
              ),
            ),
          ],
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Penanda biru di kiri judul seksi.
class SectionLabel extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final double markerHeight;
  const SectionLabel(this.text,
      {super.key,
      this.size = 16,
      this.weight = FontWeight.w500,
      this.markerHeight = 22});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: markerHeight,
          decoration: const BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(3), bottomRight: Radius.circular(3)),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(text,
              style: TextStyle(
                  fontSize: size, fontWeight: weight, color: Colors.black)),
        ),
      ],
    );
  }
}

/// Kerangka halaman wizard: header (back + judul + langkah), progress, body, bar bawah.
class StepScaffold extends StatelessWidget {
  final String title;
  final int step;
  final int totalSteps;
  final VoidCallback onBack;
  final Widget body;
  final Widget bottom;
  const StepScaffold({
    super.key,
    required this.title,
    required this.step,
    this.totalSteps = 6,
    required this.onBack,
    required this.body,
    required this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.white,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Column(
            children: [
              SizedBox(
                height: 62,
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onBack,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        child: Icon(Icons.arrow_back_rounded,
                            size: 30, color: AppColors.blue),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.2,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black)),
                          Text('Langkah $step/$totalSteps',
                              style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.2,
                                  color: UiColors.textMute)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (_, c) => Stack(
                  children: [
                    Container(height: 4, color: UiColors.blueTint),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 4,
                      width: c.maxWidth * step / totalSteps,
                      color: AppColors.blue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: PageBg(child: body)),
        bottom,
      ],
    );
  }
}

/// Bar bawah: [Kembali] [Lanjut/Simpan].
class WizardBottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool nextEnabled; // tampilan biru jika true
  final bool backActive; // border biru muda lebih tegas (mis. langkah lanjut)
  final String nextText;
  final bool nextArrow;
  final bool loading;
  const WizardBottomBar({
    super.key,
    required this.onBack,
    required this.onNext,
    required this.nextEnabled,
    this.backActive = false,
    this.nextText = 'Lanjut',
    this.nextArrow = true,
    this.loading = false,
  });

  Widget _btn({
    required VoidCallback onTap,
    required Widget child,
    required Color bg,
    required Color border,
  }) =>
      Expanded(
        child: Material(
          color: bg,
          shape: StadiumBorder(side: BorderSide(color: border, width: 1.5)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: SizedBox(height: 38, child: Center(child: child)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final grey = AppColors.grey;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: UiColors.shadow, blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      child: Row(
        children: [
          _btn(
            onTap: onBack,
            bg: AppColors.surface,
            border: UiColors.blueTint,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back_rounded, size: 20, color: grey),
                const SizedBox(width: 8),
                Text('Kembali',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500, color: grey)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _btn(
            onTap: loading ? () {} : onNext,
            bg: nextEnabled ? AppColors.blue : AppColors.surface,
            border: nextEnabled ? AppColors.blue : UiColors.blueTint,
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(nextText,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: nextEnabled ? AppColors.white : grey)),
                      if (nextArrow) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            size: 20,
                            color: nextEnabled ? AppColors.white : grey),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- formatters
/// Hanya angka, dikelompokkan ribuan dengan titik (40.000).
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final digits = n.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final t = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final b = StringBuffer();
    for (var i = 0; i < t.length; i++) {
      if (i > 0 && (t.length - i) % 3 == 0) b.write('.');
      b.write(t[i]);
    }
    final s = b.toString();
    return TextEditingValue(
        text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

/// Angka desimal dengan koma (maks 2 desimal), contoh 1,5.
class DecimalFormatter extends TextInputFormatter {
  final int maxInt;
  DecimalFormatter({this.maxInt = 9});
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    var t = n.text.replaceAll('.', ',');
    if (!RegExp(r'^\d*(,\d{0,2})?$').hasMatch(t)) return o;
    final intPart = t.split(',').first;
    if (intPart.length > maxInt) return o;
    return TextEditingValue(
        text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

// ---------------------------------------------------------------- fields
/// Kolom input outline dengan label mengambang di garis (opsional), ikon & suffix.
class OutField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final String? floatLabel;
  final IconData? icon;
  final Widget? prefix; // mengganti icon (mis. teks "Rp")
  final Widget? suffix;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final bool error;
  final bool readOnly;
  final double height;
  final double radius;
  final Color borderColor;
  final Color fill;
  final TextStyle? textStyle;
  final int maxLines;
  final TextAlign textAlign;

  const OutField({
    super.key,
    required this.controller,
    this.hint,
    this.floatLabel,
    this.icon,
    this.prefix,
    this.suffix,
    this.keyboard,
    this.formatters,
    this.onChanged,
    this.error = false,
    this.readOnly = false,
    this.height = 44,
    this.radius = 12,
    this.borderColor = AppColors.blue,
    this.fill = AppColors.white,
    this.textStyle,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final bc = error ? AppColors.red : borderColor;
    final field = Container(
      height: maxLines > 1 ? null : height,
      constraints: maxLines > 1 ? BoxConstraints(minHeight: height) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: bc, width: 1),
      ),
      child: Row(
        children: [
          if (prefix != null) ...[prefix!, const SizedBox(width: 10)],
          if (prefix == null && icon != null) ...[
            Icon(icon, size: 22, color: UiColors.blueSoft),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              readOnly: readOnly,
              keyboardType: keyboard,
              inputFormatters: formatters,
              maxLines: maxLines,
              textAlign: textAlign,
              cursorColor: AppColors.blue,
              style: textStyle ??
                  TextStyle(
                      fontSize: 15,
                      color: error ? AppColors.red : Colors.black),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                    fontSize: 15, color: UiColors.textMute, fontWeight: FontWeight.w400),
                contentPadding: EdgeInsets.symmetric(vertical: maxLines > 1 ? 12 : 0),
              ),
            ),
          ),
          if (suffix != null) ...[const SizedBox(width: 8), suffix!],
        ],
      ),
    );
    if (floatLabel == null) return field;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        field,
        Positioned(
          left: 14,
          top: -9,
          child: Container(
            color: fill == AppColors.white ? AppColors.white : fill,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(floatLabel!,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: error ? AppColors.red : AppColors.blue)),
          ),
        ),
      ],
    );
  }
}

/// Switch kustom (aktif: biru + knob putih, nonaktif: abu + knob abu tua).
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const AppSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? AppColors.blue : const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: value ? AppColors.blue : AppColors.grey, width: 1.4),
        ),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
              color: value ? AppColors.white : AppColors.grey,
              shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Banner peringatan inline (merah muda).
class AlertBanner extends StatelessWidget {
  final String text;
  const AlertBanner(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33D70004)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, size: 22, color: Color(0xFFB71C1C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB71C1C))),
          ),
        ],
      ),
    );
  }
}

/// Kotak foto dengan garis putus-putus.
class DashedBox extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final VoidCallback? onTap;
  const DashedBox(
      {super.key,
      required this.child,
      required this.width,
      required this.height,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashPainter(),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
              color: UiColors.field, borderRadius: BorderRadius.circular(14)),
          child: child,
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(14));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = AppColors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 3), paint);
        d += 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Segmented pill (mis. Presentase | Manual, Tidak ada | Persen | Sisa).
class SegmentPill extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final double height;
  const SegmentPill({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: AppColors.blue, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) Container(width: 1, color: AppColors.blue),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  alignment: Alignment.center,
                  color: i == selected ? UiColors.blueSoft : AppColors.white,
                  child: Text(labels[i],
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: i == selected
                              ? AppColors.white
                              : const Color(0xFF14295C))),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dropdown satuan bergaya desain (panel dengan garis pemisah + tombol Tambah Satuan).
class UnitDropdown extends StatefulWidget {
  final List<String> items;
  final String? value;
  final ValueChanged<String> onSelected;
  final VoidCallback onAddUnit;
  final String label;
  final double height;
  const UnitDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onSelected,
    required this.onAddUnit,
    this.label = 'Satuan',
    this.height = 44,
  });

  @override
  State<UnitDropdown> createState() => _UnitDropdownState();
}

class _UnitDropdownState extends State<UnitDropdown> {
  final _link = LayerLink();
  OverlayEntry? _entry;
  bool get _open => _entry != null;

  void _toggle() => _open ? _close() : _show();

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  void _show() {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final pos = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    const panelH = 330.0;
    final below = screenH - (pos.dy + size.height) > panelH + 16;

    _entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: below ? Alignment.bottomLeft : Alignment.topLeft,
            followerAnchor: below ? Alignment.topLeft : Alignment.bottomLeft,
            offset: Offset(0, below ? 4 : -4),
            child: Align(
              alignment: below ? Alignment.topLeft : Alignment.bottomLeft,
              child: SizedBox(
                width: size.width < 130 ? 130 : size.width,
                child: Material(
                  color: AppColors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: AppColors.blue)),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: panelH),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final it in widget.items)
                            InkWell(
                              onTap: () {
                                widget.onSelected(it);
                                _close();
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: const BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: AppColors.blue, width: 0.8))),
                                child: Text(it,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black)),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Material(
                            color: AppColors.blue,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                _close();
                                widget.onAddUnit();
                              },
                              child: const Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                child: Text('Tambah\nSatuan',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 13,
                                        height: 1.25,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.blue, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.value ?? 'pcs',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black)),
                  ),
                  Icon(
                      _open
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: Colors.black),
                ],
              ),
            ),
            Positioned(
              left: 12,
              top: -9,
              child: Container(
                color: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(widget.label,
                    style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: AppColors.blue)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lingkaran berisi ikon (avatar kecil).
class IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color bg;
  final Color fg;
  const IconBadge(this.icon,
      {super.key,
      this.size = 40,
      this.bg = UiColors.blueTint,
      this.fg = AppColors.blue});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: size * 0.52, color: fg),
      );
}

/// Debounce sederhana.
class Debouncer {
  final Duration delay;
  Timer? _t;
  Debouncer([this.delay = const Duration(milliseconds: 250)]);
  void run(VoidCallback f) {
    _t?.cancel();
    _t = Timer(delay, f);
  }

  void dispose() => _t?.cancel();
}
