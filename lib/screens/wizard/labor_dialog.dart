import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_theme.dart';
import '../../core/calc.dart';
import '../../core/format.dart';
import '../../core/ui_kit.dart';
import '../../core/widgets.dart';
import '../../services/data_service.dart';
import 'wizard_dialogs.dart';

class LaborDialog extends StatefulWidget {
  final Set<String> excludeEmployeeIds;
  final LaborLine? editing;
  const LaborDialog({
    super.key,
    this.excludeEmployeeIds = const {},
    this.editing,
  });

  @override
  State<LaborDialog> createState() => _LaborDialogState();
}

class _LaborDialogState extends State<LaborDialog> {
  final _ds = DataService.instance;

  // 0 = pilih/buat akun, 1 = atur metode & tarif
  late int _step = widget.editing != null ? 1 : 0;
  bool _createNew = true;

  // tahap 1 (akun)
  Uint8List? _foto;
  final _nama = TextEditingController();
  final _pass = TextEditingController();
  String _pin = '';
  String _pin2 = '';
  int? _activePin; // null = tutup, 0 = Buat PIN, 1 = Konfirmasi PIN
  bool _pinErr = false;
  bool _busy = false;
  EmployeeItem? _selectedEmp;

  void _onPinDigit(String d) {
    setState(() {
      _pinErr = false;
      if (_activePin == 0 && _pin.length < 6) {
        _pin += d;
        if (_pin.length == 6) _activePin = 1;
      } else if (_activePin == 1 && _pin2.length < 6) {
        _pin2 += d;
        if (_pin2.length == 6) _activePin = null;
      }
    });
  }

  void _onPinBack() {
    setState(() {
      if (_activePin == 0 && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      } else if (_activePin == 1 && _pin2.isNotEmpty) {
        _pin2 = _pin2.substring(0, _pin2.length - 1);
      }
    });
  }

  // tahap 2 (tarif)
  String _metode = 'jam'; // jam | hari | output | manual
  final _tarif = TextEditingController();
  final _qty = TextEditingController();

