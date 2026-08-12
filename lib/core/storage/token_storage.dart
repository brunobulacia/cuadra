import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kTokenKey = 'access_token';

/// Thin wrapper around [FlutterSecureStorage] para guardar/leer el JWT.
class TokenStorage {
  const TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> save(String token) =>
      _storage.write(key: _kTokenKey, value: token);

  Future<String?> read() => _storage.read(key: _kTokenKey);

  Future<void> delete() => _storage.delete(key: _kTokenKey);
}
