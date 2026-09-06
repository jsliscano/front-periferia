/// Sesión autenticada tras un login exitoso.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.type,
    required this.userId,
    required this.name,
    required this.email,
  });

  final String token;
  final String type;
  final int userId;
  final String name;
  final String email;

  String get authorizationHeader => '$type $token';
}
