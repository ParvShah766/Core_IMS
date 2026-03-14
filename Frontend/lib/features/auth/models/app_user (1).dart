enum UserRole { inventoryManager, warehouseStaff }

UserRole userRoleFromApi(String value) {
  return UserRole.values.firstWhere(
    (UserRole role) => role.name == value,
    orElse: () => UserRole.inventoryManager,
  );
}

class AppUser {
  const AppUser({
    required this.fullName,
    required this.email,
    required this.role,
    this.id,
    this.password,
  });

  final String? id;
  final String fullName;
  final String email;
  final String? password;
  final UserRole role;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString(),
      fullName: (json['fullName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: userRoleFromApi((json['role'] ?? 'inventoryManager') as String),
    );
  }
}
