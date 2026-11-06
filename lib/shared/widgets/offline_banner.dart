// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../theme/app_colors.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityProvider);
    final auth = ref.watch(authProvider);
    final usingOfflineSession = auth.offlineSession;

    if (online && !usingOfflineSession) return const SizedBox.shrink();

    final message = usingOfflineSession
        ? 'Offline session active. Using your last verified account; cached data remains available and queued changes will sync when the server is reachable.'
        : 'You are offline. Tickets will be queued and synced automatically.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warning.withOpacity(0.95),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (!online || usingOfflineSession)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (!online) {
                  ref.read(connectivityProvider.notifier).setOnline(true);
                }
                if (usingOfflineSession) {
                  await ref.read(authProvider.notifier).revalidateSession();
                }
              },
              child: Text(
                usingOfflineSession ? 'Retry server' : 'Reconnect',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    ).animate().slideY(begin: -1, duration: 250.ms, curve: Curves.easeOut);
  }
}
