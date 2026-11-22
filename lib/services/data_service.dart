import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/calc.dart';
import 'auth_service.dart';

class UnitItem {
  final String id;
  final String nama;
  const UnitItem(this.id, this.nama);
  factory UnitItem.from(Map j) =>
      UnitItem(j['id'] as String, j['nama'] as String);
}

class CategoryItem {
  final String id;
  final String nama;
  const CategoryItem(this.id, this.nama);
  factory CategoryItem.from(Map j) =>
      CategoryItem(j['id'] as String, j['nama'] as String);
}

double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

class MaterialItem {
  final String id;
  final String nama;
  final double hargaBeli;
  final double jumlahBeli;
  final String? unitId;
  final String unit;
  final double penyusutan; 
  final int usedCount;

  const MaterialItem({
    required this.id,
    required this.nama,
    required this.hargaBeli,
    required this.jumlahBeli,
    required this.unitId,
    required this.unit,
    required this.penyusutan,
    this.usedCount = 0,
  });

  factory MaterialItem.from(Map j) => MaterialItem(
        id: j['id'] as String,
        nama: j['nama'] as String,
        hargaBeli: _d(j['harga_beli']),
        jumlahBeli: _d(j['jumlah_beli']),
        unitId: j['unit_id'] as String?,
        unit: (j['unit'] as String?) ?? 'pcs',
        penyusutan: _d(j['penyusutan']),
        usedCount: (j['used_count'] as num?)?.toInt() ?? 0,
      );

  double get unitCost => MaterialCost.unitCost(
        hargaBeli: hargaBeli,
        jumlahBeli: jumlahBeli,
        penyusutanPersen: penyusutan,
      );
}

class EmployeeItem {
  final String id;
  final String username;
  final String? fotoUrl;
  final double tarif;
  final String satuanTarif;
  const EmployeeItem(
    this.id,
    this.username,
    this.fotoUrl, {
    this.tarif = 0,
    this.satuanTarif = 'jam',
  });
  factory EmployeeItem.from(Map j) => EmployeeItem(
        j['id'] as String,
        j['username'] as String,
        j['foto_url'] as String?,
        tarif: _d(j['tarif']),
        satuanTarif: (j['satuan_tarif'] as String?) ?? 'jam',
      );

  String get metodeLabel {
    switch (satuanTarif) {
      case 'hari':
        return 'Tarif per Hari';
      case 'output':
        return 'Tarif per Output';
      case 'manual':
        return 'Input Manual';
      default:
        return 'Tarif per Jam';
    }
  }
}

class ProductSummary {
  final String id;
  final String nama;
  final DateTime createdAt;
  final double jumlahProduksi;
  final String? unitId;
  final String unit;
  final String? categoryId;
  final String kategori;
  final String? overheadMode;
  final double? overheadPersen;
  final String? marginMetode;
  final double? marginNilai;
  final double totalHpp;
  final double hargaJual;
  final double labaBersih;
  final double hargaNet;
  final double marginTarget;
  final double hppBahan;
  final double hppTenaga;
  final double hppOverhead;
  final double servicePersen;
  final String? pajakJenis;
  final double pajakPersen;
  final bool pajakTermasuk;
  final bool pembulatan;
  final double? pembulatanStep;
  final double diskonPersen;
  final String? diskonMode;
  final double diskonNilai;
  final double sisaStok;
  final String? fotoUrl;

  const ProductSummary({
    required this.id,
    required this.nama,
    required this.createdAt,
    required this.jumlahProduksi,
    this.unitId,
    required this.unit,
    this.categoryId,
    required this.kategori,
    this.overheadMode,
    this.overheadPersen,
    this.marginMetode,
    this.marginNilai,
    required this.totalHpp,
    required this.hargaJual,
    required this.labaBersih,
    required this.hargaNet,
    required this.marginTarget,
    this.hppBahan = 0,
    this.hppTenaga = 0,
    this.hppOverhead = 0,
    required this.servicePersen,
    required this.pajakJenis,
    required this.pajakPersen,
    required this.pajakTermasuk,
    required this.pembulatan,
    this.pembulatanStep,
    this.diskonPersen = 0,
    this.diskonMode,
    this.diskonNilai = 0,
    this.sisaStok = 0,
    required this.fotoUrl,
  });

