// ignore_for_file: deprecated_member_use, unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/user_role.dart';
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
  String _query = '';
  UserRole? _roleFilter;

  static const _users = [
    _MockUser('u-001', 'Akosua Mensah', 'akosua.mensah@goldfields.gh', 'Operations', 'Plant Operator', 'Tarkwa Mine', UserRole.endUser, true),
    _MockUser('u-002', 'Kofi Asare', 'kofi.asare@goldfields.gh', 'Plant Maintenance', 'Mechanic', 'Tarkwa Mine', UserRole.endUser, true),
    _MockUser('u-003', 'Ama Boateng', 'ama.boateng@goldfields.gh', 'Finance', 'Senior Accountant', 'Accra HQ', UserRole.endUser, true),
    _MockUser('u-004', 'Yaw Darko', 'yaw.darko@goldfields.gh', 'Geology', 'Senior Geologist', 'Damang Mine', UserRole.endUser, false),
    _MockUser('u-005', 'Adwoa Frimpong', 'adwoa.frimpong@goldfields.gh', 'Human Resources', 'HR Business Partner', 'Accra HQ', UserRole.endUser, true),
    _MockUser('t-001', 'Kwame Boateng', 'kwame.boateng@goldfields.gh', 'IT Operations', 'Senior IT Technician', 'Accra HQ', UserRole.technician, true),
    _MockUser('t-002', 'Yaa Mensah', 'yaa.mensah@goldfields.gh', 'IT Operations', 'IT Technician', 'Accra HQ', UserRole.technician, true),
    _MockUser('t-003', 'Kojo Owusu', 'kojo.owusu@goldfields.gh', 'IT Operations', 'IT Technician', 'Accra HQ', UserRole.technician, false),
    _MockUser('t-004', 'Abena Asante', 'abena.asante@goldfields.gh', 'IT Operations', 'IT Technician', 'Tarkwa Mine', UserRole.technician, true),
    _MockUser('a-001', 'Esi Owusu', 'esi.owusu@goldfields.gh', 'IT Administration', 'IT Administrator', 'Accra HQ', UserRole.admin, true),
    _MockUser('m-001', 'Yaw Asante', 'yaw.asante@goldfields.gh', 'IT Leadership', 'IT Service Manager', 'Accra HQ', UserRole.manager, true),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var users = _users;
    if (_roleFilter != null) users = users.where((u) => u.role == _roleFilter).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      users = users.where((u) =>
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.department.toLowerCase().contains(q)).toList();
    }
    final isDesktop = Responsive.isDesktop(context);

    return Padding(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'User management',
            subtitle: '${_users.length} users across the organization.',
            trailing: FilledButton.icon(
              onPressed: () => context.showSnack('Invite user coming soon.'),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Invite user'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search by name, email, or department…',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.colors.outline),
                  ),
                  child: DropdownButton<UserRole?>(
                    value: _roleFilter,
                    hint: const Text('All roles', style: TextStyle(fontSize: 13)),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    isDense: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All roles')),
                      for (final r in UserRole.values)
                        DropdownMenuItem(value: r, child: Text(r.label)),
                    ],
                    onChanged: (v) => setState(() => _roleFilter = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isDesktop
                ? Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.outline),
                    ),
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (_, i) => _UserRow(user: users[i], isLast: i == users.length - 1, desktop: true)
                          .animate(delay: (i * 18).ms)
                          .fadeIn(duration: 180.ms),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _UserRow(user: users[i], isLast: true),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MockUser {
  final String id, name, email, department, position, location;
  final UserRole role;
  final bool active;
  const _MockUser(this.id, this.name, this.email, this.department, this.position,
      this.location, this.role, this.active);
}

class _UserRow extends StatelessWidget {
  final _MockUser user;
  final bool isLast;
  final bool desktop;
  const _UserRow({required this.user, required this.isLast, this.desktop = false});

  String get _initials {
    final p = user.name.split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return user.name.substring(0, 2).toUpperCase();
  }

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
    final br = desktop ? Border(bottom: BorderSide(color: isLast ? Colors.transparent : context.colors.outline)) : Border.all(color: context.colors.outline);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: desktop ? null : BorderRadius.circular(12),
        border: br,
      ),
      child: Row(
        children: [
          UserAvatar(initials: _initials, size: 38, showStatus: true, online: user.active),
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _roleColor(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (desktop)
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, size: 18),
              tooltip: 'More',
              onPressed: () => context.showSnack('User actions coming soon.'),
            ),
        ],
      ),
    );
  }
}
