// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/user.dart';
import '../../../models/user_role.dart';
import '../../../providers/users_admin_provider.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchCtrl = TextEditingController();
  UserRole? _roleFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(usersAdminProvider.notifier).load(search: query.isEmpty ? null : query);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersAdminProvider);
    final isDesktop = Responsive.isDesktop(context);

    var users = state.users;
    if (_roleFilter != null) {
      users = users.where((u) => u.role == _roleFilter).toList();
    }

    return Padding(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'User management',
            subtitle: '${state.total} users across the organization.',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  decoration: const InputDecoration(
                    hintText: 'Search by name, email, or department...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<UserRole?>(
                tooltip: 'Filter by role',
                icon: Badge(
                  isLabelVisible: _roleFilter != null,
                  child: const Icon(Icons.filter_list_rounded),
                ),
                onSelected: (v) => setState(() => _roleFilter = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('All roles')),
                  ...UserRole.values.map((r) =>
                      PopupMenuItem(value: r, child: Text(r.label))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.loadState == UsersLoadState.loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (state.loadState == UsersLoadState.error)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.error ?? 'Failed to load users'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.read(usersAdminProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(usersAdminProvider.notifier).refresh(),
                child: users.isEmpty
                    ? const Center(child: Text('No users found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _UserRow(
                          user: users[i],
                          isLast: i == users.length - 1,
                          desktop: isDesktop,
                          onDeactivate: () async {
                            await ref.read(usersAdminProvider.notifier).deactivateUser(users[i].id);
                            if (context.mounted) context.showSnack('User deactivated.');
                          },
                          onActivate: () async {
                            await ref.read(usersAdminProvider.notifier).activateUser(users[i].id);
                            if (context.mounted) context.showSnack('User activated.');
                          },
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final AppUser user;
  final bool isLast;
  final bool desktop;
  final VoidCallback onDeactivate;
  final VoidCallback onActivate;

  const _UserRow({
    required this.user,
    required this.isLast,
    this.desktop = false,
    required this.onDeactivate,
    required this.onActivate,
  });

  Color _roleColor() {
    switch (user.role) {
      case UserRole.endUser:
        return AppColors.statusInProgress;
      case UserRole.technician:
        return AppColors.info;
      case UserRole.admin:
        return AppColors.warning;
      case UserRole.manager:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = desktop ? Colors.transparent : context.colors.surface;
    final br = desktop
        ? Border(bottom: BorderSide(color: isLast ? Colors.transparent : context.colors.outline))
        : Border.all(color: context.colors.outline);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: desktop ? null : BorderRadius.circular(12),
        border: br,
      ),
      child: Row(
        children: [
          UserAvatar(initials: user.initials, size: 38, showStatus: false),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text(user.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurface.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (desktop) ...[
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(user.department,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                  Text(user.position,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: context.colors.onSurface.withOpacity(0.55))),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(user.location,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.colors.onSurface.withOpacity(0.7),
                  )),
            ),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _roleColor().withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _roleColor().withOpacity(0.3)),
            ),
            child: Text(
              user.role.label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _roleColor()),
            ),
          ),
          const SizedBox(width: 12),
          if (desktop)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 18),
              tooltip: 'Actions',
              onSelected: (v) {
                if (v == 'deactivate') onDeactivate();
                if (v == 'activate') onActivate();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'activate', child: Text('Activate')),
                const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
              ],
            ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
