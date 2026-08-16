// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/screens/kb_management_screen.dart';
import '../features/admin/screens/routing_rules_screen.dart';
import '../features/admin/screens/sla_config_screen.dart';
import '../features/admin/screens/user_management_screen.dart';
import '../features/assets/screens/asset_detail_screen.dart';
import '../features/assets/screens/assets_list_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/dashboard/screens/home_dashboard_screen.dart';
import '../features/knowledge_base/screens/kb_article_screen.dart';
import '../features/knowledge_base/screens/kb_browse_screen.dart';
import '../features/manager/screens/analytics_dashboard_screen.dart';
import '../features/manager/screens/kpi_dashboard_screen.dart';
import '../features/manager/screens/reports_screen.dart';
import '../features/manager/screens/sla_compliance_screen.dart';
import '../features/manager/screens/technician_performance_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/sync/screens/sync_queue_screen.dart';
import '../features/technician/screens/sla_monitor_screen.dart';
import '../features/technician/screens/ticket_resolution_screen.dart';
import '../features/telemetry/screens/telemetry_analysis_screen.dart';
import '../features/tickets/screens/submit_ticket_screen.dart';
import '../features/tickets/screens/ticket_detail_screen.dart';
import '../features/tickets/screens/tickets_list_screen.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../shared/widgets/adaptive_shell.dart';
import '../shared/widgets/placeholder_screen.dart';
import 'app_routes.dart';

/// Listenable that triggers GoRouter refresh when auth state changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthListenable(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      const authRoutes = {AppRoutes.login, AppRoutes.register, AppRoutes.forgotPassword};
      final isAuthRoute = authRoutes.contains(loc);
      final isSplash = loc == AppRoutes.splash;

      if (isSplash) return null;

      if (auth.restoring) return AppRoutes.splash;

      if (!auth.isAuthenticated && !isAuthRoute) return AppRoutes.login;
      if (auth.isAuthenticated && isAuthRoute) return AppRoutes.home;

      // ── Role-based route guards ───────────────────────────────
      if (auth.isAuthenticated && auth.user != null) {
        final role = auth.user!.role;

        // Admin-only routes
        const adminRoutes = {
          AppRoutes.userManagement,
          AppRoutes.kbManagement,
          AppRoutes.routingRules,
          AppRoutes.slaConfig,
        };
        if (adminRoutes.contains(loc) &&
            role != UserRole.admin &&
            role != UserRole.manager) {
          return AppRoutes.home;
        }

        // Manager-only routes
        const managerRoutes = {
          AppRoutes.analytics,
          AppRoutes.kpiDashboard,
          AppRoutes.technicianPerformance,
          AppRoutes.slaCompliance,
          AppRoutes.reports,
        };
        if (managerRoutes.contains(loc) &&
            role != UserRole.manager &&
            role != UserRole.admin) {
          return AppRoutes.home;
        }

        // Technician+ routes (technician, admin, manager)
        const techRoutes = {
          AppRoutes.ticketQueue,
          AppRoutes.slaMonitor,
        };
        if (techRoutes.contains(loc) && role == UserRole.endUser) {
          return AppRoutes.home;
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // Authenticated shell
      ShellRoute(
        builder: (context, state, child) =>
            AdaptiveShell(currentLocation: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeDashboardScreen()),

          // Tickets
          GoRoute(
            path: AppRoutes.tickets,
            builder: (_, __) => const TicketsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const SubmitTicketScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    TicketDetailScreen(ticketId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'resolve',
                    builder: (_, state) => TicketResolutionScreen(
                      ticketId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'telemetry',
                    builder: (_, state) => TelemetryAnalysisScreen(
                      ticketId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Knowledge Base
          GoRoute(
            path: AppRoutes.knowledgeBase,
            builder: (_, __) => const KbBrowseScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    KbArticleScreen(articleId: state.pathParameters['id']!),
              ),
            ],
          ),

          // Notifications, Settings, Profile, Search, Sync, Offline
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (_, __) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.syncQueue,
            builder: (_, __) => const SyncQueueScreen(),
          ),
          GoRoute(
            path: AppRoutes.offline,
            builder: (_, __) => const PlaceholderScreen(
              title: 'Offline mode',
              description: 'You are offline. Tickets created here will sync when reconnected.',
              icon: Icons.cloud_off_rounded,
            ),
          ),

          // Technician
          GoRoute(
            path: AppRoutes.ticketQueue,
            builder: (_, __) => const TicketsListScreen(),
          ),
          GoRoute(
            path: AppRoutes.slaMonitor,
            builder: (_, __) => const SlaMonitorScreen(),
          ),

          // Admin
          GoRoute(
            path: AppRoutes.assets,
            builder: (_, __) => const AssetsListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    AssetDetailScreen(assetId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.userManagement,
            builder: (_, __) => const UserManagementScreen(),
          ),
          GoRoute(
            path: AppRoutes.kbManagement,
            builder: (_, __) => const KbManagementScreen(),
          ),
          GoRoute(
            path: AppRoutes.routingRules,
            builder: (_, __) => const RoutingRulesScreen(),
          ),
          GoRoute(
            path: AppRoutes.slaConfig,
            builder: (_, __) => const SlaConfigScreen(),
          ),

          // Manager
          GoRoute(
            path: AppRoutes.analytics,
            builder: (_, __) => const AnalyticsDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.kpiDashboard,
            builder: (_, __) => const KpiDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.technicianPerformance,
            builder: (_, __) => const TechnicianPerformanceScreen(),
          ),
          GoRoute(
            path: AppRoutes.slaCompliance,
            builder: (_, __) => const SlaComplianceScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (_, __) => const ReportsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Page not found', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(state.matchedLocation,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    ),
  );
});
