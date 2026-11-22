import 'dart:async';

import 'package:flutter/material.dart';

import '../services/data_service.dart';
import 'app_theme.dart';
import 'net_check.dart';
import 'ui_kit.dart';
import 'widgets.dart';

/// Membungkus halaman utama (Beranda Bos & Karyawan) untuk mendeteksi
/// apakah Wi-Fi / data seluler aktif. Jika terputus, tampilkan UI offline
/// dengan tombol "Coba Lagi" dan otomatis pulih saat koneksi kembali.
class OfflineGuard extends StatefulWidget {
  final Widget child;
  const OfflineGuard({super.key, required this.child});

  @override
  State<OfflineGuard> createState() => _OfflineGuardState();
}

class _OfflineGuardState extends State<OfflineGuard>
    with WidgetsBindingObserver {
  final _ds = DataService.instance;
  bool _offline = false;
  bool _checking = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ds.addListener(_onDataChanged);
    _offline = _ds.error == 'network';
    _syncTimer();
    _checkNow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ds.removeListener(_onDataChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _syncTimer() {
    if (_offline) {
      _timer ??= Timer.periodic(
          const Duration(seconds: 5), (_) => _checkNow(reloadIfBack: true));
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNow(reloadIfBack: true);
    }
  }

  void _onDataChanged() {
    if (_ds.error == 'network' && !_offline && mounted) {
      setState(() => _offline = true);
      _syncTimer();
    }
  }

  Future<void> _checkNow({bool manual = false, bool reloadIfBack = false}) async {
    if (_checking) return;
    if (manual && mounted) setState(() => _checking = true);
    final online = await hasInternetConnection();
    if (!mounted) return;
    final wasOffline = _offline;
    setState(() {
      _offline = !online;
      _checking = false;
    });
    _syncTimer();
    if (online && (wasOffline || reloadIfBack || _ds.home == null || _ds.error == 'network')) {
      await _ds.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_offline) return widget.child;

    return Scaffold(
      backgroundColor: UiColors.page,
      body: PageBg(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ikon status offline (pure Flutter code, sesuai palet Labaku)
                  SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: UiColors.blueTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            size: 62,
                            color: AppColors.blue,
                          ),
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.yellow,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.signal_cellular_off_rounded,
                              size: 20,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tidak Ada Koneksi Internet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Wi-Fi atau data seluler kamu sedang tidak aktif.\nAktifkan koneksi internet untuk menggunakan Labaku.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: UiColors.textMute,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: UiColors.blueTint, width: 1.2),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_rounded,
                            size: 20, color: AppColors.blue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Data produk, stok, dan laporan disinkronkan secara real-time dengan server.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  AppButton(
                    text: 'Coba Lagi',
                    width: 210,
                    height: 46,
                    fontSize: 15.5,
                    loading: _checking,
                    onTap: () => _checkNow(manual: true, reloadIfBack: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
