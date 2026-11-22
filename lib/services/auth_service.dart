import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum LoginCheck { ok, userInvalid, businessInvalid, bothInvalid }

class PinResult {
  final bool ok;
  final int attemptsLeft;
  final DateTime? lockedUntil;
  const PinResult(this.ok, this.attemptsLeft, this.lockedUntil);

  bool get locked =>
      lockedUntil != null && lockedUntil!.isAfter(DateTime.now());

  factory PinResult.fromJson(Map<String, dynamic> j) => PinResult(
        j['ok'] == true,
        (j['left'] as num?)?.toInt() ?? 0,
        j['locked_until'] == null
            ? null
            : DateTime.parse(j['locked_until'] as String).toLocal(),
      );
}

class AppProfile {
  final String id;
  final String username;
  final String role;
  final String? fotoUrl;
  final String? businessId;
  final String? businessName;
  final String? businessLogo;
  const AppProfile({
    required this.id,
    required this.username,
    required this.role,
    this.fotoUrl,
    this.businessId,
    this.businessName,
    this.businessLogo,
  });
}

class AuthFailure implements Exception {
  final String
      code; 
  final String message;
  const AuthFailure(this.code, [this.message = '']);
  @override
  String toString() => 'AuthFailure($code) $message';
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  static const _kUserIdKey = 'labaku_user_id';
  static const _kTokenKey = 'labaku_session_token';

  SupabaseClient get _db => Supabase.instance.client;

  String? _userId;
  String? _pendingUserId;
  String? _token;

  String? get userId => _userId;
  String? get token => _token;

  bool unlocked = false;

