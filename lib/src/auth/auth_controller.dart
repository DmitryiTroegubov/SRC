import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

class AuthStateModel {
  const AuthStateModel({
    required this.isLoading,
    required this.user,
    this.errorMessage,
  });

  final bool isLoading;
  final User? user;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  AuthStateModel copyWith({
    bool? isLoading,
    User? user,
    String? errorMessage,
  }) {
    return AuthStateModel(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  factory AuthStateModel.initial(User? user) =>
      AuthStateModel(isLoading: false, user: user);
}

class AuthController extends StateNotifier<AuthStateModel> {
  AuthController(this._service)
      : super(AuthStateModel.initial(_service.currentUser)) {
    _subscription = _service.authStateChanges().listen((event) {
      state = state.copyWith(user: event.session?.user, errorMessage: null);
    });
  }

  final AuthService _service;
  StreamSubscription<AuthState>? _subscription;

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.signIn(email: email, password: password);
      state = state.copyWith(isLoading: false, user: _service.currentUser);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _mapError(e));
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Unexpected login error');
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.signUp(email: email, password: password, username: username);
      state = state.copyWith(isLoading: false, user: _service.currentUser);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _mapError(e));
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Unexpected registration error');
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _service.signOut();
    state = state.copyWith(isLoading: false, user: null);
  }

  String _mapError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Неверный email или пароль';
    }
    if (msg.contains('password should be')) {
      return 'Слабый пароль: минимум 6 символов';
    }
    if (msg.contains('already registered') || msg.contains('already been registered')) {
      return 'Email уже занят';
    }
    return e.message;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthStateModel>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});