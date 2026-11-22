import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/ui_kit.dart';
import '../core/widgets.dart';

class TermsScreen extends StatelessWidget {
  final bool showAgreeButton;

  const TermsScreen({super.key, this.showAgreeButton = false});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      backgroundColor: UiColors.page,
      body: PageBg(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.blue,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Syarat & Ketentuan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Konten S&K
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    showAgreeButton ? 20 : 32,
                  ),
                  children: [
                    _HeroBanner(),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _sections.length; i++) ...[
                      _TermsCard(
                        number: i + 1,
                        title: _sections[i].title,
                        paragraphs: _sections[i].paragraphs,
                        bullets: _sections[i].bullets,
                      ),
                      if (i != _sections.length - 1) const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'Dengan menggunakan aplikasi Labaku, Anda menyatakan\ntelah membaca dan menyetujui seluruh ketentuan di atas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: UiColors.textMute,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tombol persetujuan 
              if (showAgreeButton)
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.of(context).padding.bottom + 14,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: UiColors.shadow,
                        blurRadius: 12,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: AppButton(
                    text: 'Saya Mengerti & Setuju',
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: UiColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.darkYellow,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ketentuan Penggunaan Labaku',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Harap membaca Syarat dan Ketentuan ini dengan saksama sebelum mendaftar atau menggunakan layanan aplikasi Labaku.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Color(0xFFDDE7FB),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 15,
                      color: AppColors.yellow,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Berlaku untuk Pemilik Usaha & Karyawan',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.yellow,
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

class _TermsCard extends StatelessWidget {
  final int number;
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const _TermsCard({
    required this.number,
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: UiColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: UiColors.blueTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          if (paragraphs.isNotEmpty) const SizedBox(height: 10),
          for (var i = 0; i < paragraphs.length; i++) ...[
            Text(
              paragraphs[i],
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: UiColors.textDark,
              ),
            ),
            if (i != paragraphs.length - 1) const SizedBox(height: 8),
          ],
          if (bullets.isNotEmpty) const SizedBox(height: 8),
          for (var i = 0; i < bullets.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 7, right: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    bullets[i],
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: UiColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            if (i != bullets.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _TermsSectionData {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const _TermsSectionData({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}

const _sections = <_TermsSectionData>[
  _TermsSectionData(
    title: 'Ketentuan Umum',
    paragraphs: [
      'Labaku adalah aplikasi manajemen dan perhitungan bisnis yang dirancang untuk membantu pelaku usaha menghitung Harga Pokok Produksi (HPP), menyimulasikan margin dan harga jual, mengelola bahan baku, mencatat penjualan, serta memantau laporan laba secara praktis.',
      'Dengan mendaftar, mengakses, atau menggunakan aplikasi Labaku, Anda menyatakan telah membaca, memahami, dan menyetujui untuk terikat pada seluruh Syarat dan Ketentuan ini.',
    ],
  ),
  _TermsSectionData(
    title: 'Akun, Peran Pengguna & Keamanan',
    paragraphs: [
      'Akses ke dalam aplikasi Labaku dikelola berdasarkan identitas usaha dan peran pengguna:',
    ],
    bullets: [
      'Pemilik Usaha (Bos) mendaftarkan usaha menggunakan Nama Pengguna, Nama Usaha, Kata Sandi (minimal 6 karakter), serta PIN 6 digit, dan memiliki akses penuh terhadap pengaturan usaha, produk, bahan baku, karyawan, serta laporan.',
      'Karyawan dibuat dan dikelola oleh Pemilik Usaha dengan hak akses terbatas, termasuk melihat daftar produk, memantau sisa stok, dan mencatat transaksi penjualan.',
      'Anda bertanggung jawab penuh menjaga kerahasiaan Kata Sandi, PIN, serta perangkat yang menyimpan sesi login aktif.',
      'Untuk menjaga keamanan akun, kesalahan memasukkan PIN sebanyak 3 (tiga) kali berturut-turut akan mengunci verifikasi sementara selama 5 menit.',
    ],
  ),
  _TermsSectionData(
    title: 'Kepemilikan Data & Privasi',
    paragraphs: [
      'Seluruh data usaha yang Anda masukkan—termasuk profil usaha, logo, foto produk, daftar bahan baku, data karyawan, serta riwayat penjualan—sepenuhnya tetap menjadi milik Pemilik Usaha.',
    ],
    bullets: [
      'Data disimpan pada layanan basis data cloud untuk mendukung sinkronisasi antar perangkat dan menjaga ketersediaan data usaha Anda.',
      'Sesi login disimpan secara lokal di perangkat agar Anda dapat langsung membuka beranda tanpa login berulang kali hingga Anda memilih Log Out atau sesi berakhir.',
      'Kami tidak menjual, menyewakan, atau menyebarluaskan data bisnis Anda kepada pihak ketiga tanpa persetujuan, kecuali apabila diwajibkan oleh peraturan perundang-undangan yang berlaku.',
    ],
  ),
  _TermsSectionData(
    title: 'Akurasi Perhitungan & Batasan Tanggung Jawab',
    paragraphs: [
      'Labaku menghitung HPP (biaya bahan baku termasuk penyusutan, biaya tenaga kerja, dan overhead), simulasi harga jual, diskon, pajak, biaya layanan, serta ringkasan laba berdasarkan angka yang dimasukkan oleh pengguna.',
    ],
    bullets: [
      'Hasil perhitungan dan laporan di dalam Labaku disediakan sebagai alat bantu operasional usaha dan tidak menggantikan nasihat akuntansi, keuangan, maupun perpajakan profesional.',
      'Pengguna bertanggung jawab memverifikasi kelengkapan dan ketepatan data bahan baku, tarif tenaga kerja, stok, harga jual, dan transaksi yang dicatat.',
      'Pengembang tidak bertanggung jawab atas kerugian finansial, selisih stok, kesalahan penetapan harga, atau kewajiban pajak yang timbul dari data yang dimasukkan pengguna maupun gangguan koneksi jaringan di luar kendali kami.',
    ],
  ),
  _TermsSectionData(
    title: 'Penggunaan yang Dilarang',
    paragraphs: [
      'Selama menggunakan aplikasi Labaku, pengguna dilarang untuk:',
    ],
    bullets: [
      'Menggunakan aplikasi untuk tujuan yang melanggar hukum, penipuan, atau kegiatan usaha ilegal.',
      'Mengakses, mengubah, atau menghapus data milik usaha lain tanpa izin yang sah.',
      'Mengunggah gambar atau konten yang melanggar hak cipta, kesusilaan, atau hak pihak ketiga lainnya.',
      'Mencoba meretas, mengganggu kestabilan server, atau melakukan rekayasa balik terhadap sistem aplikasi.',
    ],
  ),
  _TermsSectionData(
    title: 'Hak Kekayaan Intelektual',
    paragraphs: [
      'Seluruh tampilan antarmuka, logo Labaku, maskot, kode sumber, ikon, dan materi desain di dalam aplikasi merupakan milik pengembang Labaku dan dilindungi oleh ketentuan hak kekayaan intelektual yang berlaku. Pengguna dilarang menyalin, memodifikasi, atau mendistribusikan ulang bagian aplikasi tanpa izin tertulis.',
    ],
  ),
  _TermsSectionData(
    title: 'Pembaruan Layanan & Ketentuan',
    paragraphs: [
      'Kami berhak mengembangkan, mengubah, atau memperbarui fitur aplikasi serta isi Syarat dan Ketentuan ini dari waktu ke waktu demi meningkatkan kenyamanan dan keamanan layanan.',
      'Penggunaan aplikasi Labaku secara berkelanjutan setelah pembaruan diberlakukan dianggap sebagai bentuk persetujuan Anda terhadap ketentuan terbaru.',
    ],
  ),
  _TermsSectionData(
    title: 'Dukungan & Kontak',
    paragraphs: [
      'Apabila Anda memiliki pertanyaan, saran, laporan kendala teknis, atau permintaan terkait pengelolaan akun dan data usaha, silakan hubungi tim pengembang Labaku melalui kanal bantuan resmi yang tersedia.',
    ],
  ),
];
