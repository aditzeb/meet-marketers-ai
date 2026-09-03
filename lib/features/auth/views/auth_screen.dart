import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/app_logo.dart';
import '../providers/auth_provider.dart';

/// Phase 0: Account Manager Authentication
/// Split-panel: left brand hero | right sign-in/sign-up form bound to Riverpod AuthNotifier
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with TickerProviderStateMixin {
  bool _isSignIn = true;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.6)),
    );
    _logoController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: ClinicSageColors.neutral,
      body: isWide
          ? Row(
              children: [
                Expanded(flex: 5, child: _BrandPanel(logoController: _logoController, logoScale: _logoScale, logoOpacity: _logoOpacity)),
                Expanded(flex: 4, child: _FormPanel(
                  isSignIn: _isSignIn,
                  isLoading: authState.isLoading,
                  errorMessage: authState.error,
                  obscurePassword: _obscurePassword,
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  nameController: _nameController,
                  onToggleMode: () => setState(() => _isSignIn = !_isSignIn),
                  onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                  onSubmit: _onSubmit,
                )),
              ],
            )
          : _FormPanel(
              isSignIn: _isSignIn,
              isLoading: authState.isLoading,
              errorMessage: authState.error,
              obscurePassword: _obscurePassword,
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              nameController: _nameController,
              onToggleMode: () => setState(() => _isSignIn = !_isSignIn),
              onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
              onSubmit: _onSubmit,
            ),
    );
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    final success = _isSignIn
        ? await ref.read(authProvider.notifier).signIn(email, password)
        : await ref.read(authProvider.notifier).signUp(name.isEmpty ? 'Account Manager' : name, email, password);

    if (mounted && success) {
      context.go(AppRoutes.dashboard);
    }
  }
}

class _BrandPanel extends StatelessWidget {
  final AnimationController logoController;
  final Animation<double> logoScale;
  final Animation<double> logoOpacity;

  const _BrandPanel({
    required this.logoController,
    required this.logoScale,
    required this.logoOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: ClinicSageGradients.brandVibrant,
      ),
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand logo
          ScaleTransition(
            scale: logoScale,
            child: FadeTransition(
              opacity: logoOpacity,
              child: Row(
                children: [
                  const AppLogo(size: 40, showBorder: false),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meet Marketers AI',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Account Manager Platform',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Hero text
          Text(
            'Intelligence\nfor Account\nManagers.',
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontSize: 50,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Orchestrate AI-powered marketing deliverables\nacross your entire client portfolio — with full\nhuman control at every step.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.65),
              height: 1.7,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 40),

          // Feature cards
          ..._features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: ClinicSageColors.tertiary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(f.$2, size: 14, color: ClinicSageColors.tertiaryVibrant),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    f.$1,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.80),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )),

          const Spacer(),

          Text(
            'Internal platform · Account Managers only',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.30),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  static const _features = [
    ('Multi-client workspace management', Icons.people_outline),
    ('AI-generated scripts, copy & design briefs', Icons.auto_awesome),
    ('Human-in-the-loop vetting & approval', Icons.verified_outlined),
    ('SWOT analysis & social media calendars', Icons.insights_outlined),
  ];
}

class _FormPanel extends StatelessWidget {
  final bool isSignIn;
  final bool isLoading;
  final String? errorMessage;
  final bool obscurePassword;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _FormPanel({
    required this.isSignIn,
    required this.isLoading,
    this.errorMessage,
    required this.obscurePassword,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.onToggleMode,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: ClinicSageColors.surface,
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: ClinicSageGradients.tertiarySubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ClinicSageColors.border),
                      ),
                      child: const Icon(Icons.auto_awesome, size: 22, color: ClinicSageColors.tertiary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isSignIn ? 'Welcome back.' : 'Create account.',
                      style: theme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isSignIn
                          ? 'Sign in to your Account Manager workspace.'
                          : 'Set up your AM portal in seconds.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 32),

                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF2F2),
                          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                          border: Border.all(color: const Color(0xFFF8B4B4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 16, color: Color(0xFF9B1C1C)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(errorMessage!, style: const TextStyle(color: Color(0xFF9B1C1C), fontSize: 13))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: isSignIn
                          ? const SizedBox.shrink()
                          : Column(
                              children: [
                                _AuthField(
                                  controller: nameController,
                                  label: 'Full Name',
                                  hint: 'Alex Johnson',
                                  prefixIcon: Icons.person_outline,
                                  validator: (v) => (v?.isEmpty ?? true) ? 'Name required' : null,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                    ),

                    _AuthField(
                      controller: emailController,
                      label: 'Email Address',
                      hint: 'am@agency.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Email required';
                        if (!v!.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _AuthField(
                      controller: passwordController,
                      label: 'Password',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      obscureText: obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                          color: ClinicSageColors.secondary,
                        ),
                        onPressed: onToggleObscure,
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Password required';
                        if (v!.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),

                    if (isSignIn) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 24),

                    // Primary CTA Button with gradient
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                        child: InkWell(
                          onTap: isLoading ? null : onSubmit,
                          borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: isLoading
                                  ? LinearGradient(colors: [ClinicSageColors.tertiary.withOpacity(0.5), ClinicSageColors.tertiary.withOpacity(0.5)])
                                  : ClinicSageGradients.tertiary,
                              borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                              boxShadow: isLoading ? [] : ClinicSageShadows.button,
                            ),
                            child: Center(
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      isSignIn ? 'Sign In' : 'Create Account',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall,
                          children: [
                            TextSpan(text: isSignIn ? "Don't have an account? " : 'Already have an account? '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: onToggleMode,
                                child: Text(
                                  isSignIn ? 'Sign Up' : 'Sign In',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: ClinicSageColors.tertiary,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: ClinicSageColors.tertiary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, size: 18, color: ClinicSageColors.secondary),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
