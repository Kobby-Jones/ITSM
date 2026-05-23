enum UserRole {
  endUser('End User'),
  technician('IT Technician'),
  admin('IT Administrator'),
  manager('IT Manager');

  final String label;
  const UserRole(this.label);

  static UserRole fromString(String s) =>
      UserRole.values.firstWhere((r) => r.name == s, orElse: () => UserRole.endUser);
}
