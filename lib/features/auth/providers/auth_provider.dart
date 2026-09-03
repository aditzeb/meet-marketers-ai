import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/hive_cache_service.dart';
import '../../../data/models/account_manager_model.dart';

class AuthState {
  final AccountManagerModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AccountManagerModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _initAuthListener();
  }

  void _initAuthListener() {
    // Check active Firebase Auth user first if Firebase is available
    if (FirebaseService.instance.isFirebaseAvailable) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final am = AccountManagerModel(
            id: currentUser.uid,
            displayName: currentUser.displayName ?? currentUser.email?.split('@').first ?? 'Account Manager',
            email: currentUser.email ?? 'am@agency.com',
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          state = AuthState(user: am);
          return;
        }
      } catch (e) {
        debugPrint('Firebase Auth listener error: $e');
      }
    }

    // Check Hive cache
    final sessionData = HiveCacheService.instance.getUserSession();
    if (sessionData != null) {
      try {
        final user = AccountManagerModel.fromJson(
          sessionData['id'] as String? ?? 'am-default',
          sessionData,
        );
        state = AuthState(user: user);
        return;
      } catch (_) {}
    }

    // If Firebase is available, sign in anonymously, otherwise use default AM session
    if (FirebaseService.instance.isFirebaseAvailable) {
      signInAnonymously();
    } else {
      state = AuthState(
        user: AccountManagerModel(
          id: 'am-default',
          displayName: 'Account Manager',
          email: 'am@agency.com',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        ),
      );
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await FirebaseService.instance.signInWithEmail(email, password);
      state = AuthState(user: user, isLoading: false);
      return user != null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await FirebaseService.instance.signUpWithEmail(name, email, password);
      state = AuthState(user: user, isLoading: false);
      return user != null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signInAnonymously() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await FirebaseService.instance.signInAnonymously();
      state = AuthState(user: user, isLoading: false);
      return user != null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await FirebaseService.instance.signOut();
    state = const AuthState(user: null, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
