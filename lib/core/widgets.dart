import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_config.dart';
import 'app_theme.dart';

/// ---------------------------------------------------------------- Header
class AuthHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  const AuthHeader({super.key, required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 196,
      decoration: const BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          if (onBack != null)
            Positioned(
              left: 18,
              top: MediaQuery.of(context).padding.top + 8,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back_rounded,
                      size: 26, color: AppColors.white),
                ),
              ),
            ),
          Align(
            alignment: const Alignment(0, 0.35),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 38,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.yellow)),
                const SizedBox(height: 6),
                const Text(
                  'Daftar atau masuk untuk\nmengakses fitur - fitur dalam aplikasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------- Text field
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final bool password;
  final bool error;
  final bool dense; // versi kecil untuk dialog
  final int maxLines;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final TextInputAction? action;

  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.password = false,
    this.error = false,
    this.dense = false,
    this.maxLines = 1,
    this.hint,
    this.onChanged,
    this.action,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final dense = widget.dense;
    final color = widget.error ? AppColors.red : AppColors.black;
    final h = widget.maxLines > 1 ? null : (dense ? 31.0 : 40.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: EdgeInsets.only(bottom: dense ? 1 : 6),
            child: Text(widget.label!,
                style: dense
                    ? const TextStyle(
                        fontSize: 13,
                        color: Colors.black,
                        fontWeight: FontWeight.w400)
                    : const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black)),
          ),
        Container(
          height: h,
          constraints:
              widget.maxLines > 1 ? const BoxConstraints(minHeight: 62) : null,
          padding: EdgeInsets.only(
              left: dense ? 8 : 11, right: widget.password ? 6 : 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(dense ? 6 : 7),
            border: Border.all(
                color: widget.error ? AppColors.red : AppColors.grey, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  obscureText: widget.password && _hidden,
                  obscuringCharacter: '●',
                  maxLines: widget.maxLines,
                  onChanged: widget.onChanged,
                  textInputAction: widget.action,
                  cursorColor: AppColors.blue,
                  style: TextStyle(fontSize: dense ? 13 : 15, color: color),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: const TextStyle(color: AppColors.grey),
                    contentPadding: EdgeInsets.symmetric(
                        vertical: widget.maxLines > 1 ? 10 : 0),
                  ),
                ),
              ),
              if (widget.password)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _hidden = !_hidden),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      _hidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: dense ? 18 : 22,
                      color: AppColors.black,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------- Buttons
enum BtnStyle { primary, disabledGrey, disabledSoft, outline }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final BtnStyle style;
  final bool loading;
  final double height;
  final double? width;
  final double fontSize;
  const AppButton({
    super.key,
    required this.text,
    required this.onTap,
    this.style = BtnStyle.primary,
    this.loading = false,
    this.height = 49,
    this.width,
    this.fontSize = 19,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    BorderSide? border;
    FontWeight fw = FontWeight.w700;
    switch (style) {
      case BtnStyle.primary:
        bg = AppColors.blue;
        fg = AppColors.white;
        break;
      case BtnStyle.disabledGrey: // tombol Masuk kosong
        bg = AppColors.surface;
        fg = AppColors.black;
        border = const BorderSide(color: AppColors.black, width: 1);
        break;
      case BtnStyle.disabledSoft: // Daftar / Simpan belum lengkap
        bg = AppColors.surface;
        fg = AppColors.grey;
        border = const BorderSide(color: AppColors.lightBlue, width: 1.5);
        break;
      case BtnStyle.outline:
        bg = AppColors.white;
        fg = Colors.black;
        border = const BorderSide(color: Colors.black, width: 1);
        fw = FontWeight.w500;
        break;
    }
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: Material(
        color: bg,
        shape: StadiumBorder(side: border ?? BorderSide.none),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: loading ? null : onTap,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2.5, color: fg))
                : Text(text,
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: fw, color: fg)),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------- Warning toast
class _Toast {
  static OverlayEntry? entry;
  static Timer? timer;
}

void showWarning(BuildContext context, String message, {double top = 193}) {
  _Toast.timer?.cancel();
  _Toast.entry?.remove();
  final overlay = Overlay.of(context, rootOverlay: true);
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      top: top,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Material(
            color: AppColors.redSoft,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error,
                      size: 22, color: Color(0xFFB71C1C)),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(message,
                        style: const TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFFB71C1C),
                            fontWeight: FontWeight.w400)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  _Toast.entry = entry;
  overlay.insert(entry);
  _Toast.timer = Timer(const Duration(seconds: 3), () {
    entry.remove();
    if (_Toast.entry == entry) _Toast.entry = null;
  });
}

