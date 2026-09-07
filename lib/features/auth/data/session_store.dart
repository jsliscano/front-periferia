import '../domain/entities/auth_session.dart';

class SessionStore {
  SessionStore._();

  static AuthSession? current;

  static bool get isAuthenticated => current != null;

  static void save(AuthSession session) {
    current = session;
  }

  static void clear() {
    current = null;
  }
}
