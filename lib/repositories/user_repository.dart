import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/core/constants.dart';

class UserRepository {
  final SupabaseClient _client;

  UserRepository(this._client);

  /// Find auth user id by email from `profiles` table.
  Future<String?> findUserIdByEmail(String email) async {
    final data = await _client
        .from(DbTables.users)        // 👈 this now points to 'profiles'
        .select('id')
        .eq('email', email)
        .maybeSingle();

    if (data == null) return null;
    return data['id'] as String?;
  }
}
