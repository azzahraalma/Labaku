import 'package:flutter/material.dart';

import '../core/widgets.dart';
import '../services/auth_service.dart';

const kLockMessage =
    'Kamu sudah mencapai batas 3 kali percobaan, coba lagi dalam 5 menit untuk masukkan PIN.';

Future<void> showLockDialog(BuildContext context) => showResultDialog(
      context,
      title: 'Ingat Lagi PIN Kamu',
      message: kLockMessage,
      success: false,
      autoClose: null,
    );

String pinFailMessage(int left) => 'PIN tidak valid, tersedia $left percobaan';

({String message, bool user, bool biz}) identityError(LoginCheck c) {
  switch (c) {
    case LoginCheck.userInvalid:
      return (message: 'Nama pengguna tidak valid', user: true, biz: false);
    case LoginCheck.businessInvalid:
      return (message: 'Nama usaha tidak valid', user: false, biz: true);
    default:
      return (message: 'Data tidak valid, cek lagi ya!', user: true, biz: true);
  }
}

const double _toastTop = 163;

// LUPA PIN  
class ForgotPinDialog extends StatefulWidget {
  const ForgotPinDialog({super.key});

  @override
  State<ForgotPinDialog> createState() => _ForgotPinDialogState();
}

class _ForgotPinDialogState extends State<ForgotPinDialog> {
  final _u = TextEditingController();
  final _b = TextEditingController();
  final _p = TextEditingController();
  String _pin = '';
  String _pin2 = '';
  int? _activePin;
  bool _eu = false, _eb = false, _ep = false, _epin = false;
  bool _busy = false;

  void _onDigit(String d) {
    setState(() {
      _epin = false;
      if (_activePin == 0 && _pin.length < 6) {
        _pin += d;
        if (_pin.length == 6) _activePin = 1;
      } else if (_activePin == 1 && _pin2.length < 6) {
        _pin2 += d;
        if (_pin2.length == 6) _activePin = null;
      }
    });
  }

  void _onBack() {
    setState(() {
      if (_activePin == 0 && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      } else if (_activePin == 1 && _pin2.isNotEmpty) {
        _pin2 = _pin2.substring(0, _pin2.length - 1);
      }
    });
  }

  @override
  void dispose() {
    _u.dispose();
    _b.dispose();
    _p.dispose();
    super.dispose();
  }

  bool get _complete =>
      _u.text.trim().isNotEmpty &&
      _b.text.trim().isNotEmpty &&
      _p.text.isNotEmpty &&
      _pin.length == 6 &&
      _pin2.length == 6;

  Future<void> _save() async {
    if (_busy) return;
    if (!_complete) {
      setState(() {
        _eu = _u.text.trim().isEmpty;
        _eb = _b.text.trim().isEmpty;
        _ep = _p.text.isEmpty;
        _epin = _pin.length < 6 || _pin2.length < 6;
      });
      showWarning(context, 'Lengkapin data nya dulu yuk!', top: _toastTop);
      return;
    }
    if (_pin != _pin2) {
      setState(() => _epin = true);
      showWarning(context, 'PIN tidak cocok', top: _toastTop);
      return;
    }
    setState(() => _busy = true);
    try {
      final c =
          await AuthService.instance.resetPin(_u.text, _b.text, _p.text, _pin);
      if (!mounted) return;
      if (c != LoginCheck.ok) {
        final e = identityError(c);
        setState(() {
          _eu = e.user;
          _eb = e.biz;
        });
        if (!mounted) return;
        showWarning(context, e.message, top: _toastTop);
      } else {
        if (!mounted) return;
        final nav = Navigator.of(context, rootNavigator: true);
        nav.pop();
        showResultDialog(context,
            title: 'PIN Berhasil Diubah',
            message: 'Yuk masuk lagi dengan PIN kamu yang baru!');
        return;
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _ep = true);
      showWarning(
          context,
          e.code == 'invalid_credentials'
              ? 'Password tidak valid'
              : 'Terjadi kesalahan, coba lagi ya',
          top: _toastTop);
    } catch (_) {
      if (mounted) {
        showWarning(context, 'Koneksi bermasalah, coba lagi ya',
            top: _toastTop);
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return PinDialogShell(
      showKeypad: _activePin != null,
      onDigit: _onDigit,
      onBackspace: _onBack,
      onCloseKeypad: () => setState(() => _activePin = null),
      cardPadding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DialogTitleRow(
              title: 'Lupa Pin',
              onClose: () =>
                  Navigator.of(context, rootNavigator: true).pop()),
          const SizedBox(height: 4),
          AppTextField(
              controller: _u,
              label: 'Nama Pengguna',
              dense: true,
              error: _eu,
              onChanged: (_) => setState(() {
                    _eu = false;
                    _activePin = null;
                  })),
          const SizedBox(height: 8),
          AppTextField(
              controller: _b,
              label: 'Nama Usaha',
              dense: true,
              error: _eb,
              onChanged: (_) => setState(() {
                    _eb = false;
                    _activePin = null;
                  })),
          const SizedBox(height: 8),
          AppTextField(
              controller: _p,
              label: 'Kata Sandi',
              dense: true,
              password: true,
              error: _ep,
              onChanged: (_) => setState(() {
                    _ep = false;
                    _activePin = null;
                  })),
          const SizedBox(height: 8),
          const Text('Pin Baru', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 2),
          PinBoxField(
            value: _pin,
            active: _activePin == 0,
            error: _epin,
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _activePin = 0);
            },
          ),
          const SizedBox(height: 8),
          const Text('Konfirmasi PIN', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 2),
          PinBoxField(
            value: _pin2,
            active: _activePin == 1,
            error: _epin,
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _activePin = 1);
            },
          ),
          const SizedBox(height: 22),
          Center(
            child: AppButton(
              text: 'Simpan',
              width: 113,
              height: 31,
              fontSize: 14,
              loading: _busy,
              style: _complete ? BtnStyle.primary : BtnStyle.disabledSoft,
              onTap: _save,
            ),
          ),
        ],
      ),
    );
  }
}

