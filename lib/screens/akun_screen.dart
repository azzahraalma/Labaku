import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_theme.dart';
import '../core/format.dart';
import '../core/ui_kit.dart';
import '../core/widgets.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import 'terms_screen.dart';
import 'wizard/labor_dialog.dart';
import 'wizard/wizard_dialogs.dart';

Future<Uint8List?> _pickPhoto() async {
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

// AKUN (Bos) 
class AkunTab extends StatelessWidget {
  final VoidCallback onLogout;
  const AkunTab({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final h = DataService.instance.home;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        const Text('Akun',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.blue)),
        const SizedBox(height: 20),
        Center(child: _AvatarCircle(url: h?.fotoUrl, size: 96)),
        const SizedBox(height: 12),
        Center(
          child: Text(h?.username ?? '-',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black)),
        ),
        const SizedBox(height: 24),
        _menuCard(
          icon: Icons.person_rounded,
          iconBg: UiColors.blueTint,
          iconFg: AppColors.blue,
          title: 'Profil',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfilSayaScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _menuCard(
          icon: Icons.storefront_rounded,
          iconBg: const Color(0xFFFCE29F),
          iconFg: AppColors.blue,
          title: 'Lihat Usaha',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UsahaSayaScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _menuCard(
          icon: Icons.description_rounded,
          iconBg: UiColors.lavender,
          iconFg: AppColors.blue,
          title: 'Syarat & Ketentuan',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TermsScreen()),
          ),
        ),
        const SizedBox(height: 60),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: onLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              backgroundColor: AppColors.white,
              side: const BorderSide(color: AppColors.red, width: 1),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Log Out',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _menuCard({
    required IconData icon,
    required Color iconBg,
    required Color iconFg,
    required String title,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.blue, width: 1.2),
          ),
          child: Row(
            children: [
              IconBadge(icon, size: 42, bg: iconBg, fg: iconFg),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black)),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 22, color: AppColors.black),
            ],
          ),
        ),
      );
}

