import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';

/// Combined Login / Sign Up screen with a tab switcher.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _authSub = AuthService.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        context.go('/home');
      }
    });
  }

  // ignore: cancel_subscriptions
  dynamic _authSub;

  @override
  void dispose() {
    _authSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.xxl),
              // ─── Branding ───
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: context.colors.primaryGradient,
                      borderRadius: AppRadii.lg,
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.primary.withAlpha(80),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('E',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text('Eklavya',
                      style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold, fontSize: 30)),
                  SizedBox(height: AppSpacing.xs),
                  Text('Your AI-powered learning roadmap',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: context.colors.textSecondary)),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.05, end: 0, duration: 500.ms),

              SizedBox(height: AppSpacing.xxl),

              // ─── Tab switcher ───
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.surfaceLight,
                    borderRadius: AppRadii.pill,
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: context.colors.primaryGradient,
                      borderRadius: AppRadii.pill,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    unselectedLabelColor: context.colors.textSecondary,
                    labelColor: Colors.white,
                    tabs: const [
                      Tab(text: 'Sign In'),
                      Tab(text: 'Create Account'),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

              SizedBox(height: AppSpacing.xl),

              // ─── Forms ───
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _LoginForm(onSignedIn: () => context.go('/home')),
                    _SignupForm(onSignedIn: () => context.go('/home')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Login Form ──────────────────────────────────────────────────────────────
class _LoginForm extends StatefulWidget {
  final VoidCallback onSignedIn;
  const _LoginForm({required this.onSignedIn});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _emailError;
  String? _passError;
  String? _globalError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = _emailCtrl.text.trim().isEmpty ? 'Email is required' : null;
      _passError = _passCtrl.text.isEmpty ? 'Password is required' : null;
      _globalError = null;
    });
    return _emailError == null && _passError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.signIn(
          _emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      widget.onSignedIn();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _globalError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _globalError = 'Connection error. Check your internet.';
      });
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Enter your email first');
      return;
    }
    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Password reset email sent — check your inbox.'),
        backgroundColor: context.colors.success,
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _globalError = 'Could not send reset email. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email
          _FieldLabel('Email'),
          SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() => _emailError = null),
            style: TextStyle(color: context.colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.email_outlined,
                  color: context.colors.textTertiary),
              errorText: _emailError,
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Password
          _FieldLabel('Password'),
          SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            onChanged: (_) => setState(() => _passError = null),
            onSubmitted: (_) => _submit(),
            style: TextStyle(color: context.colors.textPrimary),
            decoration: InputDecoration(
              hintText: '••••••',
              prefixIcon: Icon(Icons.lock_outline,
                  color: context.colors.textTertiary),
              errorText: _passError,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: context.colors.textTertiary,
                ),
                onPressed: () =>
                    setState(() => _obscure = !_obscure),
              ),
            ),
          ),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4)),
              child: Text('Forgot password?',
                  style: TextStyle(
                      color: context.colors.primaryLight,
                      fontSize: 13)),
            ),
          ),

          if (_globalError != null) ...[
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.error.withAlpha(20),
                borderRadius: AppRadii.md,
                border: Border.all(
                    color: context.colors.error.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: context.colors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_globalError!,
                          style: TextStyle(
                              color: context.colors.error,
                              fontSize: 13))),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),
          ],

          SizedBox(height: AppSpacing.sm),
          GradientButton(
            label: 'Sign In',
            onPressed: _loading ? null : _submit,
            isLoading: _loading,
            isExpanded: true,
            icon: Icons.arrow_forward_rounded,
          ),
          SizedBox(height: AppSpacing.xl),

          _OrDivider(),
          SizedBox(height: AppSpacing.xl),

          _GoogleButton(onTap: () async {
            setState(() => _loading = true);
            try {
              await AuthService.signInWithGoogle();
            } catch (_) {
              if (!mounted) return;
              setState(() {
                _loading = false;
                _globalError = 'Google sign-in failed. Try again.';
              });
            }
          }),
          SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

