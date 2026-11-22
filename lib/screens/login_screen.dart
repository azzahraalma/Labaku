import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../services/auth_service.dart';
import 'forgot_dialogs.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  /// true
  final bool resume;
  const LoginScreen({super.key, this.resume = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService.instance;
  final _u = TextEditingController();
  final _b = TextEditingController();
  final _p = TextEditingController();
  bool _eu = false, _eb = false, _ep = false;
  bool _busy = false;

  bool get _filled =>
      _u.text.trim().isNotEmpty &&
      _b.text.trim().isNotEmpty &&
      _p.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.resume) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resume());
    }
  }

  @override
  void dispose() {
    _u.dispose();
    _b.dispose();
    _p.dispose();
    super.dispose();
  }

  Future<void> _resume() async {
    try {
      final prof = await _auth.myProfile();
      if (prof == null) {
        await _auth.signOut();
        return;
      }
      _u.text = prof.username;
      _b.text = prof.businessName ?? '';
      if (mounted) setState(() {});
      await _askPin();
    } catch (_) {
      await _auth.signOut();
    }
  }

  void _toast(String m) => showWarning(context, m);

  Future<void> _login() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_filled) {
      setState(() {
        _eu = _u.text.trim().isEmpty;
        _eb = _b.text.trim().isEmpty;
        _ep = _p.text.isEmpty;
      });
      _toast('Lengkapin data nya dulu yuk!');
      return;
    }
    setState(() => _busy = true);
    try {
      final c = await _auth.signIn(_u.text, _b.text, _p.text);
      if (!mounted) return;
      if (c != LoginCheck.ok) {
        final e = identityError(c);
        setState(() {
          _eu = e.user;
          _eb = e.biz;
          _ep = c == LoginCheck.bothInvalid;
          _busy = false;
        });
        _toast(e.message);
        return;
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _ep = true;
        _busy = false;
      });
      _toast(e.code == 'invalid_credentials'
          ? 'Password tidak valid'
          : 'Terjadi kesalahan, coba lagi ya');
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('Koneksi bermasalah, coba lagi ya');
      return;
    }
    setState(() => _busy = false);
    await _askPin();
  }

  Future<void> _askPin() async {
    var locked = false;
    final ok = await showPinSheet(
      context,
      title: 'Masukkan PIN',
      onForgot: () =>
          showAppDialog<void>(context, (_) => const ForgotPinDialog()),
      onSubmit: (pin) async {
        try {
          final r = await _auth.verifyPin(pin);
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
    if (ok) {
      await showResultDialog(context,
          title: 'Masuk Berhasil',
          message: 'Kamu akan segera diarahkan\nke halaman beranda');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      await _auth.signOut();
      if (locked && mounted) await showLockDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(title: 'Masuk'),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(34, 26, 34, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                      controller: _u,
                      label: 'Nama Pengguna',
                      error: _eu,
                      action: TextInputAction.next,
                      onChanged: (_) => setState(() => _eu = false)),
                  const SizedBox(height: 18),
                  AppTextField(
                      controller: _b,
                      label: 'Nama Usaha',
                      error: _eb,
                      action: TextInputAction.next,
                      onChanged: (_) => setState(() => _eb = false)),
                  const SizedBox(height: 18),
                  AppTextField(
                      controller: _p,
                      label: 'Password',
                      password: true,
                      error: _ep,
                      action: TextInputAction.done,
                      onChanged: (_) => setState(() => _ep = false)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showAppDialog<void>(
                          context, (_) => const ForgotPasswordDialog()),
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(8, 8, 6, 8),
                        child: Text('Lupa kata sandi?',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blue)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    text: 'Masuk',
                    loading: _busy,
                    style: _filled ? BtnStyle.primary : BtnStyle.disabledGrey,
                    onTap: _login,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Daftar usaha',
                    style: BtnStyle.outline,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const RegisterScreen())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
