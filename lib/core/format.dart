/// Format angka & tanggal gaya Indonesia (tanpa paket intl agar ringan).
class Fmt {
  static String _group(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  /// 389980 -> "389.980"
  static String number(num v) {
    final r = v.isNaN || v.isInfinite ? 0 : v.round();
    return (r < 0 ? '-' : '') + _group(r);
  }

  /// 389980 -> "Rp389.980"
  static String rp(num v) => 'Rp${number(v)}';

  /// 24.67 -> "24,7%"
  static String pct(num v, {int decimals = 1}) {
    final x = v.isNaN || v.isInfinite ? 0 : v;
    return '${x.toStringAsFixed(decimals).replaceAll('.', ',')}%';
  }

  /// Angka bebas desimal -> "1,5" / "20" (tanpa nol di belakang)
  static String plain(num v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    var s = v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    return s.replaceAll('.', ',');
  }

  /// Parse input user: "40.000" / "40000" / "1,5" -> double
  static double parse(String s) {
    var t = s.trim();
    if (t.isEmpty) return 0;
    if (t.contains(',')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(t)) {
      t = t.replaceAll('.', '');
    }
    return double.tryParse(t) ?? 0;
  }

  static const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  static const _bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus',
    'September', 'Oktober', 'November', 'Desember'
  ];

  /// "Minggu, 15 November 2026"
  static String dateLong(DateTime d) =>
      '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';

  /// "Baru saja", "5 menit lalu", "2 jam lalu", "3 hari lalu", "12 Nov 2026"
  static String ago(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari lalu';
    return '${t.day} ${_bulan[t.month - 1].substring(0, 3)} ${t.year}';
  }
}
