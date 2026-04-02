import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';

/// Sign-up screen with real Supabase email/password auth.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final (_, needsConfirmation) =
          await AuthService.signUp(email, password, displayName: name);

      if (!mounted) return;

      if (needsConfirmation) {
        // Email confirmation is enabled in Supabase.
        // User can't log in yet — take them back to login with a message.
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account created! Check your email to verify, then sign in.',
            ),
            duration: Duration(seconds: 5),
            backgroundColor: context.colors.success,
          ),
        );
        // Auto-sign-in: Supabase created the user. If "Confirm email" is OFF
        // in dashboard, this acts as a no-op message. If ON, user sees it.
        // Either way, try signing in immediately — it works if confirm is OFF.
        try {
          await AuthService.signIn(email, password);
          if (!mounted) return;
          context.go('/home');
          return;
        } catch (_) {
          // Confirm is ON and user hasn't confirmed yet —
          // navigate to login so they can try after confirming.
          if (!mounted) return;
          context.go('/login');
          return;
        }
      }

      // Session exists — account created and auto-logged-in
      context.go('/home');
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: context.colors.error, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(e.message)),
            ],
          ),
          backgroundColor: context.colors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.md),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error. Check internet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 60),
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Start your learning journey today',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: context.colors.textSecondary),
                ),
                SizedBox(height: AppSpacing.xxxl),

                GlassCard(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name
                      Text('Name', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: context.colors.textSecondary)),
                      SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _nameController,
                        style: TextStyle(color: context.colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Your name',
                          prefixIcon: Icon(Icons.person_outline, color: context.colors.textTertiary),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      // Email
                      Text('Email', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: context.colors.textSecondary)),
                      SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: context.colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.email_outlined, color: context.colors.textTertiary),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      // Password
                      Text('Password', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: context.colors.textSecondary)),
                      SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: context.colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: '6+ characters',
                          prefixIcon: Icon(Icons.lock_outline, color: context.colors.textTertiary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: context.colors.textTertiary,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxl),
                      GradientButton(
                        label: 'Create Account',
                        onPressed: _isLoading ? null : _handleSignup,
                        isLoading: _isLoading,
                        isExpanded: true,
                        icon: Icons.arrow_forward_rounded,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: context.colors.textSecondary),
                        children: [
                          TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: context.colors.primaryLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0, duration: 500.ms);
  }
}
