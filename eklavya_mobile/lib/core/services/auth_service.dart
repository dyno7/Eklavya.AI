import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  static Future<void> signOut() async {
    await _client.auth.signOut();
    await _googleSignIn.signOut();
  }

  /// Private GoogleSignIn instance configured with server client ID.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
    scopes: ['email', 'profile', 'openid'],
  );

  /// Sign in with Google using native platform flow.
  /// On Android: Uses Google Sign-In SDK → ID token → Supabase signInWithIdToken
  /// On iOS: Uses Google Sign-In SDK → ID token → Supabase signInWithIdToken
  /// On Web: Falls back to browser-based Supabase OAuth flow.
  static Future<bool> signInWithGoogle() async {
    if (kIsWeb) {
      return _signInWithGoogleWeb();
    }
    return _signInWithGoogleNative();
  }

  /// Native Google Sign-In for Android/iOS using Google ID token.
  /// This avoids the browser-based Supabase OAuth flow that shows the random Supabase domain.
  static Future<bool> _signInWithGoogleNative() async {
    // Verify server client ID is configured
    const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    if (serverClientId.isEmpty) {
      throw StateError(
        'Missing GOOGLE_SERVER_CLIENT_ID. '
        'Run with: flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=...',
      );
    }

    // Trigger the native Google Sign-In flow
    final GoogleSignInAccount? account = await _googleSignIn.signIn();

    if (account == null) {
      // User cancelled the sign-in flow
      return false;
    }

    // Get the ID token from the authenticated account
    final GoogleSignInAuthentication auth = await account.authentication;
    final String? idToken = auth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Failed to obtain Google ID token');
    }

    // Exchange the Google ID token for a Supabase session
    final AuthResponse response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    return response.session != null;
  }

  /// Web fallback: browser-based Supabase OAuth flow.
  static Future<bool> _signInWithGoogleWeb() async {
    final redirectTo = '${Uri.base.origin}/login';

    final success = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
    return success;
  }

  /// Listen for auth state changes (e.g., OAuth redirect completing).
  /// Returns a subscription that should be cancelled on dispose.
  static Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;
}
