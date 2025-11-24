import 'package:equatable/equatable.dart';

class Attachment extends Equatable {
  final String id;
  final String workspaceId;
  final String todoId;
  final String fileName;
  final String fileUrl;

  const Attachment({
    required this.id,
    required this.workspaceId,
    required this.todoId,
    required this.fileName,
    required this.fileUrl,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'],
      workspaceId: json['workspace_id'],
      todoId: json['todo_id'],
      fileName: json['file_name'],
      fileUrl: json['file_url'],
    );
  }

  @override
  List<Object?> get props => [id, workspaceId, todoId, fileName, fileUrl];
}