// PROFIL 
class ProfilSayaScreen extends StatelessWidget {
  const ProfilSayaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = DataService.instance;
    return ListenableBuilder(
      listenable: ds,
      builder: (_, __) {
        final h = ds.home;
        return _SubPage(
          title: 'Profil Saya',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            children: [
              Center(child: _AvatarCircle(url: h?.fotoUrl, size: 96)),
              const SizedBox(height: 12),
              Center(
                child: Text(h?.username ?? '-',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black)),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: UiColors.shadow,
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nama',
                        style:
                            TextStyle(fontSize: 12, color: UiColors.textMute)),
                    const SizedBox(height: 4),
                    Text(h?.username ?? '-',
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.black)),
                    const Divider(height: 22, color: AppColors.blue),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const UbahProfilScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 26, vertical: 10),
                          decoration: BoxDecoration(
                            color: UiColors.chipGrey,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded,
                                  size: 18, color: AppColors.black),
                              SizedBox(width: 8),
                              Text('Ubah Profil',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.black)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// UBAH PROFIL (Bos)
class UbahProfilScreen extends StatefulWidget {
  const UbahProfilScreen({super.key});

  @override
  State<UbahProfilScreen> createState() => _UbahProfilScreenState();
}

class _UbahProfilScreenState extends State<UbahProfilScreen> {
  final _ds = DataService.instance;
  late final _nama = TextEditingController(text: _ds.home?.username ?? '');
  final _passMask = TextEditingController(text: '••••••••••');
  Uint8List? _foto;
  bool _saving = false;

  @override
  void dispose() {
    _nama.dispose();
    _passMask.dispose();
    super.dispose();
  }

  bool get _changed =>
      _foto != null || _nama.text.trim() != (_ds.home?.username ?? '');

  Future<void> _save() async {
    if (_nama.text.trim().isEmpty) {
      warnPage(context);
      return;
    }
    setState(() => _saving = true);
    try {
      await _ds.updateProfile(username: _nama.text.trim(), foto: _foto);
      if (!mounted) return;
      setState(() => _saving = false);
      await showResultDialog(context,
          title: 'Profil Disimpan',
          message: 'Perubahan profilmu sudah tersimpan');
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        warnPage(context, 'Gagal menyimpan profil, coba lagi ya');
      }
    }
  }

  Future<void> _changePassword() async {
    await showAppDialog<void>(
      context,
      (_) => _ChangePasswordDialog(
        onSubmit: (pw) => _ds.changePassword(pw),
      ),
      dismissible: true,
    );
  }

  Future<void> _changePin() async {
    // 1. Verifikasi PIN lama 
    final verified = await showPinSheet(
      context,
      title: 'Masukkan PIN',
      onSubmit: (pin) async {
        try {
          final r = await AuthService.instance.verifyPin(pin);
          if (r.ok) return const PinOutcome.success();
          return PinOutcome.fail('PIN tidak valid, tersedia ${r.attemptsLeft} percobaan');
        } catch (_) {
          return const PinOutcome.fail('Koneksi bermasalah, coba lagi ya');
        }
      },
    );
    if (!verified || !mounted) return;
    // 2. Dialog Ubah PIN 
    await showAppDialog<void>(
      context,
      (_) => _ChangePinDialog(
        onSubmit: (newPin) => _ds.changePin(newPin),
      ),
      dismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'Ubah Profil',
      showBack: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
        children: [
          Center(
            child: GestureDetector(
              onTap: () async {
                final b = await _pickPhoto();
                if (b != null && mounted) setState(() => _foto = b);
              },
              child: Column(
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      children: [
                        _AvatarCircle(
                            url: _ds.home?.fotoUrl, bytes: _foto, size: 92),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                                color: AppColors.blue, shape: BoxShape.circle),
                            child: const Icon(Icons.edit_rounded,
                                size: 17, color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Edit Foto Profil',
                      style:
                          TextStyle(fontSize: 12.5, color: UiColors.textMute)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text('Nama',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black)),
          const SizedBox(height: 6),
          OutField(
            controller: _nama,
            height: 46,
            borderColor: AppColors.blue,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          const Text('Kata Sandi',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black)),
          const SizedBox(height: 6),
          OutField(
            controller: _passMask,
            height: 46,
            readOnly: true,
            borderColor: AppColors.blue,
            suffix: const Icon(Icons.visibility_off_outlined,
                size: 20, color: AppColors.black),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _changePassword,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Ubah Kata Sandi',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: _changePin,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: UiColors.blueTint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.blue, width: 1),
                ),
                child: const Text('Ubah PIN',
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black)),
              ),
            ),
          ),
          const SizedBox(height: 44),
          AppButton(
            text: 'Simpan',
            loading: _saving,
            style: _changed ? BtnStyle.primary : BtnStyle.disabledSoft,
            onTap: _save,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                backgroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.red, width: 1),
                shape: const StadiumBorder(),
              ),
              child: const Text('Batal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// USAHA 
class UsahaSayaScreen extends StatelessWidget {
  const UsahaSayaScreen({super.key});

  Future<void> _editDetail(BuildContext context, HomeData h) async {
    await showAppDialog<void>(
      context,
      (_) => _EditBusinessDialog(home: h),
      dismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = DataService.instance;
    return ListenableBuilder(
      listenable: ds,
      builder: (_, __) {
        final h = ds.home;
        return _SubPage(
          title: 'Usaha Saya',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 92,
                  height: 92,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.blue, width: 1.2),
                  ),
                  child: (h?.businessLogo != null &&
                          h!.businessLogo!.isNotEmpty)
                      ? Image.network(h.businessLogo!, fit: BoxFit.cover)
                      : const Icon(Icons.storefront_rounded,
                          size: 48, color: AppColors.darkYellow),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: UiColors.shadow,
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('Nama', h?.businessName ?? '-'),
                    const Divider(height: 20),
                    _field('Kategori', h?.businessCategory ?? '-'),
                    const Divider(height: 20),
                    _field(
                        'Deskripsi Usaha',
                        (h?.businessDescription ?? '').isEmpty
                            ? '-'
                            : h!.businessDescription),
                    const Divider(height: 22, color: AppColors.blue),
                    Center(
                      child: GestureDetector(
                        onTap: h == null ? null : () => _editDetail(context, h),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 26, vertical: 10),
                          decoration: BoxDecoration(
                            color: UiColors.chipGrey,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded,
                                  size: 18, color: AppColors.black),
                              SizedBox(width: 8),
                              Text('Ubah Detail',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.black)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const KaryawanListScreen()),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: UiColors.blueTint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.blue, width: 1.2),
                  ),
                  child: const Row(
                    children: [
                      IconBadge(Icons.groups_rounded,
                          size: 40, bg: AppColors.yellow, fg: AppColors.black),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Lihat Akun Karyawan',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.black)),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 22, color: AppColors.black),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k,
              style: const TextStyle(fontSize: 12, color: UiColors.textMute)),
          const SizedBox(height: 2),
          Text(v,
              style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black)),
        ],
      );
}

// DAFTAR KARYAWAN & UBAH AKUN KARYAWAN
class KaryawanListScreen extends StatelessWidget {
  const KaryawanListScreen({super.key});

  Future<void> _addEmployee(BuildContext context) async {
    final res = await showAppDialog<dynamic>(
      context,
      (_) => const LaborDialog(),
      dismissible: true,
    );
    if (res != null) {
      // Simpan tarif default ke akun karyawan yang baru dibuat
      try {
        await DataService.instance.updateEmployee(
          empId: res.employeeId as String,
          username: res.name as String,
          tarif: res.tarif as double,
          satuanTarif: res.metode as String,
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DataService.instance;
    return ListenableBuilder(
      listenable: ds,
      builder: (_, __) {
        final emps = ds.employees;
        final totalBiaya = emps.fold<double>(0, (s, e) => s + e.tarif);
        return _SubPage(
          title: 'Karyawan',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              // Kartu biru Total Biaya Karyawan
              Container(
                padding: const EdgeInsets.fromLTRB(0, 16, 18, 16),
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 16,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.darkYellow,
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Biaya Karyawan',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white)),
                          Text('${emps.length} Tenaga Kerja',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFFD6E3FA))),
                          const SizedBox(height: 6),
                          Text(Fmt.rp(totalBiaya),
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              for (final e in emps)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              UbahAkunKaryawanScreen(employee: e)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.blue, width: 1.3),
                      ),
                      child: Row(
                        children: [
                          const IconBadge(Icons.calendar_today_outlined,
                              size: 42,
                              bg: Color(0xFFDCDCDC),
                              fg: AppColors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.username,
                                    style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.black)),
                                Text(
                                    '${Fmt.rp(e.tarif)}/${e.satuanTarif}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: UiColors.textMute)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: AppColors.yellow,
                                      borderRadius: BorderRadius.circular(5)),
                                  child: Text(e.metodeLabel,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.blue)),
                                ),
                              ],
                            ),
                          ),
                          Text(Fmt.rp(e.tarif),
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.blue)),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: () => _addEmployee(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: UiColors.blueTint,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.blue, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 18, color: AppColors.blue),
                        SizedBox(width: 6),
                        Text('Tambah karyawan',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.blue)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class UbahAkunKaryawanScreen extends StatefulWidget {
  final EmployeeItem employee;
  const UbahAkunKaryawanScreen({super.key, required this.employee});

  @override
  State<UbahAkunKaryawanScreen> createState() => _UbahAkunKaryawanScreenState();
}

class _UbahAkunKaryawanScreenState extends State<UbahAkunKaryawanScreen> {
  final _ds = DataService.instance;
  late final _nama = TextEditingController(text: widget.employee.username);
  final _passMask = TextEditingController(text: '••••••••••');
  late double _tarif = widget.employee.tarif;
  late String _satuan = widget.employee.satuanTarif;
  Uint8List? _foto;
  bool _saving = false;

  @override
  void dispose() {
    _nama.dispose();
    _passMask.dispose();
    super.dispose();
  }

  Future<void> _save({String? newPass, String? newPin}) async {
    if (_nama.text.trim().isEmpty) {
      warnPage(context);
      return;
    }
    setState(() => _saving = true);
    try {
      await _ds.updateEmployee(
        empId: widget.employee.id,
        username: _nama.text.trim(),
        foto: _foto,
        tarif: _tarif,
        satuanTarif: _satuan,
        password: newPass,
        pin: newPin,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      await showResultDialog(context,
          title: 'Data Karyawan Diubah',
          message: 'Perubahan akun karyawan berhasil disimpan');
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        warnPage(context, 'Gagal menyimpan data karyawan');
      }
    }
  }

  Future<void> _editTarif() async {
    final tCtrl =
        TextEditingController(text: _tarif > 0 ? Fmt.number(_tarif) : '');
    final qCtrl = TextEditingController(text: '1');
    var metode = _satuan;

    Widget radioCard(String id, IconData icon, String title, String sub,
        void Function(void Function()) setSt) {
      final active = metode == id;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => setSt(() => metode = id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: active ? AppColors.black : AppColors.grey,
                  width: active ? 1.3 : 1),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: AppColors.black),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black)),
                      Text(sub,
                          style: const TextStyle(
                              fontSize: 11, color: UiColors.textMute)),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: active ? AppColors.black : AppColors.grey,
                        width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: active
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: AppColors.black),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ok = await showAppDialog<bool>(
      context,
      (ctx) => StatefulBuilder(
        builder: (_, setSt) {
          final isManual = metode == 'manual';
          final detailTitle = metode == 'hari'
              ? 'Detail Tarif per Hari'
              : metode == 'output'
                  ? 'Detail Tarif per Output'
                  : isManual
                      ? 'Input total biaya'
                      : 'Detail Tarif per Jam';
          final qtyUnit = metode == 'hari'
              ? 'Hari'
              : metode == 'output'
                  ? 'pcs'
                  : 'Jam';
          final ready = Fmt.parse(tCtrl.text) > 0 &&
              (isManual || Fmt.parse(qCtrl.text) > 0);

          return AppDialogCard(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Metode Input',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: UiColors.textMute)),
                  const SizedBox(height: 12),
                  radioCard('jam', Icons.access_time_rounded, 'Tarif per Jam',
                      'Upah berdasarkan jam kerja', setSt),
                  radioCard('hari', Icons.calendar_today_outlined,
                      'Tarif per Hari', 'Upah berdasarkan hari kerja', setSt),
                  radioCard('output', Icons.calendar_today_outlined,
                      'Tarif per Output', 'Upah berdasarkan jumlah output', setSt),
                  radioCard('manual', Icons.edit_outlined, 'Input Manual',
                      'Input total biaya langsung', setSt),
                  const SizedBox(height: 6),
                  Text(detailTitle,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: UiColors.textMute)),
                  const SizedBox(height: 10),
                  if (isManual)
                    OutField(
                      controller: tCtrl,
                      height: 44,
                      radius: 22,
                      borderColor: AppColors.grey,
                      prefix: const Text('Rp',
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue)),
                      hint: 'Total biaya',
                      keyboard: TextInputType.number,
                      formatters: [ThousandsFormatter()],
                      onChanged: (_) => setSt(() {}),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutField(
                            controller: tCtrl,
                            height: 44,
                            radius: 22,
                            borderColor: AppColors.grey,
                            prefix: const Text('Rp',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blue)),
                            hint: '3000',
                            keyboard: TextInputType.number,
                            formatters: [ThousandsFormatter()],
                            onChanged: (_) => setSt(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutField(
                            controller: qCtrl,
                            height: 44,
                            radius: 22,
                            borderColor: AppColors.grey,
                            hint: '1',
                            textAlign: TextAlign.right,
                            keyboard: const TextInputType.numberWithOptions(
                                decimal: true),
                            formatters: [DecimalFormatter()],
                            suffix: Text(qtyUnit,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.blue)),
                            onChanged: (_) => setSt(() {}),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  DialogButtons(
                    ready: ready,
                    onCancel: () =>
                        Navigator.of(ctx, rootNavigator: true).pop(),
                    onConfirm: () {
                      if (!ready) {
                        warnDialog(ctx);
                        return;
                      }
                      Navigator.of(ctx, rootNavigator: true).pop(true);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      dismissible: true,
    );
    if (ok == true && mounted) {
      setState(() {
        _tarif = Fmt.parse(tCtrl.text);
        _satuan = metode;
      });
    }
    tCtrl.dispose();
    qCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SubPage(
      title: 'Ubah Akun Karyawan',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
        children: [
          Center(
            child: GestureDetector(
              onTap: () async {
                final b = await _pickPhoto();
                if (b != null && mounted) setState(() => _foto = b);
              },
              child: Column(
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      children: [
                        _AvatarCircle(
                            url: widget.employee.fotoUrl,
                            bytes: _foto,
                            size: 92),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                                color: AppColors.blue, shape: BoxShape.circle),
                            child: const Icon(Icons.edit_rounded,
                                size: 17, color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Edit Foto Profil',
                      style:
                          TextStyle(fontSize: 12.5, color: UiColors.textMute)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Nama',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          OutField(controller: _nama, height: 46, borderColor: AppColors.blue),
          const SizedBox(height: 16),
          const Text('Tarif',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _editTarif,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: UiColors.lavender,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: UiColors.blueTint),
              ),
              child: Row(
                children: [
                  const IconBadge(Icons.payments_rounded,
                      size: 36, bg: Color(0xFFC9D5EC), fg: AppColors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _tarif > 0
                          ? '${Fmt.rp(_tarif)} / $_satuan'
                          : 'Tap untuk mengubah tarif',
                      style: TextStyle(
                          fontSize: 13.5,
                          color: _tarif > 0
                              ? AppColors.black
                              : UiColors.textMute),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.black),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Kata Sandi',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          OutField(
            controller: _passMask,
            height: 46,
            readOnly: true,
            borderColor: AppColors.blue,
            suffix: const Icon(Icons.visibility_off_outlined, size: 20),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => showAppDialog<void>(
                context,
                (_) => _ChangePasswordDialog(
                  onSubmit: (pw) => _ds.updateEmployee(
                    empId: widget.employee.id,
                    username: _nama.text.trim(),
                    password: pw,
                  ),
                ),
                dismissible: true,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Ubah Kata Sandi',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: GestureDetector(
              onTap: () => showAppDialog<void>(
                context,
                (_) => _ChangePinDialog(
                  onSubmit: (pin) => _ds.updateEmployee(
                    empId: widget.employee.id,
                    username: _nama.text.trim(),
                    pin: pin,
                  ),
                ),
                dismissible: true,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: UiColors.blueTint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.blue),
                ),
                child: const Text('Ubah PIN',
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black)),
              ),
            ),
          ),
          const SizedBox(height: 28),
          AppButton(
            text: 'Simpan',
            loading: _saving,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}

// Dialogs: Ubah Sandi, Ubah PIN (pakai keypad kustom), Ubah Detail Usaha.
class _ChangePasswordDialog extends StatefulWidget {
  final Future<void> Function(String newPassword) onSubmit;
  const _ChangePasswordDialog({required this.onSubmit});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  bool _err = false;
  bool _busy = false;

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  bool get _ok => _p1.text.length >= 6 && _p2.text.length >= 6;

  Future<void> _save() async {
    if (_p1.text.isEmpty || _p2.text.isEmpty) {
      warnDialog(context);
      return;
    }
    if (_p1.text.length < 6) {
      setState(() => _err = true);
      warnDialog(context, 'Kata sandi minimal 6 karakter');
      return;
    }
    if (_p1.text != _p2.text) {
      setState(() => _err = true);
      warnDialog(context, 'Kata sandi tidak cocok, cek lagi ya!');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onSubmit(_p1.text);
      if (!mounted) return;
      final nav = Navigator.of(context, rootNavigator: true);
      final ctx = nav.context;
      nav.pop();
      if (ctx.mounted) {
        showResultDialog(ctx,
            title: 'Kata Sandi Diubah',
            message: 'Kata sandi baru berhasil disimpan');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        warnDialog(context, 'Gagal mengubah kata sandi');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DialogTitleRow(
              title: 'Ubah Sandi', onClose: () => closeDialog(context)),
          const SizedBox(height: 12),
          AppTextField(
            controller: _p1,
            label: 'Kata Sandi Baru',
            dense: true,
            password: true,
            error: _err,
            onChanged: (_) => setState(() => _err = false),
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _p2,
            label: 'Konfirmasi Kata Sandi',
            dense: true,
            password: true,
            error: _err,
            onChanged: (_) => setState(() => _err = false),
          ),
          const SizedBox(height: 20),
          Center(
            child: AppButton(
              text: 'Simpan',
              width: 120,
              height: 36,
              fontSize: 14,
              loading: _busy,
              style: _ok ? BtnStyle.primary : BtnStyle.disabledSoft,
              onTap: _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePinDialog extends StatefulWidget {
  final Future<void> Function(String newPin) onSubmit;
  const _ChangePinDialog({required this.onSubmit});

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  String _pin1 = '';
  String _pin2 = '';
  int? _activePin; // null = tutup, 0 = PIN Baru, 1 = Konfirmasi PIN
  bool _err = false;
  bool _busy = false;

  bool get _ok => _pin1.length == 6 && _pin2.length == 6;

  void _onDigit(String d) {
    setState(() {
      _err = false;
      if (_activePin == 0 && _pin1.length < 6) {
        _pin1 += d;
        if (_pin1.length == 6) _activePin = 1;
      } else if (_activePin == 1 && _pin2.length < 6) {
        _pin2 += d;
        if (_pin2.length == 6) _activePin = null;
      }
    });
  }

  void _onBack() {
    setState(() {
      if (_activePin == 0 && _pin1.isNotEmpty) {
        _pin1 = _pin1.substring(0, _pin1.length - 1);
      } else if (_activePin == 1 && _pin2.isNotEmpty) {
        _pin2 = _pin2.substring(0, _pin2.length - 1);
      }
    });
  }

  Future<void> _save() async {
    if (!_ok) {
      warnDialog(context);
      return;
    }
    if (_pin1 != _pin2) {
      setState(() => _err = true);
      warnDialog(context, 'PIN baru tidak cocok, cek lagi ya!');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onSubmit(_pin1);
      if (!mounted) return;
      final nav = Navigator.of(context, rootNavigator: true);
      final ctx = nav.context;
      nav.pop();
      if (ctx.mounted) {
        showResultDialog(ctx,
            title: 'PIN Berhasil Diubah',
            message: 'PIN baru kamu sudah aktif digunakan');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        warnDialog(context, 'Gagal mengubah PIN');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PinDialogShell(
      showKeypad: _activePin != null,
      onDigit: _onDigit,
      onBackspace: _onBack,
      onCloseKeypad: () => setState(() => _activePin = null),
      cardPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DialogTitleRow(
              title: 'Ubah Pin', onClose: () => closeDialog(context)),
          const SizedBox(height: 10),
          const Text('PIN Baru', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          PinBoxField(
            value: _pin1,
            active: _activePin == 0,
            error: _err,
            onTap: () => setState(() => _activePin = 0),
          ),
          const SizedBox(height: 12),
          const Text('Konfirmasi PIN', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          PinBoxField(
            value: _pin2,
            active: _activePin == 1,
            error: _err,
            onTap: () => setState(() => _activePin = 1),
          ),
          const SizedBox(height: 20),
          Center(
            child: AppButton(
              text: 'Simpan',
              width: 120,
              height: 36,
              fontSize: 14,
              loading: _busy,
              style: _ok ? BtnStyle.primary : BtnStyle.disabledSoft,
              onTap: _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditBusinessDialog extends StatefulWidget {
  final HomeData home;
  const _EditBusinessDialog({required this.home});

  @override
  State<_EditBusinessDialog> createState() => _EditBusinessDialogState();
}

class _EditBusinessDialogState extends State<_EditBusinessDialog> {
  late final _nama = TextEditingController(text: widget.home.businessName);
  late final _kat = TextEditingController(text: widget.home.businessCategory);
  late final _desc =
      TextEditingController(text: widget.home.businessDescription);
  Uint8List? _logo;
  bool _busy = false;

  @override
  void dispose() {
    _nama.dispose();
    _kat.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nama.text.trim().isEmpty) {
      warnDialog(context);
      return;
    }
    setState(() => _busy = true);
    try {
      await DataService.instance.updateBusiness(
        nama: _nama.text.trim(),
        kategori: _kat.text.trim(),
        deskripsi: _desc.text.trim(),
        logo: _logo,
      );
      if (mounted) closeDialog(context);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        warnDialog(context, 'Gagal menyimpan detail usaha');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DialogTitleRow(
                title: 'Ubah Detail Usaha',
                onClose: () => closeDialog(context)),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () async {
                  final b = await _pickPhoto();
                  if (b != null && mounted) setState(() => _logo = b);
                },
                child: Container(
                  width: 72,
                  height: 72,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: UiColors.field,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.blue),
                  ),
                  child: _logo != null
                      ? Image.memory(_logo!, fit: BoxFit.cover)
                      : const Icon(Icons.add_a_photo_rounded,
                          color: AppColors.blue),
                ),
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(controller: _nama, label: 'Nama Usaha', dense: true),
            const SizedBox(height: 10),
            AppTextField(controller: _kat, label: 'Kategori', dense: true),
            const SizedBox(height: 10),
            AppTextField(
                controller: _desc,
                label: 'Deskripsi Usaha',
                dense: true,
                maxLines: 3),
            const SizedBox(height: 18),
            DialogButtons(
              ready: _nama.text.trim().isNotEmpty,
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

// Helper widgets
class _SubPage extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showBack;
  const _SubPage(
      {required this.title, required this.body, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
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
                  if (showBack)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back_rounded,
                            size: 28, color: AppColors.blue),
                      ),
                    )
                  else
                    const SizedBox(width: 10),
                  const SizedBox(width: 4),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            Expanded(child: PageBg(child: body)),
          ],
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String? url;
  final Uint8List? bytes;
  final double size;
  const _AvatarCircle({this.url, this.bytes, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
          color: Color(0xFFE0E0E0), shape: BoxShape.circle),
      child: bytes != null
          ? Image.memory(bytes!, fit: BoxFit.cover)
          : (url != null && url!.isNotEmpty)
              ? Image.network(url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.person_rounded,
                      size: size * 0.6, color: AppColors.grey))
              : Icon(Icons.person_rounded,
                  size: size * 0.6, color: AppColors.grey),
    );
  }
}