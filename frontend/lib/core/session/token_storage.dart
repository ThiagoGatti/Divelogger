import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda o token no Keychain (iOS) / Keystore (Android).
class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kToken = 'access_token';
  static const _kExpiresAt = 'access_token_expires_at';
  static const _kUser = 'user_json';

  Future<void> save({
    required String token,
    required DateTime expiresAt,
    required String userJson,
  }) async {
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kExpiresAt, value: expiresAt.millisecondsSinceEpoch.toString());
    await _storage.write(key: _kUser, value: userJson);
  }

  Future<({String? token, DateTime? expiresAt, String? userJson})> read() async {
    try {
      final token = await _storage.read(key: _kToken);
      final exp = await _storage.read(key: _kExpiresAt);
      final user = await _storage.read(key: _kUser);
      final ms = exp == null ? null : int.tryParse(exp);
      return (
        token: token,
        expiresAt: ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms),
        userJson: user,
      );
    } catch (_) {
      // Keystore corrompido (acontece após restore de backup no Android): trata como deslogado.
      await clear();
      return (token: null, expiresAt: null, userJson: null);
    }
  }

  Future<void> clear() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
