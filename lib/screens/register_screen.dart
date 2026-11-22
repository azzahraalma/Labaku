import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_config.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'terms_screen.dart';

Future<Uint8List?> _pickImage() async {
  try {
    final f = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70);
    return f == null ? null : await f.readAsBytes();
  } catch (_) {
    return null;
  }
}

class BusinessData {
  final String name;
  final String description;
  final String category;
  final Uint8List? logo;
  const BusinessData(this.name, this.description, this.category, this.logo);
}

// REGISTER SCREEN
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = AuthService.instance;
  final _u = TextEditingController();
  final _p = TextEditingController();
  Uint8List? _avatar;
  BusinessData? _biz;
  bool _agree = false;
  bool _eu = false, _eb = false, _ep = false;
  bool _busy = false;

  bool get _complete =>
      _u.text.trim().isNotEmpty && _biz != null && _p.text.isNotEmpty;

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    super.dispose();
  }

  void _toast(String m) => showWarning(context, m);

  Future<void> _editBusiness() async {
    final r = await showAppDialog<BusinessData>(
        context, (_) => BusinessDialog(initial: _biz));
    if (r != null) {
      setState(() {
        _biz = r;
        _eb = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_complete) {
      setState(() {
        _eu = _u.text.trim().isEmpty;
        _eb = _biz == null;
        _ep = _p.text.isEmpty;
      });
      _toast('Lengkapin data nya dulu ya!');
      return;
    }
    if (_p.text.length < AppConfig.minPasswordLength) {
      setState(() => _ep = true);
      _toast('Password minimal ${AppConfig.minPasswordLength} karakter');
      return;
    }
    if (!_agree) {
      _toast('kamu belum menyetujui S&K');
      return;
    }

    setState(() => _busy = true);
    try {
      if (!await _auth.businessAvailable(_biz!.name)) {
        if (!mounted) return;
        setState(() {
          _eb = true;
          _busy = false;
        });
        _toast('Nama usaha sudah dipakai');
        return;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('Koneksi bermasalah, coba lagi ya');
      return;
    }
    setState(() => _busy = false);
    if (!mounted) return;

    // Buat PIN 
    String? first;
    final created =
        await showPinSheet(context, title: 'Buat PIN', onSubmit: (pin) async {
      first = pin;
      return const PinOutcome.success();
    });
    if (!created || first == null || !mounted) return;
    final confirmed = await showPinSheet(context, title: 'Konfirmasi PIN',
        onSubmit: (pin) async {
      return pin == first
          ? const PinOutcome.success()
          : const PinOutcome.fail('PIN tidak cocok');
    });
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await _auth.registerOwner(
        username: _u.text,
        password: _p.text,
        pin: first!,
        businessName: _biz!.name,
        category: _biz!.category,
        description: _biz!.description,
        avatar: _avatar,
        logo: _biz!.logo,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (!context.mounted) return;
      await showResultDialog(context,
          title: 'Daftar Berhasil',
          message: 'Kamu akan segera diarahkan\nke halaman beranda');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      switch (e.code) {
        case 'business_taken':
          setState(() => _eb = true);
          _toast('Nama usaha sudah dipakai');
          break;
        case 'user_taken':
          setState(() => _eu = true);
          _toast('Nama pengguna sudah dipakai');
          break;
        default:
          _toast(e.message.isEmpty
              ? 'Terjadi kesalahan, coba lagi ya'
              : e.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast('Koneksi bermasalah, coba lagi ya');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      body: Column(
        children: [
          AuthHeader(
              title: 'Daftar', onBack: () => Navigator.of(context).maybePop()),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(34, 22, 34, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(children: [
                      PhotoPicker(
                        bytes: _avatar,
                        size: 98,
                        icon: Icons.person,
                        bg: const Color(0xFFD9D9D9),
                        onTap: () async {
                          final b = await _pickImage();
                          if (b != null) setState(() => _avatar = b);
                        },
                      ),
                      const SizedBox(height: 6),
                      const Text('Tambah Foto Profil',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black)),
                    ]),
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                      controller: _u,
                      label: 'Nama Pengguna',
                      error: _eu,
                      action: TextInputAction.next,
                      onChanged: (_) => setState(() => _eu = false)),
                  const SizedBox(height: 18),
                  Text(_biz == null ? 'Nama Usaha' : 'Tambah Usaha',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black)),
                  const SizedBox(height: 6),
                  SelectTile(
                    icon: Icons.storefront_outlined,
                    title: _biz?.name,
                    subtitle: _biz == null
                        ? 'Ketuk untuk buat usaha'
                        : 'Tap untuk mengubah',
                    error: _eb,
                    onTap: _editBusiness,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                      controller: _p,
                      label: 'Password',
                      password: true,
                      error: _ep,
                      onChanged: (_) => setState(() => _ep = false)),
                  const SizedBox(height: 14),
                  if (_complete) _termsRow() else _haveAccountRow(),
                  const SizedBox(height: 18),
                  AppButton(
                    text: 'Daftar',
                    loading: _busy,
                    style: _complete ? BtnStyle.primary : BtnStyle.disabledSoft,
                    onTap: _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _haveAccountRow() => Center(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Sudah punya akun?',
                style: TextStyle(fontSize: 15.5, color: AppColors.grey)),
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Text('Masuk',
                  style: TextStyle(
                      fontSize: 15.5,
                      color: AppColors.blue,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.blue)),
            ),
          ],
        ),
      );

  Widget _termsRow() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _agree = !_agree),
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.black, width: 1.4)),
              child: _agree
                  ? const Icon(Icons.check, size: 17, color: Colors.black)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dengan mendaftar saya setuju dengan',
                    style: TextStyle(fontSize: 14.5, color: Colors.black)),
                GestureDetector(
                  onTap: () async {
                    final agreed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const TermsScreen(showAgreeButton: true),
                      ),
                    );
                    if (agreed == true && mounted) {
                      setState(() => _agree = true);
                    }
                  },
                  child: const Text('Syarat dan Ketentuan',
                      style: TextStyle(
                          fontSize: 14.5,
                          color: AppColors.blue,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.blue)),
                ),
              ],
            ),
          ),
        ],
      );
}

