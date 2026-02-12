import 'package:supabase_flutter/supabase_flutter.dart';

class PreparedProfile {
  const PreparedProfile({
    required this.label,
    required this.username,
    required this.email,
    required this.password,
  });

  final String label;
  final String username;
  final String email;
  final String password;
}
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
   static const List<PreparedProfile> preparedProfiles = [
    PreparedProfile(
      label: 'Runner Alpha',
      username: 'runner_alpha',
      email: 'runner.alpha@runmate.app',
      password: 'runner-alpha-2026',
    ),
    PreparedProfile(
      label: 'Runner Beta',
      username: 'runner_beta',
      email: 'runner.beta@runmate.app',
      password: 'runner-beta-2026',
    ),
  ];
  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    if (response.user != null) {
      await _client.from('users').upsert({'id': response.user!.id, 'username': username});
    }
  }

  Future<void> signOut() => _client.auth.signOut();
Future<void> ensurePreparedProfiles() async {
    for (final profile in preparedProfiles) {
      try {
        await signIn(email: profile.email, password: profile.password);
      } on AuthException catch (error) {
        if (!_isInvalidCredentialsError(error)) {
          rethrow;
        }

        await signUp(
          email: profile.email,
          password: profile.password,
          username: profile.username,
        );
      }

      await signOut();
    }
  }

  Future<void> signInPreparedProfile(PreparedProfile profile) {
    return signIn(email: profile.email, password: profile.password);
  }

  bool _isInvalidCredentialsError(AuthException error) {
    final message = error.message.toLowerCase();
    return message.contains('invalid login credentials');
  }
}