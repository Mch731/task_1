import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/core/constants.dart';
import 'package:flutter_application_1/data/models/workspace.dart';

class WorkspaceRepository {
  final SupabaseClient _client;

  WorkspaceRepository(this._client);

  /// Load all workspaces where the user is a member (owner/admin/member).
  /// This satisfies: "Users can see only their own workspace".
  Future<List<Workspace>> fetchUserWorkspaces(String userId) async {
    // 1) find workspace_ids from workspace_members
    final memberRows = await _client
        .from(DbTables.workspaceMembers)
        .select('workspace_id')
        .eq('user_id', userId);

    final memberList = memberRows as List;
    if (memberList.isEmpty) {
      return [];
    }

    final workspaceIds = memberList
        .map<String>((row) => row['workspace_id'] as String)
        .toSet() // just in case
        .toList();

    // 2) fetch those workspaces one by one (avoids .in_ version issues)
    final List<Workspace> workspaces = [];

    for (final id in workspaceIds) {
      final data = await _client
          .from(DbTables.workspaces)
          .select()
          .eq('id', id)
          .single();

      workspaces.add(Workspace.fromJson(data));
    }

    return workspaces;
  }

  /// Create a workspace and register creator as owner.
  Future<Workspace> createWorkspace({
    required String name,
    required String ownerId,
  }) async {
    final data = await _client
        .from(DbTables.workspaces)
        .insert({
          'name': name,
          'owner_id': ownerId,
        })
        .select()
        .single();

    final workspace = Workspace.fromJson(data);

    // creator becomes owner in workspace_members
    await _client.from(DbTables.workspaceMembers).insert({
      'workspace_id': workspace.id,
      'user_id': ownerId,
      'role': 'owner',
    });

    return workspace;
  }

  /// Only owner or admin can invite.
  ///
  /// This first checks workspace_members.
  /// If there is no membership row (old data), it falls back to checking
  /// if the user is the workspace.owner_id.
  Future<bool> canInvite(String workspaceId, String userId) async {
    // 1) check membership
    final membership = await _client
        .from(DbTables.workspaceMembers)
        .select('role')
        .eq('workspace_id', workspaceId)
        .eq('user_id', userId)
        .maybeSingle();

    if (membership != null) {
      final role = membership['role'] as String;
      return role == 'owner' || role == 'admin';
    }

    // 2) fallback: check if user is the owner on workspaces table
    final ws = await _client
        .from(DbTables.workspaces)
        .select('owner_id')
        .eq('id', workspaceId)
        .maybeSingle();

    if (ws == null) return false;
    final ownerId = ws['owner_id'] as String?;
    return ownerId == userId;
  }

  /// Invite by userId (user id comes from profiles via UserRepository).
  /// Role is 'member' or 'admin'.
  Future<void> inviteUserByUserId({
    required String workspaceId,
    required String invitedUserId,
    String role = 'member',
  }) async {
    await _client.from(DbTables.workspaceMembers).insert({
      'workspace_id': workspaceId,
      'user_id': invitedUserId,
      'role': role,
    });
  }
}