// Widget bersama
class PhotoPicker extends StatelessWidget {
  final Uint8List? bytes;
  final double size;
  final IconData icon;
  final Color bg;
  final VoidCallback onTap;
  const PhotoPicker({
    super.key,
    required this.bytes,
    required this.size,
    required this.icon,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 16,
        height: size + 8,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: size,
                height: size,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
                child: bytes != null
                    ? Image.memory(bytes!,
                        fit: BoxFit.cover, gaplessPlayback: true)
                    : Center(
                        child: Icon(
                          icon,
                          size: size * 0.52,
                          color: const Color(0xFF666666),
                        ),
                      ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 25,
                height: 25,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.blue),
                child: const Icon(Icons.add, size: 18, color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectTile extends StatelessWidget {
  final IconData icon;
  final String? title; 
  final String subtitle;
  final bool error;
  final VoidCallback onTap;
  const SelectTile({
    super.key,
    required this.icon,
    this.title,
    required this.subtitle,
    required this.onTap,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: error ? AppColors.red : AppColors.grey),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: const Color(0xFFB9C7E0),
                  borderRadius: BorderRadius.circular(4)),
              child: Icon(icon, size: 24, color: AppColors.black),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15.5,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: title == null ? 14 : 13,
                          height: 1.2,
                          fontWeight:
                              title == null ? FontWeight.w500 : FontWeight.w400,
                          color: Colors.black)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black, size: 26),
          ],
        ),
      ),
    );
  }
}

// Buat Usaha
class BusinessDialog extends StatefulWidget {
  final BusinessData? initial;
  const BusinessDialog({super.key, this.initial});

  @override
  State<BusinessDialog> createState() => _BusinessDialogState();
}

