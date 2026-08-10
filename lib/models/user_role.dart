enum UserRole {
  endUser('End User'),
  technician('IT Technician'),
  admin('IT Administrator'),
  manager('IT Manager');

  final String label;
  const UserRole(this.label);

  /// Maps a backend role name (`Role.name`, e.g. `it_technician`,
  /// `it_admin`, `super_admin`, `it_manager`, `end_user`) to the UI's
  /// 4-tier [UserRole]. Both `it_admin` and `super_admin` collapse to
  /// [admin] since the app doesn't distinguish them in the UI today.
  static UserRole fromApi(String? apiRoleName) {
    switch (apiRoleName) {
      case 'it_technician':
        return UserRole.technician;
      case 'it_admin':
      case 'super_admin':
        return UserRole.admin;
      case 'it_manager':
        return UserRole.manager;
      case 'end_user':
      default:
        return UserRole.endUser;
    }
  }

  static UserRole fromString(String s) =>
      UserRole.values.firstWhere((r) => r.name == s, orElse: () => UserRole.endUser);
}
