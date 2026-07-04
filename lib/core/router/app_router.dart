import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/views/auth_screen.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/client_inputs/views/client_inputs_screen.dart';
import '../../features/content_studio/views/content_studio_screen.dart';
import '../../features/strategy_hub/views/strategy_hub_screen.dart';
import '../../features/review/views/review_screen.dart';
import '../../shared/widgets/app_shell.dart';

// Route name constants
abstract class AppRoutes {
  static const String auth = '/auth';
  static const String dashboard = '/dashboard';
  static const String clientInputs = '/client/:clientId/inputs';
  static const String clientContent = '/client/:clientId/content';
  static const String clientStrategy = '/client/:clientId/strategy';
  static const String clientReview = '/client/:clientId/review';

  static String clientInputsPath(String clientId) => '/client/$clientId/inputs';
  static String clientContentPath(String clientId) => '/client/$clientId/content';
  static String clientStrategyPath(String clientId) => '/client/$clientId/strategy';
  static String clientReviewPath(String clientId) => '/client/$clientId/review';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.auth,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // Auth guard — always allow /auth, everything else requires session
      // (Real Firebase auth check would happen here)
      return null;
    },
    routes: [
      // ── Auth ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),

      // ── Authenticated Shell (persistent sidebar) ─────────
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          // Dashboard
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const DashboardScreen(),
            ),
          ),

          // Client Inputs Ingestion — Phase 1
          GoRoute(
            path: AppRoutes.clientInputs,
            name: 'client-inputs',
            pageBuilder: (context, state) {
              final clientId = state.pathParameters['clientId']!;
              return _buildPage(
                state: state,
                child: ClientInputsScreen(clientId: clientId),
              );
            },
          ),

          // Content Studio — Phase 3A Split Screen
          GoRoute(
            path: AppRoutes.clientContent,
            name: 'client-content',
            pageBuilder: (context, state) {
              final clientId = state.pathParameters['clientId']!;
              return _buildPage(
                state: state,
                child: ContentStudioScreen(clientId: clientId),
              );
            },
          ),

          // Strategy Hub — Phase 3B SWOT + Calendar
          GoRoute(
            path: AppRoutes.clientStrategy,
            name: 'client-strategy',
            pageBuilder: (context, state) {
              final clientId = state.pathParameters['clientId']!;
              return _buildPage(
                state: state,
                child: StrategyHubScreen(clientId: clientId),
              );
            },
          ),

          // Review & Approval Dashboard — Phase 4
          GoRoute(
            path: AppRoutes.clientReview,
            name: 'client-review',
            pageBuilder: (context, state) {
              final clientId = state.pathParameters['clientId']!;
              return _buildPage(
                state: state,
                child: ReviewScreen(clientId: clientId),
              );
            },
          ),
        ],
      ),
    ],

    // Error page
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
  );
});

/// Fade transition page builder
CustomTransitionPage<void> _buildPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeIn).animate(animation),
        child: child,
      );
    },
  );
}

class _ErrorPage extends StatelessWidget {
  final Exception? error;
  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Page not found', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(error?.toString() ?? '', style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