/// ---------------------------------------------------------------- PIN
class PinBoxes extends StatelessWidget {
  final String value;
  final bool error;
  final double boxW;
  final double boxH;
  final double gap;
  final bool filled;
  const PinBoxes({
    super.key,
    required this.value,
    this.error = false,
    this.boxW = 38,
    this.boxH = 40,
    this.gap = 9,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(AppConfig.pinLength, (i) {
        final c = i < value.length ? value[i] : '';
        return Container(
          width: boxW,
          height: boxH,
          margin:
              EdgeInsets.only(right: i == AppConfig.pinLength - 1 ? 0 : gap),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: error ? AppColors.red : AppColors.grey, width: 1),
          ),
          child: Text(c,
              style: TextStyle(
                  fontSize: boxH * 0.55,
                  fontWeight: FontWeight.w500,
                  color: error ? AppColors.black : AppColors.black)),
        );
      }),
    );
  }
}

/// Kotak 6 digit PIN yang bisa di-tap untuk memunculkan keypad di bawah dialog
/// tanpa menumpuk atau menduplikasi kotak PIN.
class PinBoxField extends StatelessWidget {
  final String value;
  final bool active;
  final bool error;
  final VoidCallback onTap;
  const PinBoxField({
    super.key,
    required this.value,
    this.active = false,
    this.error = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (_, cs) {
          const n = AppConfig.pinLength;
          const gap = 8.0;
          final w = (cs.maxWidth - gap * (n - 1)) / n;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(n, (i) {
              final c = i < value.length ? value[i] : '';
              final isCursor = active && i == value.length;
              return Container(
                width: w,
                height: 42,
                margin: EdgeInsets.only(right: i == n - 1 ? 0 : gap),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: error
                        ? AppColors.red
                        : (active ? AppColors.blue : AppColors.grey),
                    width: (active || isCursor) ? 1.6 : 1,
                  ),
                ),
                child: Text(
                  c,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Hanya panel keypad numerik (1-9, 0, hapus) — tanpa duplikasi judul/kotak PIN.
class PinKeypadPanel extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClose;
  const PinKeypadPanel({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onClose,
  });

  Widget _key(String d) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 4.5),
          child: Material(
            color: AppColors.keypad,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                HapticFeedback.selectionClick();
                onDigit(d);
              },
              child: SizedBox(
                height: 48,
                child: Center(
                  child: Text(d,
                      style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A4A4A))),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _row(List<String> ds) => Row(children: ds.map(_key).toList());

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Icon(Icons.keyboard_hide_rounded,
                        size: 22, color: AppColors.grey),
                  ),
                ),
              ),
              _row(['1', '2', '3']),
              _row(['4', '5', '6']),
              _row(['7', '8', '9']),
              Row(children: [
                const Expanded(child: SizedBox()),
                _key('0'),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onBackspace,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.backspace_rounded,
                            size: 28, color: AppColors.grey),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper dialog yang otomatis menaikkan kartu dialog saat keypad PIN muncul
/// sehingga tidak pernah menumpuk atau terpotong.
class PinDialogShell extends StatelessWidget {
  final Widget child;
  final bool showKeypad;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onCloseKeypad;
  final EdgeInsets cardPadding;
  final double horizontalInset;
  const PinDialogShell({
    super.key,
    required this.child,
    required this.showKeypad,
    required this.onDigit,
    required this.onBackspace,
    required this.onCloseKeypad,
    this.cardPadding = const EdgeInsets.fromLTRB(20, 16, 20, 20),
    this.horizontalInset = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: !showKeypad,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontalInset, vertical: 12),
                  child: Material(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      padding: cardPadding,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showKeypad)
            PinKeypadPanel(
              onDigit: onDigit,
              onBackspace: onBackspace,
              onClose: onCloseKeypad,
            ),
        ],
      ),
    );
  }
}

class PinOutcome {
  final String? error;
  final bool close; // tutup sheet
  final bool success;
  const PinOutcome._(this.error, this.close, this.success);
  const PinOutcome.success() : this._(null, true, true);
  const PinOutcome.fail(String message) : this._(message, false, false);
  const PinOutcome.dismiss() : this._(null, true, false);
}

/// Bottom sheet keypad PIN. Return true bila sukses.
Future<bool> showPinSheet(
  BuildContext context, {
  required String title,
  required Future<PinOutcome> Function(String pin) onSubmit,
  VoidCallback? onForgot,
}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    barrierColor: AppColors.overlay,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (_) =>
        _PinSheet(title: title, onSubmit: onSubmit, onForgot: onForgot),
  );
  return r == true;
}

class _PinSheet extends StatefulWidget {
  final String title;
  final Future<PinOutcome> Function(String) onSubmit;
  final VoidCallback? onForgot;
  const _PinSheet({required this.title, required this.onSubmit, this.onForgot});

  @override
  State<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<_PinSheet> {
  String _pin = '';
  String? _error;
  bool _busy = false;

  Future<void> _tap(String d) async {
    if (_busy || _pin.length >= AppConfig.pinLength) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == AppConfig.pinLength) {
      setState(() => _busy = true);
      final out = await widget.onSubmit(_pin);
      if (!mounted) return;
      if (out.close) {
        Navigator.of(context, rootNavigator: true).pop(out.success);
        return;
      }
      setState(() {
        _busy = false;
        _error = out.error;
        _pin = '';
      });
    }
  }

