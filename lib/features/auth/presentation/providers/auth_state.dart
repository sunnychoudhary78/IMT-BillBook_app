import 'package:solar_erp_app/features/auth/data/models/auth_models.dart';

class AuthState {
  final bool isLoading;
  final bool isInitializing;
  final AuthUser? authUser;
  final UserProfile? profile;
  final List<String> permissions;

  const AuthState({
    this.isLoading = false,
    this.isInitializing = true,
    this.authUser,
    this.profile,
    this.permissions = const [],
  });

  bool get isAuthenticated =>
      profile != null || (authUser != null && !isInitializing);

  bool hasPermission(String permission) => permissions.contains(permission);

  bool hasAny(List<String> perms) =>
      perms.any((p) => permissions.contains(p));

  AuthState copyWith({
    bool? isLoading,
    bool? isInitializing,
    AuthUser? authUser,
    UserProfile? profile,
    List<String>? permissions,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      authUser: clearUser ? null : (authUser ?? this.authUser),
      profile: clearUser ? null : (profile ?? this.profile),
      permissions: clearUser ? const [] : (permissions ?? this.permissions),
    );
  }
}