  bool get hasSession =>
      _userId != null && _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_kUserIdKey);
    final tok = prefs.getString(_kTokenKey);
    if (uid != null && uid.isNotEmpty && tok != null && tok.isNotEmpty) {
      _userId = uid;
      _token = tok;
      unlocked = true;
    } else {
      _userId = null;
      _token = null;
      unlocked = false;
    }
  }

  Future<void> _saveSession(String uid, String token) async {
    _userId = uid;
    _pendingUserId = null;
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserIdKey, uid);
    await prefs.setString(_kTokenKey, token);
  }

  static String slug(String s) {
    final r = s.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return r.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static LoginCheck _parseStatus(String status) {
    switch (status) {
      case 'ok':
        return LoginCheck.ok;
      case 'user_invalid':
        return LoginCheck.userInvalid;
      case 'business_invalid':
        return LoginCheck.businessInvalid;
      default:
        return LoginCheck.bothInvalid;
    }
  }

  Future<LoginCheck> loginCheck(String username, String business) async {
    final r = await _db.rpc('login_check', params: {
      'p_slug': business.trim(),
      'p_username': username.trim(),
    });
    return _parseStatus(r as String);
  }

  Future<LoginCheck> signIn(
      String username, String business, String password) async {
    final r = await _db.rpc('login_user', params: {
      'p_slug': business.trim(),
      'p_username': username.trim(),
      'p_password': password,
    });
    final data = Map<String, dynamic>.from(r as Map);
    final status = data['status'] as String? ?? 'both_invalid';

    if (status == 'password_invalid') {
      throw const AuthFailure('invalid_credentials');
    }
    if (status != 'ok') {
      return _parseStatus(status);
    }

    _pendingUserId = data['user_id'] as String;
    return LoginCheck.ok;
  }

  Future<PinResult> verifyPin(String pin) async {
    final uid = _pendingUserId ?? _userId;
    if (uid == null) throw const AuthFailure('unknown', 'Sesi tidak ditemukan');

    final r = await _db.rpc('verify_pin', params: {
      'p_uid': uid,
      'p_pin': pin,
    });
    final map = Map<String, dynamic>.from(r as Map);
    final res = PinResult.fromJson(map);
    final tok = map['token'] as String?;
    if (res.ok && tok != null) {
      unlocked = true;
      await _saveSession(uid, tok);
    }
    return res;
  }

  Future<void> signOut() async {
    final tok = _token;
    unlocked = false;
    _userId = null;
    _pendingUserId = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserIdKey);
    await prefs.remove(_kTokenKey);
    if (tok != null) {
      try {
        await _db.rpc('logout', params: {'p_token': tok});
      } catch (_) {}
    }
  }

  // profil 
  Future<AppProfile?> myProfile() async {
    final uid = _userId ?? _pendingUserId;
    if (uid == null) return null;
    final r = await _db.rpc('get_profile', params: {'p_uid': uid});
    if (r == null) return null;
    final row = Map<String, dynamic>.from(r as Map);
    return AppProfile(
      id: row['id'] as String,
      username: row['username'] as String,
      role: row['role'] as String,
      fotoUrl: row['foto_url'] as String?,
      businessId: row['business_id'] as String?,
      businessName: row['business_name'] as String?,
      businessLogo: row['business_logo'] as String?,
    );
  }

  // daftar
  Future<bool> businessAvailable(String business) async {
    final r = await _db
        .rpc('business_available', params: {'p_slug': slug(business)});
    return r == true;
  }

  Future<void> registerOwner({
    required String username,
    required String password,
    required String pin,
    required String businessName,
    required String category,
    String? description,
    Uint8List? avatar,
    Uint8List? logo,
  }) async {
    final prefix = '${slug(businessName)}_${DateTime.now().millisecondsSinceEpoch}';

    // upload foto
    final urls = await Future.wait<String?>([
      _upload('avatars', prefix, avatar),
      _upload('logos', prefix, logo),
    ]);

    try {
      final r = await _db.rpc('register_owner', params: {
        'p_username': username.trim(),
        'p_password': password,
        'p_nama': businessName.trim(),
        'p_slug': slug(businessName),
        'p_kategori': category,
        'p_deskripsi':
            (description ?? '').trim().isEmpty ? null : description!.trim(),
        'p_logo_url': urls[1],
        'p_foto_url': urls[0],
        'p_pin': pin,
      });
      final m = Map<String, dynamic>.from(r as Map);
      unlocked = true;
      await _saveSession(m['uid'] as String, m['token'] as String);
    } on PostgrestException catch (e) {
      if (e.message.contains('business_taken')) {
        throw const AuthFailure('business_taken');
      }
      if (e.message.contains('password_short')) {
        throw const AuthFailure('unknown', 'Password minimal 6 karakter');
      }
      throw AuthFailure('unknown', e.message);
    }
  }

  Future<String?> _upload(String bucket, String prefix, Uint8List? bytes) async {
    if (bytes == null) return null;
    final path = '$prefix.jpg';
    await _db.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return _db.storage.from(bucket).getPublicUrl(path);
  }

  // lupa PIN 
  Future<LoginCheck> resetPin(
      String username, String business, String password, String newPin) async {
    final r = await _db.rpc('reset_pin', params: {
      'p_slug': business.trim(),
      'p_username': username.trim(),
      'p_password': password,
      'p_new_pin': newPin,
    });
    final data = Map<String, dynamic>.from(r as Map);
    final status = data['status'] as String? ?? 'both_invalid';

    if (status == 'password_invalid') {
      throw const AuthFailure('invalid_credentials');
    }
    if (status != 'ok') {
      return _parseStatus(status);
    }
    return LoginCheck.ok;
  }

  // lupa kata sandi
  Future<LoginCheck> precheckIdentity(String username, String business) =>
      loginCheck(username, business);

  /// Verifikasi dengan PIN 
  Future<PinResult> resetPassword(
      String username, String business, String pin, String newPassword) async {
    final r = await _db.rpc('reset_password', params: {
      'p_slug': business.trim(),
      'p_username': username.trim(),
      'p_pin': pin,
      'p_new_password': newPassword,
    });
    return PinResult.fromJson(Map<String, dynamic>.from(r as Map));
  }
}