  factory ProductSummary.from(Map j) {
    final qty = _d(j['jumlah_produksi']);
    return ProductSummary(
      id: j['id'] as String,
      nama: j['nama'] as String,
      createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      jumlahProduksi: qty,
      unitId: j['unit_id'] as String?,
      unit: (j['unit'] as String?) ?? 'pcs',
      categoryId: j['category_id'] as String?,
      kategori: (j['kategori'] as String?) ?? 'Lainnya',
      overheadMode: j['overhead_mode'] as String?,
      overheadPersen:
          j['overhead_persen'] == null ? null : _d(j['overhead_persen']),
      marginMetode: j['margin_metode'] as String?,
      marginNilai: j['margin_nilai'] == null ? null : _d(j['margin_nilai']),
      totalHpp: _d(j['total_hpp']),
      hargaJual: _d(j['harga_jual']),
      labaBersih: _d(j['laba_bersih']),
      hargaNet: _d(j['harga_net']),
      marginTarget: _d(j['margin_target']),
      hppBahan: _d(j['hpp_bahan']),
      hppTenaga: _d(j['hpp_tenaga']),
      hppOverhead: _d(j['hpp_overhead']),
      servicePersen: _d(j['service_charge_persen']),
      pajakJenis: j['pajak_jenis'] as String?,
      pajakPersen: _d(j['pajak_persen']),
      pajakTermasuk: j['pajak_termasuk'] == true,
      pembulatan: j['pembulatan'] == true,
      pembulatanStep:
          j['pembulatan_step'] == null ? null : _d(j['pembulatan_step']),
      diskonPersen: _d(j['diskon_persen']),
      diskonMode: j['diskon_mode'] as String?,
      diskonNilai: _d(j['diskon_nilai']),
      sisaStok: j['sisa_stok'] == null ? qty : _d(j['sisa_stok']),
      fotoUrl: j['foto_url'] as String?,
    );
  }

  double get hppPerUnit => jumlahProduksi > 0 ? totalHpp / jumlahProduksi : 0;
  double get hargaJualPerUnit =>
      jumlahProduksi > 0 ? hargaJual / jumlahProduksi : 0;
  double get hargaNetPerUnit =>
      jumlahProduksi > 0 ? hargaNet / jumlahProduksi : 0;

  bool get hasDiscount => diskonPersen > 0 || diskonNilai > 0;

  double get potonganPerUnit {
    if (!hasDiscount) return 0;
    if (diskonMode == 'nominal' && diskonNilai > 0) {
      return diskonNilai.clamp(0, hargaJualPerUnit);
    }
    final pct = diskonMode == 'persen' && diskonNilai > 0
        ? diskonNilai
        : diskonPersen;
    return (hargaJualPerUnit * pct / 100).clamp(0, hargaJualPerUnit);
  }

  // Harga jual per unit 
  double get effectivePricePerUnit =>
      (hargaJualPerUnit - potonganPerUnit).clamp(0.0, double.infinity);

  String? get diskonLabel {
    if (!hasDiscount) return null;
    if (diskonMode == 'nominal' && diskonNilai > 0) {
      final n = diskonNilai.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
      return 'Diskon Rp$n';
    }
    final pct = diskonMode == 'persen' && diskonNilai > 0
        ? diskonNilai
        : diskonPersen;
    return 'Diskon ${_p(pct)}%';
  }

  double get keuntunganAktual => hargaNet > 0 ? labaBersih / hargaNet * 100 : 0;

  bool get hasService => servicePersen > 0;
  bool get hasTax => pajakJenis != null && pajakPersen > 0;

  String? get tambahanLabel {
    final parts = <String>[];
    if (hasService) parts.add('Biaya Layanan ${_p(servicePersen)}%');
    if (hasTax) parts.add('Pajak');
    return parts.isEmpty ? null : 'Termasuk: ${parts.join(' + ')}';
  }