class _BusinessDialogState extends State<BusinessDialog> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _desc = TextEditingController(text: widget.initial?.description);
  late String? _cat = widget.initial?.category;
  late Uint8List? _logo = widget.initial?.logo;
  bool _en = false, _ec = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  bool get _complete => _name.text.trim().isNotEmpty && _cat != null;

  Future<void> _pickCategory() async {
    final r = await showAppDialog<String>(
        context, (_) => const CategoryDialog(),
        dismissible: true);
    if (r != null) {
      setState(() {
        _cat = r;
        _ec = false;
      });
    }
  }

  void _save() {
    if (!_complete) {
      setState(() {
        _en = _name.text.trim().isEmpty;
        _ec = _cat == null;
      });
      showWarning(context, 'Lengkapin data nya dulu ya!', top: 207);
      return;
    }
    Navigator.of(context, rootNavigator: true)
        .pop(BusinessData(_name.text.trim(), _desc.text.trim(), _cat!, _logo));
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogCard(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('Logo Usaha (Opsional)',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black)),
            ),
            const SizedBox(height: 8),
            Center(
              child: PhotoPicker(
                bytes: _logo,
                size: 84,
                icon: Icons.storefront_outlined,
                bg: const Color(0xFFEDEDED),
                onTap: () async {
                  final b = await _pickImage();
                  if (b != null) setState(() => _logo = b);
                },
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
                controller: _name,
                label: 'Nama Usaha',
                error: _en,
                dense: true,
                onChanged: (_) => setState(() => _en = false)),
            const SizedBox(height: 14),
            AppTextField(
                controller: _desc,
                label: 'Deskripsi Usaha',
                dense: true,
                maxLines: 4),
            const SizedBox(height: 14),
            const Text('Kategori Usaha',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black)),
            const SizedBox(height: 6),
            SelectTile(
              icon: Icons.grid_view_rounded,
              subtitle: _cat ?? 'Pilih Kategori',
              error: _ec,
              onTap: _pickCategory,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 33,
                  child: AppButton(
                    text: 'Batal',
                    height: 38,
                    fontSize: 16,
                    style: BtnStyle.outline,
                    onTap: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 50,
                  child: AppButton(
                    text: 'Simpan',
                    height: 38,
                    fontSize: 16,
                    style: _complete ? BtnStyle.primary : BtnStyle.disabledSoft,
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

// DIALOG: Pilih Kategori (+ Kategori Lainnya)
class CategoryDialog extends StatelessWidget {
  const CategoryDialog({super.key});

  static const _items = [
    ('Kuliner/F&B', Icons.fastfood_rounded),
    ('Retail/Toko', Icons.shopping_bag_rounded),
    ('Jasa', Icons.handshake_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    void close([String? v]) =>
        Navigator.of(context, rootNavigator: true).pop(v);
    return AppDialogCard(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DialogTitleRow(title: 'Pilih Kategori', onClose: close),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (_, cs) {
            final w = (cs.maxWidth - 11) / 2;
            return Wrap(
              spacing: 11,
              runSpacing: 11,
              children: [
                for (final it in _items)
                  GestureDetector(
                    onTap: () => close(it.$1),
                    child: Container(
                      width: w,
                      height: w,
                      decoration: BoxDecoration(
                          color: const Color(0xFFEDEDED),
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(it.$2,
                              size: 44, color: const Color(0xFF6B6B6B)),
                          const SizedBox(height: 8),
                          Text(it.$1,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () async {
              final r = await showAppDialog<String>(
                  context, (_) => const CustomCategoryDialog());
              if (r != null) close(r);
            },
            child: Container(
              height: 33,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 1)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 18, color: AppColors.black),
                  SizedBox(width: 8),
                  Text('Tambah Kategori',
                      style: TextStyle(fontSize: 14.5, color: AppColors.black)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomCategoryDialog extends StatefulWidget {
  const CustomCategoryDialog({super.key});

  @override
  State<CustomCategoryDialog> createState() => _CustomCategoryDialogState();
}

class _CustomCategoryDialogState extends State<CustomCategoryDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _ok => _c.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AppDialogCard(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DialogTitleRow(
              title: 'Kategori Lainnya',
              onClose: () => Navigator.of(context, rootNavigator: true).pop()),
          const SizedBox(height: 14),
          const Text('Masukkan nama kategori usaha',
              style: TextStyle(fontSize: 14.5, color: Colors.black)),
          const SizedBox(height: 10),
          Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.grey)),
            child: Row(
              children: [
                const Icon(Icons.grid_view_rounded,
                    size: 20, color: AppColors.black),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _c,
                    onChanged: (_) => setState(() {}),
                    maxLines: 2,
                    minLines: 1,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Contoh:\nKerajinan',
                      hintStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppButton(
                text: 'Batal',
                width: 76,
                height: 31,
                fontSize: 14,
                style: BtnStyle.outline,
                onTap: () => Navigator.of(context, rootNavigator: true).pop(),
              ),
              const SizedBox(width: 14),
              AppButton(
                text: 'Simpan',
                width: 113,
                height: 31,
                fontSize: 14,
                style: _ok ? BtnStyle.primary : BtnStyle.disabledSoft,
                onTap: () {
                  if (_ok) {
                    Navigator.of(context, rootNavigator: true)
                        .pop(_c.text.trim());
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
