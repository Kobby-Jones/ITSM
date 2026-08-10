// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/ticket.dart';
import '../../../models/user_role.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tickets_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';
import '../../tickets/widgets/priority_badge.dart';
import '../../tickets/widgets/ticket_status_chip.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const EmptyState(
        icon: Icons.person_off_rounded,
        title: 'Not signed in',
        message: 'Please sign in to view your profile.',
      );
    }
    final tickets = ref.watch(ticketsProvider);

    final isTechOrAdmin = user.role == UserRole.technician ||
        user.role == UserRole.admin ||
        user.role == UserRole.manager;

    final relevant = isTechOrAdmin
        ? tickets.where((t) => t.assigneeName == user.name).toList()
        : tickets.where((t) => t.reporterName == user.name).toList();

    final activeCount = relevant
        .where((t) => t.status != TicketStatus.resolved && t.status != TicketStatus.closed)
        .length;
    final resolvedCount = relevant
        .where((t) => t.status == TicketStatus.resolved || t.status == TicketStatus.closed)
        .length;
    final breachedCount = relevant.where((t) => t.slaBreached).length;

    final isDesktop = Responsive.isDesktop(context);

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Profile',
                subtitle: 'Your account details, role, and recent activity.',
                trailing: OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.settings),
                  icon: const Icon(Icons.settings_rounded, size: 16),
                  label: const Text('Settings'),
                ),
              ),
              const SizedBox(height: 24),
              _Header(
                name: user.name,
                email: user.email,
                role: user.role.label,
                initials: user.initials,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _statTile(context,
                      isTechOrAdmin ? 'Active assignments' : 'Open tickets',
                      '$activeCount', AppColors.statusInProgress, Icons.assignment_ind_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _statTile(context,
                      isTechOrAdmin ? 'Resolved' : 'Closed',
                      '$resolvedCount', AppColors.success, Icons.check_circle_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _statTile(context, 'SLA breached', '$breachedCount',
                      breachedCount == 0 ? AppColors.success : AppColors.danger,
                      Icons.warning_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _statTile(context, 'Total tickets', '${relevant.length}',
                      AppColors.primary, Icons.inventory_2_rounded)),
                ],
              ),
              const SizedBox(height: 20),
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: _DetailsCard(
                          email: user.email,
                          department: user.department,
                          location: user.location,
                          role: user.role.label,
                        )),
                        const SizedBox(width: 16),
                        Expanded(flex: 6, child: _RecentTicketsCard(
                          tickets: relevant,
                          isTechOrAdmin: isTechOrAdmin,
                        )),
                      ],
                    )
                  : Column(
                      children: [
                        _DetailsCard(
                          email: user.email,
                          department: user.department,
                          location: user.location,
                          role: user.role.label,
                        ),
                        const SizedBox(height: 16),
                        _RecentTicketsCard(
                          tickets: relevant,
                          isTechOrAdmin: isTechOrAdmin,
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile(BuildContext context, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name, email, role, initials;
  const _Header({
    required this.name,
    required this.email,
    required this.role,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        children: [
          UserAvatar(initials: initials, size: 80),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: context.colors.onSurface,
                    )),
                const SizedBox(height: 4),
                Text(email,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.onSurface.withOpacity(0.7),
                    )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(role,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.3,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (Responsive.isDesktop(context))
            OutlinedButton.icon(
              onPressed: () => context.showSnack('Edit profile coming soon.'),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit profile'),
            ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final String email, department, location, role;
  const _DetailsCard({
    required this.email,
    required this.department,
    required this.location,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return CardSection(
      title: 'Account details',
      titleIcon: Icons.badge_rounded,
      child: Column(
        children: [
          _detail(context, 'Email', email, Icons.mail_rounded),
          _detail(context, 'Department', department, Icons.apartment_rounded),
          _detail(context, 'Location', location, Icons.place_rounded),
          _detail(context, 'Role', role, Icons.shield_rounded),
          _detail(context, 'Member since', 'Jan 2024', Icons.event_rounded),
          _detail(context, 'Last active', 'Just now', Icons.bolt_rounded),
        ],
      ),
    );
  }

  Widget _detail(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.colors.onSurface.withOpacity(0.5)),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface.withOpacity(0.55),
                )),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _RecentTicketsCard extends StatelessWidget {
  final List<Ticket> tickets;
  final bool isTechOrAdmin;
  const _RecentTicketsCard({required this.tickets, required this.isTechOrAdmin});

  @override
  Widget build(BuildContext context) {
    final sorted = [...tickets]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recent = sorted.take(6).toList();

    return CardSection(
      title: isTechOrAdmin ? 'My assigned tickets' : 'My recent tickets',
      titleIcon: Icons.history_rounded,
      titleTrailing: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: const Size(0, 28),
        ),
        onPressed: () => context.go(AppRoutes.tickets),
        child: const Text('View all'),
      ),
      child: recent.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  isTechOrAdmin
                      ? 'No tickets assigned to you yet.'
                      : 'You haven\'t raised any tickets yet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < recent.length; i++)
                  InkWell(
                    onTap: () => context.go(AppRoutes.ticketDetailFor(recent[i].id)),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        border: i == recent.length - 1
                            ? null
                            : Border(bottom: BorderSide(color: context.colors.outline.withOpacity(0.5))),
                      ),
                      child: Row(
                        children: [
                          PriorityBadge(priority: recent[i].priority, dense: true, showLabel: false),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 80,
                            child: Text(
                              recent[i].code,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                color: context.colors.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(recent[i].title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(
                                  Formatters.relativeTime(recent[i].updatedAt),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: context.colors.onSurface.withOpacity(0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TicketStatusChip(status: recent[i].status, dense: true),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 11, color: context.colors.onSurface.withOpacity(0.4)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
