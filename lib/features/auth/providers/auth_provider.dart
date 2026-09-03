import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
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
    if (FirebaseService.instance.isFirebaseAvailable) {
      try {
        FirebaseAuth.instance.authStateChanges().listen((currentUser) async {
          if (currentUser != null) {
            final am = await FirebaseService.instance.getAccountManager(currentUser.uid);
            state = AuthState(
              user: am ??
                  AccountManagerModel(
                    id: currentUser.uid,
                    displayName: currentUser.displayName ?? currentUser.email?.split('@').first ?? 'Account Manager',
                    email: currentUser.email ?? 'am@agency.com',
                    createdAt: DateTime.now(),
                    lastLoginAt: DateTime.now(),
                    role: (currentUser.email != null && currentUser.email!.toLowerCase().contains('admin')) ? 'admin' : 'accountManager',
                  ),
              isLoading: false,
            );
          } else {
            state = const AuthState(user: null, isLoading: false);
          }
        });
        return;
      } catch (e) {
        debugPrint('Firebase Auth listener error: $e');
      }
    }
    state = const AuthState(user: null, isLoading: false);
  }

  Future<void> reloadUser() async {
    final current = state.user;
    if (current != null) {
      final updated = await FirebaseService.instance.getAccountManager(current.id);
      if (updated != null) {
        state = state.copyWith(user: updated);
      }
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await FirebaseService.instance.signInWithEmail(email, password);
      state = AuthState(user: user, isLoading: false);
      return user != null;
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: cleanMsg);
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
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: cleanMsg);
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
