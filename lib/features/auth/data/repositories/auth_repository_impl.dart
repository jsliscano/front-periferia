import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request.dart';
import '../models/register_user_request.dart';
import '../session_store.dart';

/// Implementación que habla con el backend Spring Boot.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({AuthRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource();

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.register(
      RegisterUserRequest(
        name: name,
        email: email,
        password: password,
      ),
    );

    return User(
      id: response.id,
      name: response.name,
      email: response.email,
    );
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      LoginRequest(
        email: email,
        password: password,
      ),
    );

    final session = AuthSession(
      token: response.token,
      type: response.type,
      userId: response.userId,
      name: response.name,
      email: response.email,
    );

    SessionStore.save(session);
    return session;
  }
}