  void _back() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Widget _key(String d) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 5),
          child: Material(
            color: AppColors.keypad,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _tap(d),
              child: SizedBox(
                height: 52,
                child: Center(
                  child: Text(d,
                      style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A4A4A))),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _row(List<String> ds) => Row(children: ds.map(_key).toList());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(19, 12, 19, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    Navigator.of(context, rootNavigator: true).pop(false),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded,
                      size: 22, color: AppColors.black),
                ),
              ),
            ),
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A))),
            const SizedBox(height: 8),
            PinBoxes(value: _pin, error: _error != null),
            SizedBox(
              height: 44,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(
                            fontSize: 13.5, color: AppColors.red)),
                  if (widget.onForgot != null)
                    GestureDetector(
                      onTap: widget.onForgot,
                      child: const Text('Lupa PIN Kamu?',
                          style: TextStyle(
                              fontSize: 14.5,
                              color: AppColors.blue,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.blue)),
                    ),
                ],
              ),
            ),
            _row(['1', '2', '3']),
            _row(['4', '5', '6']),
            _row(['7', '8', '9']),
            Row(children: [
              const Expanded(child: SizedBox()),
              _key('0'),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _back,
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Icon(Icons.backspace_rounded,
                          size: 30, color: AppColors.grey),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------- Dialogs
class AppDialogCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const AppDialogCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 20)});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 44, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(padding: padding, child: child),
    );
  }
}

class DialogTitleRow extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  const DialogTitleRow({super.key, required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A4A4A))),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.close_rounded, size: 24, color: Colors.black),
          ),
        ),
      ],
    );
  }
}

Future<T?> showAppDialog<T>(BuildContext context, WidgetBuilder builder,
    {bool dismissible = false}) {
  return showDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: dismissible,
    barrierColor: AppColors.overlay,
    builder: builder,
  );
}

class _CheckBadge extends StatelessWidget {
  final double size;
  const _CheckBadge({required this.size});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.blue,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          color: AppColors.white,
          size: size * 0.62,
        ),
      );
}

class _PinLimitBadge extends StatelessWidget {
  final double size;
  const _PinLimitBadge({required this.size});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: size * 0.08,
              bottom: size * 0.08,
              child: Icon(
                Icons.sentiment_satisfied_alt_rounded,
                size: size * 0.7,
                color: AppColors.blue,
              ),
            ),
            Positioned(
              left: size * 0.06,
              top: size * 0.08,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pan_tool_outlined,
                  size: size * 0.42,
                  color: AppColors.blue,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Dialog hasil: judul + ikon + pesan. Tutup otomatis jika [autoClose] diisi.
class ResultDialog extends StatefulWidget {
  final String title;
  final String message;
  final bool success;
  final Duration? autoClose;
  const ResultDialog({
    super.key,
    required this.title,
    required this.message,
    this.success = true,
    this.autoClose,
  });

  @override
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.autoClose != null) {
      _t = Timer(widget.autoClose!, () {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.autoClose == null,
      child: AppDialogCard(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A4A4A))),
            const SizedBox(height: 22),
            widget.success
                ? const _CheckBadge(size: 116)
                : const _PinLimitBadge(size: 116),
            const SizedBox(height: 22),
            Text(widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, height: 1.45, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}

Future<void> showResultDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool success = true,
  Duration? autoClose = const Duration(milliseconds: 1800),
}) {
  return showAppDialog<void>(
    context,
    (_) => ResultDialog(
        title: title, message: message, success: success, autoClose: autoClose),
    dismissible: autoClose == null,
  );
}

/// Dialog konfirmasi hapus sesuai desain ("Yakin ingin menghapus?").
Future<bool> showConfirmDeleteDialog(BuildContext context) =>
    showConfirmActionDialog(
      context,
      title: 'Yakin ingin menghapus?',
      cancelText: 'Tidak, kembali',
      confirmText: 'Ya, hapus',
    );

/// Dialog konfirmasi keluar akun (gaya sama dengan konfirmasi hapus).
Future<bool> showConfirmLogoutDialog(BuildContext context) =>
    showConfirmActionDialog(
      context,
      title: 'Yakin ingin keluar?',
      cancelText: 'Tidak, kembali',
      confirmText: 'Ya, keluar',
    );

Future<bool> showConfirmActionDialog(
  BuildContext context, {
  required String title,
  required String cancelText,
  required String confirmText,
}) async {
  final r = await showAppDialog<bool>(
    context,
    (ctx) => AppDialogCard(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.red,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Material(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(ctx, rootNavigator: true).pop(false),
                child: Center(
                  child: Text(
                    cancelText,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Material(
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.red, width: 1.3),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(ctx, rootNavigator: true).pop(true),
                child: Center(
                  child: Text(
                    confirmText,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    dismissible: true,
  );
  return r == true;
}
