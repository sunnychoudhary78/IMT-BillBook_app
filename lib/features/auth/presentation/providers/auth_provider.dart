import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:solar_erp_app/app/navigator.dart';
import 'package:solar_erp_app/core/providers/global_loading_provider.dart';
import 'package:solar_erp_app/core/providers/network_providers.dart';

import '../../data/auth_api_service.dart';
import '../../data/auth_repository.dart';
import 'auth_state.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.watch(apiServiceProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authApiServiceProvider),
    ref.watch(tokenStorageProvider),
  );
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repo;

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
    return const AuthState();
  }

  Future<void> tryAutoLogin() async {
    final jwt = await _repo.getStoredToken();
    if (jwt == null || jwt.isEmpty) {
      state = const AuthState(isLoading: false, isInitializing: false);
      return;
    }

    try {
      state = state.copyWith(isLoading: true);
      final profile = await _repo.getMe();
      final permissions = await _repo.getPermissions();
      state = state.copyWith(
        isLoading: false,
        isInitializing: false,
        profile: profile,
        permissions: permissions,
      );
    } catch (_) {
      await _repo.logoutLocal();
      state = const AuthState(isLoading: false, isInitializing: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    ref.read(globalLoadingProvider.notifier).showLoading('Signing in...');

    try {
      final result = await _repo.login(email, password);
      final profile = await _repo.getMe();
      final permissions = await _repo.getPermissions();

      state = state.copyWith(
        isLoading: false,
        isInitializing: false,
        authUser: result.user,
        profile: profile,
        permissions: permissions,
      );

      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showMessage(
            'Welcome back, ${profile.name.split(' ').first}',
          );

      navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      state = state.copyWith(isLoading: false, isInitializing: false);
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showApiError(e);
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    ref.read(globalLoadingProvider.notifier).showLoading('Updating password...');
    try {
      await _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showSuccess('Password updated');
    } catch (e) {
      ref.read(globalLoadingProvider.notifier).hide();
      ref.read(globalLoadingProvider.notifier).showApiError(e);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logoutLocal();
    state = const AuthState(isLoading: false, isInitializing: false);
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
    triggerAppRestart();
  }

  void forceLogout() {
    state = const AuthState(isLoading: false, isInitializing: false);
  }
}
