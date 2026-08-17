# Google Sign-In Configuration for Eklavya.AI

This document describes the required Google Cloud Console and Supabase configuration for native Google Sign-In on Android.

## Overview

The app now uses **native Google Sign-In** on Android/iOS instead of the browser-based Supabase OAuth flow. This avoids showing the random Supabase domain (`<project-id>.supabase.co`) during Google authentication.

## Google Cloud Console Configuration

### 1. Create/Select Project
- Go to [Google Cloud Console](https://console.cloud.google.com/)
- Create a new project or select existing: **Eklavya.AI**

### 2. Configure OAuth Consent Screen
1. Navigate to **APIs & Services** → **OAuth consent screen**
2. Set **App name**: `Eklavya.AI`
3. Set **User support email**: Your support email
4. Set **App logo**: Upload Eklavya.AI logo
5. Set **Authorized domains**: Add your domain if you have one (optional for mobile-only)
6. **Scopes**: Add `.../auth/userinfo.email`, `.../auth/userinfo.profile`, `openid`
7. **Test users**: Add test emails during development
8. **Publishing status**: Keep as "Testing" during development, publish when ready

### 3. Create OAuth 2.0 Client IDs

You need **two** OAuth client IDs:

#### A. Android Client (for native Google Sign-In SDK)
1. Go to **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth client ID**
2. **Application type**: Android
3. **Name**: `Eklavya.AI Android`
4. **Package name**: `ai.eklavya.eklavya_mobile` (must match `applicationId` in `android/app/build.gradle.kts`)
5. **SHA-1 certificate fingerprint**:
   - Debug: Run `./gradlew signingReport` in `android/` folder, copy SHA-1 from `debug` variant
   - Release: Copy SHA-1 from `release` variant (from your keystore)
6. **Create** → Copy the **Client ID** (not needed in app code, but used by Google Play Services)

#### B. Web/Server Client (for ID token verification by Supabase)
1. Go to **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth client ID**
2. **Application type**: Web application
3. **Name**: `Eklavya.AI Server`
4. **Authorized JavaScript origins**: 
   - `http://localhost:3000` (for local web testing)
   - `https://<your-project-id>.supabase.co` (Supabase project URL)
5. **Authorized redirect URIs**:
   - `https://<your-project-id>.supabase.co/auth/v1/callback`
6. **Create** → Copy the **Client ID** → This is your **`GOOGLE_SERVER_CLIENT_ID`**

### 4. Configure Supabase
1. Go to your Supabase project dashboard
2. Navigate to **Authentication** → **Providers** → **Google**
3. **Enable Google provider**
4. **Client ID**: Paste the **Web/Server Client ID** (from step 3B)
5. **Client Secret**: Paste the **Web/Server Client Secret** (from step 3B)
6. **Save**

## Android Configuration

### 1. Add `google-services.json` (Optional but Recommended)
1. In Google Cloud Console, go to **Firebase Console** (or create Firebase project linked to your Google Cloud project)
2. Add Android app with package name: `ai.eklavya.eklavya_mobile`
3. Download `google-services.json`
4. Place it at: `android/app/google-services.json`

> **Note**: The `google-services.json` is not strictly required if you pass the `serverClientId` programmatically (as done in `auth_service.dart`). However, it's recommended for proper Google Play Services integration and to avoid warnings.

### 2. Update `android/build.gradle.kts` (Project-level) — Only if using `google-services.json`
Add Google Services plugin:
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.1" apply false
}
```

### 3. Update `android/app/build.gradle.kts` (App-level) — Only if using `google-services.json`
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // Add this line
}
```

### 3. Intent Filter (Already Added)
The `AndroidManifest.xml` includes the required intent filter for the redirect URI:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="ai.eklavya.eklavya_mobile"/>
</intent-filter>
```

## Build Configuration

### Required `--dart-define` Flags
When building/running the app, you must provide:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<your-project-id>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key> \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-server-client-id-from-step-3B>
```

For release builds:
```bash
flutter build apk \
  --dart-define=SUPABASE_URL=https://<your-project-id>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key> \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-server-client-id-from-step-3B>
```

### Getting SHA-1 Fingerprints
```bash
cd android
./gradlew signingReport
```
Look for `SHA1` under `debug` and `release` variants.

## Testing Checklist

- [ ] Google Cloud OAuth consent screen configured with "Eklavya.AI" branding
- [ ] Android OAuth client created with correct package name and SHA-1
- [ ] Web/Server OAuth client created with Supabase callback URL
- [ ] Supabase Google provider enabled with Web/Server Client ID & Secret
- [ ] `google-services.json` placed in `android/app/`
- [ ] Google Services plugin added to Gradle files
- [ ] App runs with all three `--dart-define` flags
- [ ] "Continue with Google" button shows native Google account picker (not browser)
- [ ] After sign-in, user is redirected back to app and logged in
- [ ] User profile shows correct Google display name/email

## Troubleshooting

### "Sign in to continue to <random>.supabase.co" still appears
- You're using the old browser-based flow. Ensure you're on the latest code with native Google Sign-In.
- Check that `kIsWeb` is false on Android (it should be).
- Verify `GOOGLE_SERVER_CLIENT_ID` is correctly passed via `--dart-define`.

### "DEVELOPER_ERROR" or "Sign in failed"
- SHA-1 fingerprint mismatch: Verify debug/release SHA-1 in Google Cloud Console matches your build.
- Package name mismatch: Ensure `ai.eklavya.eklavya_mobile` matches exactly.
- `google-services.json` missing or incorrect: Re-download from Firebase Console.

### "Invalid ID token" from Supabase
- Ensure Supabase Google provider uses the **Web/Server Client ID** (not Android Client ID).
- Verify the Web/Server Client Secret is correctly set in Supabase.

### Redirect not working / App not opening after Google sign-in
- Check `AndroidManifest.xml` has the intent filter with scheme `ai.eklavya.eklavya_mobile`.
- Ensure `android:launchMode="singleTop"` is set on MainActivity.

## Architecture Notes

The native flow:
1. User taps "Continue with Google"
2. App calls `GoogleSignIn(...).signIn()` → Native Google account picker
3. User selects account → Google returns ID token (JWT)
4. App calls `supabase.auth.signInWithIdToken(provider: google, idToken: <token>)`
5. Supabase verifies ID token with Google, creates/links user, returns session
6. App receives session → User logged in

This completely bypasses the browser and Supabase's OAuth redirect flow, so the user never sees the Supabase domain.