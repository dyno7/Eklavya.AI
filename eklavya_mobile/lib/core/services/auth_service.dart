import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton wrapper around Supabase Auth for the entire app.
/// All services read the JWT from here.
class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// The current session's access token (JWT).
  static String? get accessToken =>
      _client.auth.currentSession?.accessToken;

  /// The currently logged-in user.
  static User? get currentUser => _client.auth.currentUser;

  /// Whether a user is currently authenticated.
  static bool get isLoggedIn => currentUser != null;

  /// The user's Supabase UUID.
  static String get userId => currentUser?.id ?? 'anonymous';

  /// Display name from user metadata.
  static String get displayName =>
      currentUser?.userMetadata?['display_name'] as String? ??
      currentUser?.email?.split('@').first ??
      'Learner';

  /// Sign in with email + password.
  static Future<AuthResponse> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  /// Create a new account with email + password.
  /// Sets display_name in user metadata.
  /// Returns (AuthResponse, needsEmailConfirmation)
  static Future<(AuthResponse, bool)> signUp(
    String email,
    String password, {
    String? displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );

    // If Supabase has "Confirm email" enabled, session will be null
    // after signup. The user exists but can't log in until confirmed.
    final needsConfirmation = response.session == null && response.user != null;

    return (response, needsConfirmation);
  }

  /// Sign out and clear session.
  static Future<void> signOut() => _client.auth.signOut();

  /// Sign in with Google OAuth.
  /// On web: opens Google login in a popup/redirect.
  /// On mobile: opens Google login in the system browser.
  /// After successful auth, Supabase stores the session automatically.
  static Future<bool> signInWithGoogle() async {
    final success = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.eklavya://login-callback/',
    );
    return success;
  }

  /// Listen for auth state changes (e.g., OAuth redirect completing).
  /// Returns a subscription that should be cancelled on dispose.
  static Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;
}
