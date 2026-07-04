import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

/// Phase 0: Account Manager Authentication
/// Split-panel: left brand hero | right sign-in/sign-up form bound to Riverpod AuthNotifier
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignIn = true;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: ClinicSageColors.neutral,
      body: isWide ? _WideLayout(
        leftPanel: _BrandPanel(),
        rightPanel: _FormPanel(
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
          onGoogleSignIn: _onGoogleSignIn,
        ),
      ) : _NarrowLayout(
        formPanel: _FormPanel(
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
          onGoogleSignIn: _onGoogleSignIn,
        ),
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

  void _onGoogleSignIn() async {
    final success = await ref.read(authProvider.notifier).signIn('google.am@agency.com', 'google-auth-pass');
    if (mounted && success) {
      context.go(AppRoutes.dashboard);
    }
  }
}

class _WideLayout extends StatelessWidget {
  final Widget leftPanel;
  final Widget rightPanel;
  const _WideLayout({required this.leftPanel, required this.rightPanel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 5, child: leftPanel),
        Expanded(flex: 4, child: rightPanel),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  final Widget formPanel;
  const _NarrowLayout({required this.formPanel});

  @override
  Widget build(BuildContext context) {
    return formPanel;
  }
}

class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: ClinicSageColors.primary,
      padding: const EdgeInsets.all(64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ClinicSageColors.tertiary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'Meet Marketers AI',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const Spacer(),

          Text(
            'Intelligence\nfor Account\nManagers.',
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontSize: 52,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Orchestrate AI-powered marketing deliverables\nacross your entire client portfolio — with full\nhuman control at every step.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.65),
              height: 1.7,
            ),
          ),

          const Spacer(),

          ..._features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: ClinicSageColors.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(f, style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.75),
                )),
              ],
            ),
          )),

          const SizedBox(height: 8),
          Text(
            'Internal platform · Account Managers only',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.35),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  static const _features = [
    'Multi-client workspace management',
    'AI-generated scripts, copy & design briefs',
    'Human-in-the-loop vetting & approval',
    'SWOT analysis & social media calendars',
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
  final VoidCallback onGoogleSignIn;

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
    required this.onGoogleSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: ClinicSageColors.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSignIn ? 'Welcome back.' : 'Create account.',
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSignIn
                        ? 'Sign in to your Account Manager workspace.'
                        : 'Set up your AM portal in seconds.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 36),

                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF8B4B4)),
                      ),
                      child: Text(errorMessage!, style: const TextStyle(color: Color(0xFF9B1C1C), fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot password?'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onSubmit,
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isSignIn ? 'Sign In' : 'Create Account'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or', style: theme.textTheme.bodySmall),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : onGoogleSignIn,
                      icon: const Icon(Icons.account_circle, size: 20, color: ClinicSageColors.tertiary),
                      label: const Text('Continue as Account Manager'),
                    ),
                  ),

                  const SizedBox(height: 28),

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
                                  fontWeight: FontWeight.w600,
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
