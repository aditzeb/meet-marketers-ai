import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;

    // If user got approved while on this screen, redirect immediately
    if (user != null && !user.isPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.dashboard);
      });
    }

    return Scaffold(
      backgroundColor: ClinicSageColors.neutral,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: ClinicSageColors.surface,
                borderRadius: BorderRadius.circular(ClinicSageRadius.lg),
                border: Border.all(color: ClinicSageColors.border),
                boxShadow: const [
                  BoxShadow(color: Color(0x08000000), blurRadius: 20, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated / Glowing Status Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.hourglass_top_rounded,
                        size: 36,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Account Pending Role Assignment',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ClinicSageColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // User Info Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: ClinicSageColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          user?.displayName ?? 'New Team Member',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ClinicSageColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${user?.email ?? ""}',
                          style: const TextStyle(fontSize: 12, color: ClinicSageColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Body Explanation
                  Text(
                    'Your account has been registered successfully. However, for agency security and client privacy, newly registered accounts cannot access client workspaces or create proposals until an Administrator assigns your role.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ClinicSageColors.secondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Administrator Notice Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(ClinicSageRadius.md),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, size: 20, color: Color(0xFFB45309)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Awaiting Administrator Approval',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please notify your platform administrator (aditya@herbalties.com) to assign your role (Admin or Account Manager) and allocate client project permissions.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade900,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Actions: Refresh Status & Sign Out
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: ClinicSageColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ClinicSageRadius.md)),
                          ),
                          onPressed: () async {
                            await ref.read(authProvider.notifier).signOut();
                            if (context.mounted) {
                              context.go(AppRoutes.auth);
                            }
                          },
                          icon: const Icon(Icons.logout, size: 16, color: ClinicSageColors.secondary),
                          label: const Text('Sign Out', style: TextStyle(color: ClinicSageColors.secondary, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ClinicSageColors.tertiary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ClinicSageRadius.md)),
                          ),
                          onPressed: () async {
                            await ref.read(authProvider.notifier).reloadUser();
                            final reloaded = ref.read(authProvider).user;
                            if (context.mounted) {
                              if (reloaded != null && !reloaded.isPending) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Your account has been approved! Redirecting to dashboard...'),
                                    backgroundColor: ClinicSageColors.tertiary,
                                  ),
                                );
                                context.go(AppRoutes.dashboard);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Account still pending role assignment. Please contact the administrator.'),
                                    backgroundColor: Color(0xFFD97706),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Check Status', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
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
