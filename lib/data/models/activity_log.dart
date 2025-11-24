import 'package:equatable/equatable.dart';

class ActivityLog extends Equatable {
  final String id;
  final String workspaceId;
  final String description;
  final DateTime createdAt;
  final String? userEmail;

  const ActivityLog({
    required this.id,
    required this.workspaceId,
    required this.description,
    required this.createdAt,
    this.userEmail,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at']),
      userEmail: json['user_email'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, workspaceId, description, createdAt, userEmail];
}
