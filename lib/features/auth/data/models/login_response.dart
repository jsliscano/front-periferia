class LoginResponse {
  const LoginResponse({
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

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      type: (json['type'] as String?) ?? 'Bearer',
      userId: (json['userId'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}