// LUPA KATA SANDI  
class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _u = TextEditingController();
  final _b = TextEditingController();
  final _p = TextEditingController();
  final _p2 = TextEditingController();
  bool _eu = false, _eb = false, _ep = false, _ep2 = false;
  bool _busy = false;

  @override
  void dispose() {
    _u.dispose();
    _b.dispose();
    _p.dispose();
    _p2.dispose();
    super.dispose();
  }

  bool get _complete =>
      _u.text.trim().isNotEmpty &&
      _b.text.trim().isNotEmpty &&
      _p.text.isNotEmpty &&
      _p2.text.isNotEmpty;

  Future<void> _save() async {
    if (_busy) return;
    if (!_complete) {
      setState(() {
        _eu = _u.text.trim().isEmpty;
        _eb = _b.text.trim().isEmpty;
        _ep = _p.text.isEmpty;
        _ep2 = _p2.text.isEmpty;
      });
      showWarning(context, 'Lengkapin data nya dulu yuk!', top: _toastTop);
      return;
    }
    if (_p.text.length < 6) {
      setState(() => _ep = true);
      showWarning(context, 'Kata sandi minimal 6 karakter', top: _toastTop);
      return;
    }
    if (_p.text != _p2.text) {
      setState(() => _ep = _ep2 = true);
      showWarning(context, 'Kata sandi tidak cocok', top: _toastTop);
      return;
    }
    setState(() => _busy = true);
    try {
      final c = await AuthService.instance.precheckIdentity(_u.text, _b.text);
      if (!mounted) return;
      if (c != LoginCheck.ok) {
        final e = identityError(c);
        setState(() {
          _eu = e.user;
          _eb = e.biz;
          _busy = false;
        });
        showWarning(context, e.message, top: _toastTop);
        return;
      }
      setState(() => _busy = false);

      var locked = false;
      final ok = await showPinSheet(
        context,
        title: 'Masukkan PIN',
        onSubmit: (pin) async {
          try {
            final r = await AuthService.instance
                .resetPassword(_u.text, _b.text, pin, _p.text);
            if (r.ok) return const PinOutcome.success();
            if (r.locked) {
              locked = true;
              return const PinOutcome.dismiss();
            }
            return PinOutcome.fail(pinFailMessage(r.attemptsLeft));
          } catch (_) {
            return const PinOutcome.fail('Koneksi bermasalah, coba lagi ya');
          }
        },
      );
      if (!mounted) return;
      final nav = Navigator.of(context, rootNavigator: true);
      final ctx = nav.context;
      if (!ctx.mounted) return;
      if (ok) {
        nav.pop();
        showResultDialog(ctx,
            title: 'Kata Sandi Berhasil Diubah',
            message: 'Yuk masuk lagi dengan kata sandi kamu yang baru!');
      } else if (locked) {
        nav.pop();
        showLockDialog(ctx);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showWarning(context, 'Koneksi bermasalah, coba lagi ya',
            top: _toastTop);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogCard(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DialogTitleRow(
                title: 'Lupa Kata Sandi',
                onClose: () =>
                    Navigator.of(context, rootNavigator: true).pop()),
            const SizedBox(height: 4),
            AppTextField(
                controller: _u,
                label: 'Nama Pengguna',
                dense: true,
                error: _eu,
                onChanged: (_) => setState(() => _eu = false)),
            const SizedBox(height: 8),
            AppTextField(
                controller: _b,
                label: 'Nama Usaha',
                dense: true,
                error: _eb,
                onChanged: (_) => setState(() => _eb = false)),
            const SizedBox(height: 8),
            AppTextField(
                controller: _p,
                label: 'Kata Sandi Baru',
                dense: true,
                password: true,
                error: _ep,
                onChanged: (_) => setState(() => _ep = false)),
            const SizedBox(height: 8),
            AppTextField(
                controller: _p2,
                label: 'Konfirmasi Kata Sandi',
                dense: true,
                password: true,
                error: _ep2,
                onChanged: (_) => setState(() => _ep2 = false)),
            const SizedBox(height: 22),
            Center(
              child: AppButton(
                text: 'Simpan',
                width: 113,
                height: 31,
                fontSize: 14,
                loading: _busy,
                style: _complete ? BtnStyle.primary : BtnStyle.disabledSoft,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
