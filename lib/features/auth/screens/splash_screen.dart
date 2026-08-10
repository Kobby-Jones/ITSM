// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minDelayElapsed = false;

  @override
  void initState() {
    super.initState();
    // Keep a small minimum splash duration for branding, but the actual
    // navigation decision waits on real session restoration below rather
    // than assuming it finished within a fixed timeout.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _minDelayElapsed = true);
      _maybeNavigate();
    });
  }

  void _maybeNavigate() {
    if (!_minDelayElapsed) return;
    final auth = ref.read(authProvider);
    if (auth.restoring) return; // still checking stored token; wait for the listener below
    if (!mounted) return;
    if (auth.isAuthenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, _) => _maybeNavigate());
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 90, showLabel: false)
                  .animate()
                  .scale(begin: const Offset(0.6, 0.6), curve: Curves.elasticOut, duration: 700.ms),
              const SizedBox(height: 28),
              const Text(
                'ITSM Framework',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ).animate(delay: 200.ms).fadeIn().moveY(begin: 8, end: 0),
              const SizedBox(height: 6),
              Text(
                'Context-Aware IT Service Management',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ).animate(delay: 400.ms).fadeIn(),
              const SizedBox(height: 48),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              ).animate(delay: 700.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
