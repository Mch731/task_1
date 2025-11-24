// lib/data/models/todo_item.dart

class TodoItem {
  final String id;
  final String workspaceId;
  final String title;
  final bool completed;
  final DateTime createdAt;

  TodoItem({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.completed,
    required this.createdAt,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'title': title,
      'completed': completed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Used for optimistic updates in the BLoC.
  TodoItem copyWith({
    String? id,
    String? workspaceId,
    String? title,
    bool? completed,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
