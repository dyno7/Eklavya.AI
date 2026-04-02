import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton wrapper around Supabase Auth for the entire app.
/// All services read the JWT from here.
class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// The current session's access token (JWT).
  /// Returns null if not logged in.
  static String? get accessToken =>
      _client.auth.currentSession?.accessToken;

  /// The currently logged-in user.
  static User? get currentUser => _client.auth.currentUser;

  /// Whether a user is currently authenticated.
  static bool get isLoggedIn => currentUser != null;

  /// The user's Supabase UUID.
  static String get userId => currentUser?.id ?? 'anonymous';

  /// Sign in with email + password.
  static Future<AuthResponse> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  /// Create a new account with email + password.
  static Future<AuthResponse> signUp(String email, String password) =>
      _client.auth.signUp(email: email, password: password);

  /// Sign out and clear session.
  static Future<void> signOut() => _client.auth.signOut();
}
