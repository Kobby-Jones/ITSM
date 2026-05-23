import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/responsive.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import 'brand_mark.dart';
import 'offline_banner.dart';
import 'sidebar_nav_item.dart';
import 'user_avatar.dart';

class NavDestination {
  final String label;
  final IconData icon;
  final IconData iconActive;
  final String route;
  final int? badge;
  const NavDestination({
    required this.label,
    required this.icon,
    required this.iconActive,
    required this.route,
    this.badge,
  });
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class AdaptiveShell extends ConsumerStatefulWidget {
  final Widget child;
  final String currentLocation;

  const AdaptiveShell({super.key, required this.child, required this.currentLocation});

  @override
  ConsumerState<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends ConsumerState<AdaptiveShell> {
  bool _collapsed = false;

  List<NavDestination> _destinationsFor(UserRole role, int unread) {
    final base = <NavDestination>[
      const NavDestination(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        iconActive: Icons.dashboard_rounded,
        route: AppRoutes.home,
      ),
      const NavDestination(
        label: 'Tickets',
        icon: Icons.confirmation_number_outlined,
        iconActive: Icons.confirmation_number_rounded,
        route: AppRoutes.tickets,
      ),
    ];

    switch (role) {
      case UserRole.endUser:
        return [
          ...base,
          const NavDestination(
            label: 'Knowledge Base',
            icon: Icons.menu_book_outlined,
            iconActive: Icons.menu_book_rounded,
            route: AppRoutes.knowledgeBase,
          ),
          NavDestination(
            label: 'Notifications',
            icon: Icons.notifications_outlined,
            iconActive: Icons.notifications_rounded,
            route: AppRoutes.notifications,
            badge: unread > 0 ? unread : null,
          ),
        ];
      case UserRole.technician:
        return [
          ...base,
          const NavDestination(
            label: 'Queue',
            icon: Icons.list_alt_outlined,
            iconActive: Icons.list_alt_rounded,
            route: AppRoutes.ticketQueue,
          ),
          const NavDestination(
            label: 'SLA Monitor',
            icon: Icons.timer_outlined,
            iconActive: Icons.timer_rounded,
            route: AppRoutes.slaMonitor,
          ),
          const NavDestination(
            label: 'Knowledge Base',
            icon: Icons.menu_book_outlined,
            iconActive: Icons.menu_book_rounded,
            route: AppRoutes.knowledgeBase,
          ),
          NavDestination(
            label: 'Notifications',
            icon: Icons.notifications_outlined,
            iconActive: Icons.notifications_rounded,
            route: AppRoutes.notifications,
            badge: unread > 0 ? unread : null,
          ),
        ];
      case UserRole.admin:
        return [
          ...base,
          const NavDestination(
            label: 'Assets',
            icon: Icons.inventory_2_outlined,
            iconActive: Icons.inventory_2_rounded,
            route: AppRoutes.assets,
          ),
          const NavDestination(
            label: 'Users',
            icon: Icons.group_outlined,
            iconActive: Icons.group_rounded,
            route: AppRoutes.userManagement,
          ),
          const NavDestination(
            label: 'Knowledge Base',
            icon: Icons.menu_book_outlined,
            iconActive: Icons.menu_book_rounded,
            route: AppRoutes.kbManagement,
          ),
          const NavDestination(
            label: 'Routing Rules',
            icon: Icons.route_outlined,
            iconActive: Icons.route_rounded,
            route: AppRoutes.routingRules,
          ),
          const NavDestination(
            label: 'SLA Config',
            icon: Icons.tune_outlined,
            iconActive: Icons.tune_rounded,
            route: AppRoutes.slaConfig,
          ),
        ];
      case UserRole.manager:
        return [
          ...base,
          const NavDestination(
            label: 'Analytics',
            icon: Icons.analytics_outlined,
            iconActive: Icons.analytics_rounded,
            route: AppRoutes.analytics,
          ),
          const NavDestination(
            label: 'KPIs',
            icon: Icons.speed_outlined,
            iconActive: Icons.speed_rounded,
            route: AppRoutes.kpiDashboard,
          ),
          const NavDestination(
            label: 'Technicians',
            icon: Icons.engineering_outlined,
            iconActive: Icons.engineering_rounded,
            route: AppRoutes.technicianPerformance,
          ),
          const NavDestination(
            label: 'SLA Compliance',
            icon: Icons.verified_outlined,
            iconActive: Icons.verified_rounded,
            route: AppRoutes.slaCompliance,
          ),
          const NavDestination(
            label: 'Reports',
            icon: Icons.summarize_outlined,
            iconActive: Icons.summarize_rounded,
            route: AppRoutes.reports,
          ),
        ];
    }
  }

  bool _isSelected(String route) {
    if (route == AppRoutes.home) {
      return widget.currentLocation == AppRoutes.home;
    }
    return widget.currentLocation == route || widget.currentLocation.startsWith('$route/');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    final destinations = _destinationsFor(user.role, ref.watch(unreadNotificationsCountProvider));
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return _buildMobile(context, destinations);
    }
    return _buildDesktop(context, destinations);
  }

  // ---------- DESKTOP ----------
  Widget _buildDesktop(BuildContext context, List<NavDestination> destinations) {
    final scheme = Theme.of(context).colorScheme;
    final width = _collapsed ? 76.0 : 250.0;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): const _SearchIntent(),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): const _SearchIntent(),
        const SingleActivator(LogicalKeyboardKey.slash): const _SearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SearchIntent: CallbackAction<_SearchIntent>(
            onInvoke: (_) {
              context.go(AppRoutes.search);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Column(
              children: [
                const OfflineBanner(),
                Expanded(
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        width: width,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          border: Border(right: BorderSide(color: scheme.outline)),
                        ),
                        child: _buildSidebar(context, destinations),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            _buildTopBar(context),
                            Expanded(child: widget.child),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, List<NavDestination> destinations) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                BrandMark(size: 32, showLabel: !_collapsed),
                const Spacer(),
                if (!_collapsed)
                  IconButton(
                    icon: const Icon(Icons.menu_open_rounded, size: 20),
                    tooltip: 'Collapse sidebar',
                    onPressed: () => setState(() => _collapsed = true),
                  ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: scheme.outline),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: [
              if (!_collapsed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                  child: Text(
                    'WORKSPACE',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                ),
              ...destinations.map((d) => SidebarNavItem(
                    icon: _isSelected(d.route) ? d.iconActive : d.icon,
                    label: d.label,
                    selected: _isSelected(d.route),
                    collapsed: _collapsed,
                    badgeCount: d.badge,
                    onTap: () => context.go(d.route),
                  )),
              const SizedBox(height: 16),
              if (!_collapsed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                  child: Text(
                    'SYSTEM',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                ),
              SidebarNavItem(
                icon: Icons.cloud_sync_outlined,
                label: 'Sync Queue',
                selected: _isSelected(AppRoutes.syncQueue),
                collapsed: _collapsed,
                onTap: () => context.go(AppRoutes.syncQueue),
              ),
              SidebarNavItem(
                icon: Icons.search_rounded,
                label: 'Search',
                selected: _isSelected(AppRoutes.search),
                collapsed: _collapsed,
                onTap: () => context.go(AppRoutes.search),
              ),
              SidebarNavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                selected: _isSelected(AppRoutes.settings),
                collapsed: _collapsed,
                onTap: () => context.go(AppRoutes.settings),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: scheme.outline),
        Padding(
          padding: const EdgeInsets.all(12),
          child: _buildUserCard(context),
        ),
        if (_collapsed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, size: 20),
              tooltip: 'Expand sidebar',
              onPressed: () => setState(() => _collapsed = false),
            ),
          ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    if (_collapsed) {
      return Tooltip(
        message: user.name,
        child: InkWell(
          onTap: () => context.go(AppRoutes.profile),
          borderRadius: BorderRadius.circular(999),
          child: UserAvatar(initials: user.initials, size: 36, showStatus: true),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.go(AppRoutes.profile),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              UserAvatar(initials: user.initials, size: 36, showStatus: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.role.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 18),
                tooltip: 'Sign out',
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go(AppRoutes.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final online = ref.watch(connectivityProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.go(AppRoutes.search),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          size: 18, color: scheme.onSurface.withOpacity(0.55)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search tickets, articles, assets…',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: scheme.outline),
                        ),
                        child: Text(
                          'Ctrl K',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Connectivity indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (online ? AppColors.success : AppColors.warning).withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: (online ? AppColors.success : AppColors.warning).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: online ? AppColors.success : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  online ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: online ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: online ? 'Simulate offline' : 'Simulate online',
            icon: Icon(online ? Icons.cloud_off_rounded : Icons.cloud_rounded, size: 20),
            onPressed: () => ref.read(connectivityProvider.notifier).toggle(),
          ),
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          Builder(builder: (context) {
            final unread = ref.watch(unreadNotificationsCountProvider);
            return IconButton(
              tooltip: unread == 0 ? 'Notifications' : '$unread unread',
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined, size: 22),
                  if (unread > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => context.go(AppRoutes.notifications),
            );
          }),
        ],
      ),
    );
  }

  // ---------- MOBILE ----------
  Widget _buildMobile(BuildContext context, List<NavDestination> destinations) {
    // Show first 4 destinations + a "More" entry on mobile.
    final visible = destinations.take(4).toList();
    final selectedIndex = visible.indexWhere((d) => _isSelected(d.route));
    final user = ref.watch(authProvider).user!;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const BrandMark(size: 32),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go(AppRoutes.search),
          ),
          Builder(builder: (context) {
            final unread = ref.watch(unreadNotificationsCountProvider);
            return IconButton(
              tooltip: unread == 0 ? 'Notifications' : '$unread unread',
              icon: unread > 0
                  ? Badge(
                      label: Text('$unread'),
                      child: const Icon(Icons.notifications_outlined),
                    )
                  : const Icon(Icons.notifications_outlined),
              onPressed: () => context.go(AppRoutes.notifications),
            );
          }),
          PopupMenuButton<String>(
            icon: UserAvatar(initials: user.initials, size: 30),
            onSelected: (v) {
              switch (v) {
                case 'profile':
                  context.go(AppRoutes.profile);
                  break;
                case 'settings':
                  context.go(AppRoutes.settings);
                  break;
                case 'sync':
                  context.go(AppRoutes.syncQueue);
                  break;
                case 'logout':
                  ref.read(authProvider.notifier).logout();
                  context.go(AppRoutes.login);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'sync', child: Text('Sync Queue')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onDestinationSelected: (i) => context.go(visible[i].route),
        destinations: [
          for (final d in visible)
            NavigationDestination(
              icon: d.badge != null && d.badge! > 0
                  ? Badge(label: Text('${d.badge}'), child: Icon(d.icon))
                  : Icon(d.icon),
              selectedIcon: Icon(d.iconActive),
              label: d.label,
            ),
        ],
      ),
      floatingActionButton: user.role == UserRole.endUser
          ? FloatingActionButton.extended(
              onPressed: () => context.go(AppRoutes.submitTicket),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Ticket'),
            )
          : null,
    );
  }
}
