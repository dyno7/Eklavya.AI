import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';

/// Login screen with dark glassmorphism styling and dummy auth.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 600));

    if (!mounted) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email == 'admin@gmail.com' && password == '123456') {
      context.go('/onboarding');
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: context.colors.error, size: 20),
              SizedBox(width: 8),
              Text('Invalid credentials. Try admin@gmail.com'),
            ],
          ),
          backgroundColor: context.colors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.md),
        ),
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
                // ─── Header ───
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Sign in to continue your journey',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: context.colors.textSecondary),
                ),
                SizedBox(height: AppSpacing.xxxl),

                // ─── Form card ───
                GlassCard(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email
                      Text(
                        'Email',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: context.colors.textSecondary),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style:
                            TextStyle(color: context.colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'admin@gmail.com',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: context.colors.textTertiary),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),

                      // Password
                      Text(
                        'Password',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: context.colors.textSecondary),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style:
                            TextStyle(color: context.colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: '••••••',
                          prefixIcon: Icon(Icons.lock_outline,
                              color: context.colors.textTertiary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: context.colors.textTertiary,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxl),

                      // Sign In button
                      GradientButton(
                        label: 'Sign In',
                        onPressed: _isLoading ? null : _handleLogin,
                        isLoading: _isLoading,
                        isExpanded: true,
                        icon: Icons.arrow_forward_rounded,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl),

                // ─── Divider ───
                Row(
                  children: [
                    Expanded(child: Divider(color: context.colors.glassBorder)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      child: Text(
                        'Or continue with',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: context.colors.textTertiary),
                      ),
                    ),
                    Expanded(child: Divider(color: context.colors.glassBorder)),
                  ],
                ),
                SizedBox(height: AppSpacing.xl),

                // ─── Social buttons (non-functional) ───
                Row(
                  children: [
                    Expanded(
                      child: _SocialButton(
                        icon: Icons.g_mobiledata_rounded,
                        label: 'Google',
                        onTap: () {},
                      ),
                    ),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: _SocialButton(
                        icon: Icons.apple_rounded,
                        label: 'Apple',
                        onTap: () {},
                      ),
                    ),
                  ],
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.lg,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppRadii.lg,
          border: Border.all(color: context.colors.glassBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.colors.textSecondary, size: 24),
            SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
