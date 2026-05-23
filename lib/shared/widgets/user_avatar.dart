import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final bool showStatus;
  final bool online;
  final List<Color>? gradient;

  const UserAvatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.showStatus = false,
    this.online = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradient ?? const [AppColors.primary, AppColors.secondary];
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.38,
              letterSpacing: 0.3,
            ),
          ),
        ),
        if (showStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: online ? AppColors.success : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