  static String _p(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toString().replaceAll('.', ',');
}

class HomeData {
  final String username;
  final String role;
  final String? fotoUrl;
  final String businessId;
  final String businessName;
  final String businessCategory;
  final String businessDescription;
  final String? businessLogo;
  final int productCount;
  final double pendapatan;
  final double keuntungan;
  final List<ProductSummary> recentList;

  HomeData({
    required this.username,
    required this.role,
    required this.fotoUrl,
    required this.businessId,
    required this.businessName,
    required this.businessCategory,
    this.businessDescription = '',
    required this.businessLogo,
    required this.productCount,
    required this.pendapatan,
    required this.keuntungan,
    required this.recentList,
  });

  ProductSummary? get recent => recentList.isEmpty ? null : recentList.first;

  bool get isBos => role == 'bos';
}

class ProductDetail {
  final ProductSummary summary;
  final List<Map<String, dynamic>> materials;
  final List<Map<String, dynamic>> labors;
  final List<Map<String, dynamic>> overheads;
  const ProductDetail(
      this.summary, this.materials, this.labors, this.overheads);
}

class SaleReportItem {
  final String saleId;
  final String productName;
  final String kategori;
  final double kuantitas;
  final double hargaSatuan;
  final double total;
  final String kasir;
  final DateTime createdAt;
  const SaleReportItem({
    required this.saleId,
    required this.productName,
    required this.kategori,
    required this.kuantitas,
    required this.hargaSatuan,
    required this.total,
    required this.kasir,
    required this.createdAt,
  });

  factory SaleReportItem.from(Map j) => SaleReportItem(
        saleId: j['sale_id'] as String,
        productName: (j['product_name'] as String?) ?? 'Produk',
        kategori: (j['kategori'] as String?) ?? 'Lainnya',
        kuantitas: _d(j['kuantitas']),
        hargaSatuan: _d(j['harga_satuan']),
        total: _d(j['total']),
        kasir: (j['kasir'] as String?) ?? '-',
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );
}

class ReportData {
  final int txCount;
  final double pendapatan;
  final double keuntungan;
  final double avgMargin;
  final List<SaleReportItem> items;
  const ReportData({
    required this.txCount,
    required this.pendapatan,
    required this.keuntungan,
    required this.avgMargin,
    required this.items,
  });

  factory ReportData.from(Map j) => ReportData(
        txCount: (j['tx_count'] as num?)?.toInt() ?? 0,
        pendapatan: _d(j['pendapatan']),
        keuntungan: _d(j['keuntungan']),
        avgMargin: _d(j['avg_margin']),
        items: (j['items'] as List? ?? [])
            .map((e) => SaleReportItem.from(e as Map))
            .toList(),
      );
}

class DataFailure implements Exception {
  final String code;
  final String message;
  const DataFailure(this.code, [this.message = '']);
  @override
  String toString() => 'DataFailure($code) $message';
}

// service
class DataService extends ChangeNotifier {
  DataService._();
  static final instance = DataService._();

  SupabaseClient get _db => Supabase.instance.client;

  HomeData? home;
  List<UnitItem> units = [];
  List<CategoryItem> categories = [];
  List<MaterialItem> materials = [];
  List<EmployeeItem> employees = [];
  bool loading = false;
  String? error;

  String get _token {
    final t = AuthService.instance.token;
    if (t == null) throw const DataFailure('unauthorized');
    return t;
  }

  Never _fail(Object e) {
    if (e is PostgrestException) {
      final m = e.message;
      for (final c in const [
        'unauthorized',
        'forbidden',
        'user_taken',
        'password_short',
        'invalid_pin',
        'invalid_material',
        'no_materials',
        'invalid_product',
        'empty_name',
        'empty_sale',
        'out_of_stock',
      ]) {
        if (m.contains(c)) throw DataFailure(c, m);
      }
      throw DataFailure('server', m);
    }
    throw const DataFailure('network');
  }

