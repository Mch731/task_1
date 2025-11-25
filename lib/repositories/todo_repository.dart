import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/core/constants.dart';
import 'package:flutter_application_1/data/models/todo_item.dart';

class TodoRepository {
  final SupabaseClient _client;

  TodoRepository(this._client);

  /// REAL-TIME: watch todos for a workspace.
  Stream<List<TodoItem>> watchTodos(String workspaceId) {
    return _client
        .from(DbTables.todos)
        .stream(primaryKey: ['id'])
        .eq('workspace_id', workspaceId)
        .order('created_at')
        .map(
          (rows) => rows
              .map(
                (row) => TodoItem.fromJson(row as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Create a todo
  Future<void> addTodo(String workspaceId, String title) async {
    // must be logged in
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Cannot create todo: user is not authenticated');
    }

    await _client.from(DbTables.todos).insert({
      'workspace_id': workspaceId,
      'title': title,
      'created_by': user.id, // 🔴 this fixes the NOT NULL error
    });
  }

  /// Toggle completed
  Future<void> toggleTodo(TodoItem item) async {
    await _client
        .from(DbTables.todos)
        .update({'completed': !item.completed})
        .eq('id', item.id);
  }

  /// Rename todo
  Future<void> renameTodo(String id, String title) async {
    await _client
        .from(DbTables.todos)
        .update({'title': title})
        .eq('id', id);
  }

  /// Delete todo
  Future<void> deleteTodo(String id) async {
    await _client.from(DbTables.todos).delete().eq('id', id);
  }
}
