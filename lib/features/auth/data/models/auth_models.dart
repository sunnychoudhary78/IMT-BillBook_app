class AuthUser {
  final String id;
  final String name;
  final String email;
  final String? roleId;
  final String? roleName;
  final int? hierarchyLevel;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.roleId,
    this.roleName,
    this.hierarchyLevel,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final role = json['Role'] ?? json['role'];
    String? roleName;
    int? hierarchy;
    if (role is Map) {
      roleName = role['name']?.toString();
      hierarchy = role['hierarchy_level'] is num
          ? (role['hierarchy_level'] as num).toInt()
          : null;
    } else if (role is String) {
      roleName = role;
    }

    return AuthUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roleId: (json['roleId'] ?? json['role_id'])?.toString(),
      roleName: roleName,
      hierarchyLevel: hierarchy,
    );
  }
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? roleName;
  final int? hierarchyLevel;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.roleName,
    this.hierarchyLevel,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : json;
    final role = user['Role'] ?? user['role'] ?? json['Role'] ?? json['role'];
    String? roleName;
    int? hierarchy;
    if (role is Map) {
      roleName = role['name']?.toString();
      hierarchy = role['hierarchy_level'] is num
          ? (role['hierarchy_level'] as num).toInt()
          : null;
    } else if (role is String) {
      roleName = role;
    }

    return UserProfile(
      id: (user['id'] ?? json['id'])?.toString() ?? '',
      name: (user['name'] ?? json['name'])?.toString() ?? '',
      email: (user['email'] ?? json['email'])?.toString() ?? '',
      roleName: roleName,
      hierarchyLevel: hierarchy,
    );
  }
}

class LoginResult {
  final String token;
  final AuthUser user;

  const LoginResult({required this.token, required this.user});

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token']?.toString() ?? '',
      user: AuthUser.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? {}),
      ),
    );
  }
}
