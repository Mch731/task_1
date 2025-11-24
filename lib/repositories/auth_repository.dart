import 'package:flutter_application_1/data/models/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  Stream<AppUser?> authChanges() {
    return _client.auth.onAuthStateChange.map((event) {
      final session = event.session;
      if (session?.user == null) return null;

      final u = session!.user;
      return AppUser(
        id: u.id,
        email: u.email ?? '',
      );
    });
  }

  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email ?? '');
  }

  Future<void> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Login failed');
    }
  }

  Future<void> signUp(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Sign-up failed');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
