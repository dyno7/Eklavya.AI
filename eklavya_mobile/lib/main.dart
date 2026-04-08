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

  // Read from --dart-define (set in launch config or CLI)
  // Fallback to the project defaults for convenience during dev.
  const supabaseUrlRaw = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://uhfydykjgbeqjwejtzip.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoZnlkeWtqZ2JlcWp3ZWp0emlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NjczNDMsImV4cCI6MjA5MDU0MzM0M30.StiG0hh84qmQMpOySUOCBYfTOaTmW94BySktoNq8jzE',
  );

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
