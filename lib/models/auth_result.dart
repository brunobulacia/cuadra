import '../models/profile.dart';

/// Resultado de un login o register exitoso.
class AuthResult {
  const AuthResult({required this.accessToken, required this.profile});

  final String accessToken;
  final Profile profile;
}
