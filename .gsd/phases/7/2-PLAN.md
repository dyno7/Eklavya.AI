---
phase: 7
plan: 2
wave: 2
depends_on: [1]
autonomous: true
files_modified:
  - eklavya_mobile/pubspec.yaml
  - eklavya_mobile/lib/core/services/auth_service.dart
  - eklavya_mobile/lib/features/auth/login_screen.dart
  - eklavya_mobile/lib/features/auth/signup_screen.dart
---

# Plan 7.2: Real Supabase Auth in Flutter

## Objective
The `LoginScreen` has a hardcoded dummy check (`admin@gmail.com / 123456`). No sign-up exists. This plan replaces it with a real Supabase email/password flow using the `supabase_flutter` SDK. After login, the Supabase `Session` is stored globally via a simple `AuthService` singleton so all other services can retrieve the JWT.

## Context
- eklavya_mobile/lib/features/auth/login_screen.dart
- eklavya_mobile/lib/core/router/app_router.dart
- eklavya_mobile/lib/main.dart
- eklavya_backend/.env (for SUPABASE_URL + SUPABASE_ANON_KEY)

## Tasks

<task type="auto">
  <name>Add supabase_flutter SDK and initialise Supabase in main.dart</name>
  <files>
    eklavya_mobile/pubspec.yaml
    eklavya_mobile/lib/main.dart
    eklavya_mobile/lib/core/services/auth_service.dart
  </files>
  <action>
    1. In `pubspec.yaml`, add under `dependencies`:
       `supabase_flutter: ^2.7.0`
    2. Run `flutter pub get`
    3. In `main.dart`, add before `runApp()`:
       ```dart
       await Supabase.initialize(
         url: 'https://YOUR_PROJECT_REF.supabase.co',
         anonKey: 'YOUR_ANON_KEY',
       );
       ```
       — Read these from the .env (hardcode for now; we'll move to --dart-define in Phase 8).
    4. Create `lib/core/services/auth_service.dart`:
       ```dart
       import 'package:supabase_flutter/supabase_flutter.dart';
       
       class AuthService {
         static final _client = Supabase.instance.client;
         
         static String? get accessToken => _client.auth.currentSession?.accessToken;
         static User? get currentUser => _client.auth.currentUser;
         static bool get isLoggedIn => currentUser != null;
         
         static Future<AuthResponse> signIn(String email, String password) =>
             _client.auth.signInWithPassword(email: email, password: password);
         
         static Future<AuthResponse> signUp(String email, String password) =>
             _client.auth.signUp(email: email, password: password);
         
         static Future<void> signOut() => _client.auth.signOut();
       }
       ```
  </action>
  <verify>flutter pub get succeeds; flutter analyze lib/core/services/auth_service.dart</verify>
  <done>Supabase is initialised in main.dart, AuthService class exists and compiles</done>
</task>

<task type="auto">
  <name>Replace dummy LoginScreen with real Supabase auth + add SignupScreen</name>
  <files>
    eklavya_mobile/lib/features/auth/login_screen.dart
    eklavya_mobile/lib/features/auth/signup_screen.dart
    eklavya_mobile/lib/core/router/app_router.dart
  </files>
  <action>
    1. In `login_screen.dart`, replace `_handleLogin()` dummy logic with:
       ```dart
       Future<void> _handleLogin() async {
         setState(() => _isLoading = true);
         try {
           await AuthService.signIn(_emailController.text.trim(), _passwordController.text);
           if (!mounted) return;
           context.go('/home');
         } on AuthException catch (e) {
           if (!mounted) return;
           setState(() => _isLoading = false);
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
         }
       }
       ```
    2. Add a "Don't have an account? Sign Up" text button below the form that calls `context.push('/signup')`
    3. Create `lib/features/auth/signup_screen.dart` — same UI structure as login but calls `AuthService.signUp()`. On success, navigate to `/home`.
    4. Register `/signup` route in `app_router.dart`.
    5. Update `splash_screen.dart` `initState` to check `AuthService.isLoggedIn`:
       ```dart
       Timer(Duration(milliseconds: 2500), () {
         if (!mounted) return;
         context.go(AuthService.isLoggedIn ? '/home' : '/login');
       });
       ```
  </action>
  <verify>flutter analyze lib/features/auth/</verify>
  <done>Login and Sign-up both work via Supabase. Splash routes logged-in users directly to /home.</done>
</task>

## Success Criteria
- [ ] User can sign up with a new email via in-app form
- [ ] User can log in with existing Supabase credentials
- [ ] Splash screen skips login if session already exists (persistent login)
- [ ] `flutter analyze lib/` — zero errors