// ─── Sign Up Form ─────────────────────────────────────────────────────────────
class _SignupForm extends StatefulWidget {
  final VoidCallback onSignedIn;
  const _SignupForm({required this.onSignedIn});

  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _nameError;
  String? _emailError;
  String? _passError;
  String? _globalError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError =
          _nameCtrl.text.trim().isEmpty ? 'Name is required' : null;
      _emailError =
          _emailCtrl.text.trim().isEmpty ? 'Email is required' : null;
      _passError = _passCtrl.text.length < 6
          ? 'Password must be 6+ characters'
          : null;
      _globalError = null;
    });
    return _nameError == null &&
        _emailError == null &&
        _passError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    try {
      final (_, needsConfirmation) = await AuthService.signUp(
        _emailCtrl.text.trim(),
        _passCtrl.text,
        displayName: _nameCtrl.text.trim(),
      );
      if (!mounted) return;
      if (needsConfirmation) {
        try {
          await AuthService.signIn(
              _emailCtrl.text.trim(), _passCtrl.text);
          if (!mounted) return;
          widget.onSignedIn();
          return;
        } catch (_) {
          if (!mounted) return;
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text(
                'Account created! Check your email to verify, then sign in.'),
            backgroundColor: context.colors.success,
            duration: const Duration(seconds: 5),
          ));
          return;
        }
      }
      widget.onSignedIn();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _globalError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _globalError = 'Connection error. Check your internet.';
      });
    }
  }

  double get _passwordStrength {
    final p = _passCtrl.text;
    if (p.length < 6) return 0.2;
    if (p.length < 8) return 0.4;
    final hasUpper = p.contains(RegExp(r'[A-Z]'));
    final hasNum = p.contains(RegExp(r'[0-9]'));
    final hasSpecial = p.contains(RegExp(r'[^a-zA-Z0-9]'));
    final score = [hasUpper, hasNum, hasSpecial]
        .where((b) => b)
        .length;
    return 0.4 + score * 0.2;
  }

  Color _strengthColor(BuildContext context) {
    final s = _passwordStrength;
    if (s < 0.4) return context.colors.error;
    if (s < 0.7) return context.colors.warning;
    return context.colors.success;
  }

  String _strengthLabel() {
    final s = _passwordStrength;
    if (s < 0.4) return 'Weak';
    if (s < 0.7) return 'Fair';
    if (s < 1.0) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    final hasPassInput = _passCtrl.text.isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name
          _FieldLabel('Name'),
          SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() => _nameError = null),
            style: TextStyle(color: context.colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Your name',
              prefixIcon: Icon(Icons.person_outline,
                  color: context.colors.textTertiary),
              errorText: _nameError,
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Email
          _FieldLabel('Email'),
          SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() => _emailError = null),
            style: TextStyle(color: context.colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.email_outlined,
                  color: context.colors.textTertiary),
              errorText: _emailError,
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Password
          _FieldLabel('Password'),
          SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            onChanged: (_) => setState(() => _passError = null),
            onSubmitted: (_) => _submit(),
            style: TextStyle(color: context.colors.textPrimary),
            decoration: InputDecoration(
              hintText: '6+ characters',
              prefixIcon: Icon(Icons.lock_outline,
                  color: context.colors.textTertiary),
              errorText: _passError,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: context.colors.textTertiary,
                ),
                onPressed: () =>
                    setState(() => _obscure = !_obscure),
              ),
            ),
          ),

          // Password strength bar
          if (hasPassInput) ...[
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppRadii.pill,
                    child: LinearProgressIndicator(
                      value: _passwordStrength,
                      backgroundColor:
                          context.colors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _strengthColor(context)),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_strengthLabel(),
                    style: TextStyle(
                        fontSize: 11,
                        color: _strengthColor(context),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],

          if (_globalError != null) ...[
            SizedBox(height: AppSpacing.md),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.error.withAlpha(20),
                borderRadius: AppRadii.md,
                border: Border.all(
                    color: context.colors.error.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: context.colors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_globalError!,
                          style: TextStyle(
                              color: context.colors.error,
                              fontSize: 13))),
                ],
              ),
            ),
          ],

          SizedBox(height: AppSpacing.lg),
          GradientButton(
            label: 'Create Account',
            onPressed: _loading ? null : _submit,
            isLoading: _loading,
            isExpanded: true,
            icon: Icons.arrow_forward_rounded,
          ),
          SizedBox(height: AppSpacing.xl),

          _OrDivider(),
          SizedBox(height: AppSpacing.xl),

          _GoogleButton(onTap: () async {
            setState(() => _loading = true);
            try {
              await AuthService.signInWithGoogle();
            } catch (_) {
              if (!mounted) return;
              setState(() {
                _loading = false;
                _globalError = 'Google sign-in failed. Try again.';
              });
            }
          }),
          SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: context.colors.textSecondary));
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.colors.glassBorder)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('Or continue with',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.colors.textTertiary)),
        ),
        Expanded(child: Divider(color: context.colors.glassBorder)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

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
            Icon(Icons.g_mobiledata_rounded,
                color: context.colors.textSecondary, size: 28),
            const SizedBox(width: 8),
            Text('Continue with Google',
                style: TextStyle(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