  Future<dynamic> _rpc(String fn,
      [Map<String, dynamic> params = const {}]) async {
    try {
      return await _db
          .rpc(fn, params: {'p_token': _token, ...params})
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      if (e is DataFailure) rethrow;
      _fail(e);
    }
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final r = Map<String, dynamic>.from(await _rpc('bootstrap') as Map);
      final p = Map<String, dynamic>.from(r['profile'] as Map);
      final b = Map<String, dynamic>.from(r['business'] as Map);
      final s = Map<String, dynamic>.from(r['stats'] as Map);
      final recent = (r['recent'] as List);
      units = (r['units'] as List).map((e) => UnitItem.from(e as Map)).toList();
      categories = (r['categories'] as List)
          .map((e) => CategoryItem.from(e as Map))
          .toList();
      materials = (r['materials'] as List)
          .map((e) => MaterialItem.from(e as Map))
          .toList();
      employees = (r['employees'] as List)
          .map((e) => EmployeeItem.from(e as Map))
          .toList();
      home = HomeData(
        username: p['username'] as String,
        role: p['role'] as String,
        fotoUrl: p['foto_url'] as String?,
        businessId: b['id'] as String,
        businessName: b['nama'] as String,
        businessCategory: (b['kategori'] as String?) ?? '-',
        businessDescription: (b['deskripsi'] as String?) ?? '',
        businessLogo: b['logo_url'] as String?,
        productCount: (s['product_count'] as num).toInt(),
        pendapatan: _d(s['pendapatan']),
        keuntungan: _d(s['keuntungan']),
        recentList: recent
            .map((e) => ProductSummary.from(e as Map))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    } on DataFailure catch (e) {
      error = e.code;
    }
    loading = false;
    notifyListeners();
  }

  void clear() {
    home = null;
    units = [];
    categories = [];
    materials = [];
    employees = [];
    error = null;
  }

  Future<List<ProductSummary>> listProducts({int limit = 200}) async {
    final r = await _rpc('list_products', {'p_limit': limit}) as List;
    return r.map((e) => ProductSummary.from(e as Map)).toList();
  }

  Future<ProductDetail> getProduct(String id) async {
    final r = Map<String, dynamic>.from(
        await _rpc('get_product', {'p_id': id}) as Map);
    List<Map<String, dynamic>> l(String k) =>
        (r[k] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return ProductDetail(
        ProductSummary.from(r), l('materials'), l('labors'), l('overheads'));
  }

  Future<void> deleteProduct(String id) async {
    await _rpc('delete_product', {'p_id': id});
    await load();
  }

  Future<UnitItem> addUnit(String nama) async {
    final r = await _rpc('add_unit', {'p_nama': nama}) as Map;
    final u = UnitItem.from(r);
    if (!units.any((x) => x.id == u.id)) units = [...units, u];
    notifyListeners();
    return u;
  }

  Future<CategoryItem> addCategory(String nama) async {
    final r = await _rpc('add_category', {'p_nama': nama}) as Map;
    final c = CategoryItem.from(r);
    if (!categories.any((x) => x.id == c.id)) categories = [...categories, c];
    notifyListeners();
    return c;
  }

  Future<MaterialItem> saveMaterial({
    String? id,
    required String nama,
    required double harga,
    required double jumlah,
    required String? unitId,
    required double penyusutan,
  }) async {
    final r = await _rpc('save_material', {
      'p_id': id,
      'p_nama': nama,
      'p_harga': harga,
      'p_jumlah': jumlah,
      'p_unit_id': unitId,
      'p_penyusutan': penyusutan,
    }) as Map;
    final m = MaterialItem.from(r);
    final i = materials.indexWhere((x) => x.id == m.id);
    materials = i >= 0
        ? ([...materials]..[i] = m)
        : ([...materials, m]..sort((a, b) => a.nama.compareTo(b.nama)));
    notifyListeners();
    return m;
  }

  Future<void> deleteMaterial(String id) async {
    await _rpc('delete_material', {'p_id': id});
    materials = materials.where((m) => m.id != id).toList();
    notifyListeners();
  }

  Future<String?> _uploadBinary(
      String bucket, String prefix, Uint8List bytes) async {
    final path =
        '$prefix/${home?.businessId ?? 'x'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _db.storage
        .from(bucket)
        .uploadBinary(path, bytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: false))
        .timeout(const Duration(seconds: 15));
    return _db.storage.from(bucket).getPublicUrl(path);
  }

