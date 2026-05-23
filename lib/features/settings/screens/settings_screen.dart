import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../theme/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _emailAlerts = true;
  bool _pushAlerts = true;
  bool _slaWarnings = true;
  bool _newComments = true;
  bool _digestEmail = false;
  bool _twoFactor = true;
  bool _sessionTimeout = true;
  bool _shareAnalytics = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final themeMode = ref.watch(themeModeProvider);

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Settings',
                subtitle: 'Manage your account, appearance, notifications, and security.',
              ),
              const SizedBox(height: 24),
              if (user != null)
                _ProfileCard(
                  name: user.name,
                  email: user.email,
                  role: user.role.label,
                  initials: user.initials,
                ),
              const SizedBox(height: 16),
              CardSection(
                title: 'Appearance',
                titleIcon: Icons.palette_rounded,
                child: Column(
                  children: [
                    _ThemeOption(
                      label: 'Match system',
                      sub: 'Use the device theme.',
                      icon: Icons.brightness_auto_rounded,
                      selected: themeMode == ThemeMode.system,
                      onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
                    ),
                    _ThemeOption(
                      label: 'Light',
                      sub: 'Always use the light theme.',
                      icon: Icons.light_mode_rounded,
                      selected: themeMode == ThemeMode.light,
                      onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
                    ),
                    _ThemeOption(
                      label: 'Dark',
                      sub: 'Always use the dark theme.',
                      icon: Icons.dark_mode_rounded,
                      selected: themeMode == ThemeMode.dark,
                      onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CardSection(
                title: 'Notifications',
                titleIcon: Icons.notifications_rounded,
                child: Column(
                  children: [
                    _SwitchTile(
                      title: 'Email alerts',
                      subtitle: 'Receive ticket activity by email.',
                      value: _emailAlerts,
                      onChanged: (v) => setState(() => _emailAlerts = v),
                    ),
                    _SwitchTile(
                      title: 'Push notifications',
                      subtitle: 'Real-time alerts on your device.',
                      value: _pushAlerts,
                      onChanged: (v) => setState(() => _pushAlerts = v),
                    ),
                    _SwitchTile(
                      title: 'SLA warnings',
                      subtitle: 'Notify me when an SLA is approaching breach.',
                      value: _slaWarnings,
                      onChanged: (v) => setState(() => _slaWarnings = v),
                    ),
                    _SwitchTile(
                      title: 'New comments',
                      subtitle: 'When someone comments on a ticket assigned to you.',
                      value: _newComments,
                      onChanged: (v) => setState(() => _newComments = v),
                    ),
                    _SwitchTile(
                      title: 'Daily digest',
                      subtitle: 'A 6 AM summary of your queue.',
                      value: _digestEmail,
                      onChanged: (v) => setState(() => _digestEmail = v),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CardSection(
                title: 'Security',
                titleIcon: Icons.shield_rounded,
                child: Column(
                  children: [
                    _SwitchTile(
                      title: 'Two-factor authentication',
                      subtitle: 'Require a code from your authenticator app at sign-in.',
                      value: _twoFactor,
                      onChanged: (v) => setState(() => _twoFactor = v),
                    ),
                    _SwitchTile(
                      title: 'Session timeout',
                      subtitle: 'Sign out automatically after 4 hours of inactivity.',
                      value: _sessionTimeout,
                      onChanged: (v) => setState(() => _sessionTimeout = v),
                    ),
                    _ActionTile(
                      icon: Icons.lock_reset_rounded,
                      title: 'Change password',
                      subtitle: 'Last changed 32 days ago.',
                      onTap: () => context.showSnack('Password change coming soon.'),
                    ),
                    _ActionTile(
                      icon: Icons.devices_rounded,
                      title: 'Active sessions',
                      subtitle: '2 active devices — review and revoke.',
                      onTap: () => context.showSnack('Session management coming soon.'),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CardSection(
                title: 'Privacy',
                titleIcon: Icons.privacy_tip_rounded,
                child: Column(
                  children: [
                    _SwitchTile(
                      title: 'Share usage analytics',
                      subtitle: 'Help us improve by sharing anonymous usage data.',
                      value: _shareAnalytics,
                      onChanged: (v) => setState(() => _shareAnalytics = v),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CardSection(
                title: 'About',
                titleIcon: Icons.info_outline_rounded,
                child: Column(
                  children: [
                    _InfoTile(label: 'Application', value: 'ITSM Framework'),
                    _InfoTile(label: 'Version', value: '1.0.0 (build 142)'),
                    _InfoTile(label: 'Tenant', value: 'Goldfields Ghana Ltd'),
                    _InfoTile(label: 'Powered by', value: 'Deeptech AI'),
                    _ActionTile(
                      icon: Icons.description_rounded,
                      title: 'Terms of Service',
                      onTap: () => context.showSnack('Opening Terms of Service…'),
                    ),
                    _ActionTile(
                      icon: Icons.policy_rounded,
                      title: 'Privacy Policy',
                      onTap: () => context.showSnack('Opening Privacy Policy…'),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CardSection(
                title: 'Account',
                titleIcon: Icons.account_circle_rounded,
                child: Column(
                  children: [
                    _ActionTile(
                      icon: Icons.logout_rounded,
                      title: 'Sign out',
                      subtitle: 'Sign out from this device.',
                      destructive: true,
                      onTap: () {
                        ref.read(authProvider.notifier).logout();
                        context.go(AppRoutes.login);
                      },
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name, email, role, initials;
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.role,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.06),
            AppColors.secondary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        children: [
          UserAvatar(initials: initials, size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(email,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.onSurface.withOpacity(0.65),
                    )),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(role,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.3,
                      )),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.profile),
            icon: const Icon(Icons.person_rounded, size: 16),
            label: const Text('View profile'),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label, sub;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.label,
    required this.sub,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary.withOpacity(0.4) : context.colors.outline,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (selected ? AppColors.primary : context.colors.onSurface)
                    .withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  size: 18,
                  color: selected ? AppColors.primary : context.colors.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Text(sub,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurface.withOpacity(0.6),
                      )),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: context.colors.outline.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurface.withOpacity(0.6),
                    )),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;
  final bool isLast;
  const _ActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.destructive = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : context.colors.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: context.colors.outline.withOpacity(0.5))),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: destructive ? AppColors.danger : context.colors.onSurface.withOpacity(0.65)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13.5, color: color)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurface.withOpacity(0.55),
                        )),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: context.colors.onSurface.withOpacity(0.35)),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface.withOpacity(0.55),
                )),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
