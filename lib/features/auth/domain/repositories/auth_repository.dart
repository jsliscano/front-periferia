import '../entities/auth_session.dart';
import '../entities/user.dart';

/// Contrato del repositorio de autenticación.
abstract class AuthRepository {
  Future<User> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthSession> login({
    required String email,
    required String password,
  });
}
