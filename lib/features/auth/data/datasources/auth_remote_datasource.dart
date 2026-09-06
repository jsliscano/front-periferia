import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_user_request.dart';
import '../models/user_response.dart';

/// Acceso remoto a endpoints de autenticación / usuarios.
class AuthRemoteDataSource {
  AuthRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<UserResponse> register(RegisterUserRequest request) async {
    final json = await _apiClient.post(
      ApiConfig.registerPath,
      body: request.toJson(),
    );
    return UserResponse.fromJson(json);
  }

  Future<LoginResponse> login(LoginRequest request) async {
    final json = await _apiClient.post(
      ApiConfig.loginPath,
      body: request.toJson(),
    );
    return LoginResponse.fromJson(json);
  }
}