  Future<EmployeeItem> createEmployee({
    required String username,
    required String password,
    required String pin,
    Uint8List? foto,
    double tarif = 0,
    String satuanTarif = 'jam',
  }) async {
    final url =
        foto == null ? null : await _uploadBinary('avatars', 'karyawan', foto);
    final r = await _rpc('create_employee_full', {
      'p_username': username,
      'p_password': password,
      'p_pin': pin,
      'p_foto_url': url,
      'p_tarif': tarif,
      'p_satuan_tarif': satuanTarif,
    }) as Map;
    final e = EmployeeItem.from(r);
    employees = [...employees, e];
    notifyListeners();
    return e;
  }

  Future<EmployeeItem> updateEmployee({
    required String empId,
    required String username,
    Uint8List? foto,
    double? tarif,
    String? satuanTarif,
    String? password,
    String? pin,
  }) async {
    final url =
        foto == null ? null : await _uploadBinary('avatars', 'karyawan', foto);
    final r = await _rpc('update_employee', {
      'p_emp_id': empId,
      'p_username': username,
      'p_foto_url': url,
      'p_tarif': tarif,
      'p_satuan_tarif': satuanTarif,
      'p_password': password,
      'p_pin': pin,
    }) as Map;
    final e = EmployeeItem.from(r);
    final i = employees.indexWhere((x) => x.id == e.id);
    if (i >= 0) employees = [...employees]..[i] = e;
    notifyListeners();
    await load();
    return e;
  }

  Future<String?> uploadProductPhoto(Uint8List bytes) =>
      _uploadBinary('logos', 'produk', bytes);

  Future<ProductSummary> saveProduct(Map<String, dynamic> payload) async {
    final r = await _rpc('save_product', {'p': payload}) as Map;
    final p = ProductSummary.from(r);
    await load();
    return p;
  }

  Future<ProductSummary> updateProduct(
      String id, Map<String, dynamic> payload) async {
    final r = await _rpc('update_product', {'p_id': id, 'p': payload}) as Map;
    final p = ProductSummary.from(r);
    await load();
    return p;
  }

  Future<ProductSummary> setProductDiscount({
    required String productId,
    String? mode, 
    double nilai = 0,
    double persen = 0,
  }) async {
    final r = await _rpc('set_product_discount', {
      'p_id': productId,
      'p_mode': mode,
      'p_nilai': nilai,
      'p_persen': persen,
    }) as Map;
    final p = ProductSummary.from(r);
    await load();
    return p;
  }

  Future<ProductSummary> updateProductStock({
    required String productId,
    required double nilai,
    String mode = 'add', // 'add' | 'set'
  }) async {
    final r = await _rpc('update_product_stock', {
      'p_id': productId,
      'p_nilai': nilai,
      'p_mode': mode,
    }) as Map;
    final p = ProductSummary.from(r);
    await load();
    return p;
  }

  Future<void> createSale(List<Map<String, dynamic>> items) async {
    await _rpc('create_sale', {'p_items': items});
    await load();
  }

  Future<ReportData> getReport(String range) async {
    final r = await _rpc('get_report', {'p_range': range}) as Map;
    return ReportData.from(r);
  }

  Future<void> updateProfile({String? username, Uint8List? foto}) async {
    final url =
        foto == null ? null : await _uploadBinary('avatars', 'profil', foto);
    await _rpc('update_profile', {
      'p_username': username ?? home?.username ?? '',
      'p_foto_url': url,
    });
    await load();
  }

  Future<void> changePassword(String newPassword) async {
    await _rpc('change_password', {'p_new_password': newPassword});
  }

  Future<void> changePin(String newPin) async {
    await _rpc('change_pin', {'p_new_pin': newPin});
  }

  Future<void> updateBusiness({
    required String nama,
    required String kategori,
    required String deskripsi,
    Uint8List? logo,
  }) async {
    final url =
        logo == null ? null : await _uploadBinary('logos', 'usaha', logo);
    await _rpc('update_business', {
      'p_nama': nama,
      'p_kategori': kategori,
      'p_deskripsi': deskripsi,
      'p_logo_url': url,
    });
    await load();
  }
}
