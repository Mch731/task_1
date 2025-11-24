import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/core/constants.dart';
import 'package:flutter_application_1/data/models/activity_log.dart';

class ActivityRepository {
  final SupabaseClient _client;

  ActivityRepository(this._client);

  /// 🔴 REAL-TIME: watch activity logs for a workspace
  Stream<List<ActivityLog>> watchActivity(String workspaceId) {
    return _client
        .from(DbTables.activityLogs)
        .stream(primaryKey: ['id'])
        .eq('workspace_id', workspaceId)
        .order('created_at')
        .map(
          (rows) => rows
              .map((row) => ActivityLog.fromJson(row))
              .toList(),
        );
  }

  /// Add one activity log entry
  Future<void> addLog({
    required String workspaceId,
    required String description,
    required String userEmail,
  }) async {
    await _client.from(DbTables.activityLogs).insert({
      'workspace_id': workspaceId,
      'description': description,
      'user_email': userEmail,
    });
  }
}
