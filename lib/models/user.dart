import 'user_role.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String department;
  final String position;
  final String phone;
  final UserRole role;
  final String? avatarInitials;
  final String company;
  final String location;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.position,
    required this.phone,
    required this.role,
    this.avatarInitials,
    required this.company,
    required this.location,
  });

  String get initials {
    if (avatarInitials != null) return avatarInitials!;
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
