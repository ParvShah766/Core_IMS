enum UserRole { inventoryManager, warehouseStaff }

class AppUser {
  const AppUser({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
  });

  final String fullName;
  final String email;
  final String password;
  final UserRole role;
}
