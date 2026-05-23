import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../theme/app_colors.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  final String subtitle;

  const AuthScaffold({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: isMobile
          ? SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrandMark(size: 44),
                    const SizedBox(height: 40),
                    Text(title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                            )),
                    const SizedBox(height: 32),
                    child,
                  ],
                ),
              ),
            )
          : Row(
              children: [
                // Left brand panel
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -120,
                          top: -120,
                          child: _circle(360, Colors.white.withOpacity(0.06)),
                        ),
                        Positioned(
                          left: -80,
                          bottom: -80,
                          child: _circle(280, Colors.white.withOpacity(0.05)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const BrandMark(size: 44, labelColor: Colors.white),
                              const Spacer(),
                              const Text(
                                'Resolve faster.\nDeliver better.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'A modern, offline-first IT service management platform built for Ghanaian enterprises.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 40),
                              _featureRow(Icons.bolt_rounded, 'Automated routing & SLA tracking'),
                              const SizedBox(height: 14),
                              _featureRow(Icons.cloud_off_rounded, 'Works offline — syncs automatically'),
                              const SizedBox(height: 14),
                              _featureRow(Icons.insights_rounded, 'Real-time analytics & telemetry'),
                              const Spacer(),
                              Text(
                                '© 2026 Goldfields Ghana Ltd. • Powered by Deeptech AI',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Right form panel
                Expanded(
                  flex: 4,
                  child: Center(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(title,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      )),
                              const SizedBox(height: 6),
                              Text(subtitle,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                                      )),
                              const SizedBox(height: 32),
                              child,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _featureRow(IconData icon, String label) => Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}
