import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

String _normalizeSupabaseUrl(String rawUrl) {
  var value = rawUrl.trim();

  // Recover from malformed values like "https:///project.supabase.co".
  value = value.replaceFirst(RegExp(r'^https?:///+'), 'https://');
  value = value.replaceFirst(RegExp(r'^/+'), '');

  if (!value.startsWith('http://') && !value.startsWith('https://')) {
    value = 'https://$value';
  }

  final parsed = Uri.tryParse(value);
  if (parsed == null || parsed.host.isEmpty) {
    throw ArgumentError('Invalid SUPABASE_URL: $rawUrl');
  }

  final scheme = parsed.scheme.isEmpty ? 'https' : parsed.scheme;
  final port = parsed.hasPort ? ':${parsed.port}' : '';
  return '$scheme://${parsed.host}$port';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read from --dart-define (set in launch config or CLI).
  // No hardcoded defaults — credentials must be injected at build time.
  // Example: flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co
  //                      --dart-define=SUPABASE_ANON_KEY=eyJ...
  const supabaseUrlRaw = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrlRaw.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing required --dart-define flags: SUPABASE_URL and SUPABASE_ANON_KEY. '
      'Run with: flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
    );
  }

  final supabaseUrl = _normalizeSupabaseUrl(supabaseUrlRaw);

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    ProviderScope(child: EklavyaApp()),
  );
}

class EklavyaApp extends ConsumerWidget {
  const EklavyaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Eklavya.AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