  List<EmployeeItem> get _availableEmployees => _ds.employees
      .where((e) => !widget.excludeEmployeeIds.contains(e.id))
      .toList();

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      final ed = widget.editing!;
      _selectedEmp = EmployeeItem(ed.employeeId, ed.name, null);
      _nama.text = ed.name;
      _metode = ed.metode;
      _tarif.text = Fmt.number(ed.tarif);
      if (ed.metode != 'manual') _qty.text = Fmt.plain(ed.qty);
    } else if (_availableEmployees.isNotEmpty) {
      _createNew = false;
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _pass.dispose();
    _tarif.dispose();
    _qty.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final f = await ImagePicker().pickImage(
          source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 70);
      if (f != null) {
        final b = await f.readAsBytes();
        if (mounted) setState(() => _foto = b);
      }
    } catch (_) {}
  }

  bool get _step1Ready =>
      _nama.text.trim().isNotEmpty &&
      _pass.text.length >= 6 &&
      _pin.length == 6 &&
      _pin2.length == 6;

  bool get _step2Ready {
    final t = Fmt.parse(_tarif.text);
    if (t <= 0) return false;
    if (_metode == 'manual') return true;
    return Fmt.parse(_qty.text) > 0;
  }

  Future<void> _nextFromCreate() async {
    if (_busy) return;
    if (_nama.text.trim().isEmpty ||
        _pass.text.isEmpty ||
        _pin.length < 6 ||
        _pin2.length < 6) {
      warnDialog(context);
      return;
    }
    if (_pass.text.length < 6) {
      warnDialog(context, 'Password minimal 6 karakter');
      return;
    }
    if (_pin != _pin2) {
      setState(() => _pinErr = true);
      warnDialog(context, 'PIN nya gak cocok, cek lagi ya!');
      return;
    }

    setState(() => _busy = true);
    try {
      final emp = await _ds.createEmployee(
        username: _nama.text.trim(),
        password: _pass.text,
        pin: _pin,
        foto: _foto,
      );
      if (!mounted) return;
      setState(() {
        _selectedEmp = emp;
        _busy = false;
        _step = 1;
      });
    } on DataFailure catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.code == 'user_taken') {
        warnDialog(context, 'Nama tenaga kerja sudah dipakai');
      } else if (e.code == 'forbidden') {
        warnDialog(context, 'Hanya pemilik usaha yang bisa menambah karyawan');
      } else {
        warnDialog(context, 'Gagal membuat akun karyawan, coba lagi ya');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      warnDialog(context, 'Koneksi bermasalah, coba lagi ya');
    }
  }

  Future<void> _saveLabor() async {
    if (!_step2Ready || _selectedEmp == null || _busy) {
      if (!_busy) warnDialog(context);
      return;
    }
    final t = Fmt.parse(_tarif.text);
    final q = _metode == 'manual' ? 1.0 : Fmt.parse(_qty.text);

    // Sinkronkan tarif & satuan_tarif ke akun karyawan di database (halaman Karyawan)
    setState(() => _busy = true);
    try {
      await _ds.updateEmployee(
        empId: _selectedEmp!.id,
        username: _selectedEmp!.username,
        tarif: t,
        satuanTarif: _metode,
      );
    } catch (_) {
      // Tetap lanjutkan agar alur tambah produk tidak terhambat
    }
    if (!mounted) return;
    closeDialog(
      context,
      LaborLine(
        employeeId: _selectedEmp!.id,
        name: _selectedEmp!.username,
        metode: _metode,
        qty: q,
        tarif: t,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PinDialogShell(
      showKeypad: _step == 0 && _activePin != null,
      onDigit: _onPinDigit,
      onBackspace: _onPinBack,
      onCloseKeypad: () => setState(() => _activePin = null),
      horizontalInset: 20,
      cardPadding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: _step == 0 ? _buildStep1() : _buildStep2(),
    );
  }

  // ---------------------------------------------------------------- tahap 1
  Widget _buildStep1() {
    final avail = _availableEmployees;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DialogTitleRow(
            title: 'Tambah Tenaga Kerja', onClose: () => closeDialog(context)),
        if (avail.isNotEmpty) ...[
          const SizedBox(height: 12),
          SegmentPill(
            labels: const ['Pilih Karyawan', 'Buat Baru'],
            selected: _createNew ? 1 : 0,
            height: 36,
            onChanged: (i) => setState(() => _createNew = i == 1),
          ),
        ],
        const SizedBox(height: 16),
        if (!_createNew && avail.isNotEmpty) ...[
          for (final emp in avail)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedEmp = emp;
                  _nama.text = emp.username;
                  _step = 1;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.blue, width: 1),
                  ),
                  child: Row(
                    children: [
                      const IconBadge(Icons.person_rounded,
                          size: 40, bg: UiColors.blueTint, fg: AppColors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(emp.username,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black)),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 22, color: AppColors.blue),
                    ],
                  ),
                ),
              ),
            ),
        ] else ...[
          // Avatar + kamera
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: AppColors.blue),
                      child: _foto != null
                          ? Image.memory(_foto!, fit: BoxFit.cover)
                          : const Icon(Icons.person_rounded,
                              size: 56, color: AppColors.white),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: UiColors.blueTint),
                        child: const Icon(Icons.add_a_photo_rounded,
                            size: 16, color: AppColors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          OutField(
            controller: _nama,
            floatLabel: 'Nama Tenaga Kerja',
            hint: 'Contoh: Buahlil',
            height: 46,
            radius: 22,
            borderColor: AppColors.grey,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          OutField(
            controller: _pass,
            floatLabel: 'Buat Password',
            hint: '******',
            height: 46,
            radius: 22,
            borderColor: AppColors.grey,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          const Text('Buat PIN',
              style: TextStyle(fontSize: 12.5, color: UiColors.textMute)),
          const SizedBox(height: 4),
          PinBoxField(
            value: _pin,
            active: _activePin == 0,
            error: _pinErr,
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _activePin = 0);
            },
          ),
          const SizedBox(height: 12),
          const Text('Konfirmasi PIN',
              style: TextStyle(fontSize: 12.5, color: UiColors.textMute)),
          const SizedBox(height: 4),
          PinBoxField(
            value: _pin2,
            active: _activePin == 1,
            error: _pinErr,
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _activePin = 1);
            },
          ),
          const SizedBox(height: 22),
          DialogButtons(
            confirmText: 'Lanjut',
            ready: _step1Ready,
            loading: _busy,
            onCancel: () => closeDialog(context),
            onConfirm: _nextFromCreate,
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------- tahap 2
  Widget _methodOption({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final active = _metode == id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() {
          _metode = id;
          _tarif.clear();
          _qty.clear();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: active ? AppColors.blue : AppColors.grey,
                width: active ? 1.4 : 1),
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
                    Text(subtitle,
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
                      color: active ? AppColors.black : AppColors.grey, width: 1.5),
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

  Widget _buildStep2() {
    String detailTitle;
    String tarifHint;
    String qtyHint;
    String qtyUnit;
    switch (_metode) {
      case 'hari':
        detailTitle = 'Detail Tarif per Hari';
        tarifHint = 'Tarif/Hari';
        qtyHint = 'Hari Kerja';
        qtyUnit = 'hari';
        break;
      case 'output':
        detailTitle = 'Detail Tarif per Output';
        tarifHint = 'Tarif/Output';
        qtyHint = 'Jumlah';
        qtyUnit = 'pcs';
        break;
      case 'manual':
        detailTitle = 'Input total biaya';
        tarifHint = 'Total biaya';
        qtyHint = '';
        qtyUnit = '';
        break;
      default:
        detailTitle = 'Detail Tarif per Jam';
        tarifHint = 'Tarif/Jam';
        qtyHint = 'Jam Kerja';
        qtyUnit = 'jam';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DialogTitleRow(
            title: 'Tambah Tenaga Kerja', onClose: () => closeDialog(context)),
        const SizedBox(height: 14),
        OutField(
          controller: _nama,
          floatLabel: 'Nama Tenaga Kerja',
          readOnly: true,
          height: 44,
          radius: 22,
          borderColor: AppColors.grey,
        ),
        const SizedBox(height: 14),
        const Text('Metode Input',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: UiColors.textMute)),
        const SizedBox(height: 8),
        _methodOption(
          id: 'jam',
          icon: Icons.access_time_rounded,
          title: 'Tarif per Jam',
          subtitle: 'Upah berdasarkan jam kerja',
        ),
        _methodOption(
          id: 'hari',
          icon: Icons.calendar_today_outlined,
          title: 'Tarif per Hari',
          subtitle: 'Upah berdasarkan hari kerja',
        ),
        _methodOption(
          id: 'output',
          icon: Icons.inventory_2_outlined,
          title: 'Tarif per Output',
          subtitle: 'Upah berdasarkan jumlah output',
        ),
        _methodOption(
          id: 'manual',
          icon: Icons.edit_outlined,
          title: 'Input Manual',
          subtitle: 'Input total biaya langsung',
        ),
        const SizedBox(height: 6),
        Text(detailTitle,
            style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w600, color: UiColors.textMute)),
        const SizedBox(height: 8),
        if (_metode == 'manual')
          OutField(
            controller: _tarif,
            height: 44,
            radius: 22,
            borderColor: AppColors.grey,
            prefix: const Text('Rp',
                style: TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.blue)),
            hint: tarifHint,
            keyboard: TextInputType.number,
            formatters: [ThousandsFormatter()],
            onChanged: (_) => setState(() {}),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutField(
                  controller: _tarif,
                  height: 44,
                  radius: 22,
                  borderColor: AppColors.grey,
                  prefix: const Text('Rp',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.blue)),
                  hint: tarifHint,
                  keyboard: TextInputType.number,
                  formatters: [ThousandsFormatter()],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutField(
                  controller: _qty,
                  height: 44,
                  radius: 22,
                  borderColor: AppColors.grey,
                  hint: qtyHint,
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                  formatters: [DecimalFormatter()],
                  suffix: Text(qtyUnit,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue)),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        const SizedBox(height: 18),
        DialogButtons(
          confirmText: 'Simpan',
          ready: _step2Ready,
          onCancel: () => closeDialog(context),
          onConfirm: _saveLabor,
        ),
      ],
    );
  }
}
