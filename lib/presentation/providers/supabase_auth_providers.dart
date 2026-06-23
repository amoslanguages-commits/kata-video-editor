import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nle_editor/domain/services/supabase_auth_service.dart';

enum SupabaseAuthStatus {
  loading,
  authenticated,
  unauthenticated,
}

class SupabaseAuthState {
  final SupabaseAuthStatus status;
  final User? user;
  final String? errorMessage;

  const SupabaseAuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory SupabaseAuthState.loading() => const SupabaseAuthState(status: SupabaseAuthStatus.loading);
  factory SupabaseAuthState.authenticated(User user) => SupabaseAuthState(status: SupabaseAuthStatus.authenticated, user: user);
  factory SupabaseAuthState.unauthenticated({String? error}) => SupabaseAuthState(status: SupabaseAuthStatus.unauthenticated, errorMessage: error);

  bool get isLoading => status == SupabaseAuthStatus.loading;
  bool get isAuthenticated => status == SupabaseAuthStatus.authenticated;
}

final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService();
});

final supabaseUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(supabaseAuthServiceProvider);
  return authService.authStateChanges.map((event) => event.session?.user);
});

final supabaseAuthStateProvider = Provider<SupabaseAuthState>((ref) {
  final userAsync = ref.watch(supabaseUserProvider);
  return userAsync.when(
    data: (user) {
      if (user != null) {
        return SupabaseAuthState.authenticated(user);
      }
      return SupabaseAuthState.unauthenticated();
    },
    loading: () => SupabaseAuthState.loading(),
    error: (err, stack) => SupabaseAuthState.unauthenticated(error: err.toString()),
  );
});
