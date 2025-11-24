// lib/repositories/storage_repository.dart
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/core/constants.dart';

class StorageRepository {
  final SupabaseClient _client;

  StorageRepository(this._client);

  /// Upload an attachment to the 'attachments' bucket
  /// and record a row in the attachments table.
  Future<void> uploadAttachment({
    required Uint8List bytes,
    required String workspaceId,
    required String todoId,
    required String fileName,
  }) async {
    final storagePath = '$workspaceId/$todoId/$fileName';

    // Upload file to Supabase Storage
    try {
      await _client.storage.from('attachments').uploadBinary(
            storagePath,
            bytes,
          );
    } on StorageException catch (e) {
      throw Exception('Storage upload failed: ${e.message}');
    } catch (e) {
      throw Exception('Unknown storage error: $e');
    }

    // Insert metadata row into attachments table
    try {
      await _client.from(DbTables.attachments).insert({
        'workspace_id': workspaceId,
        'todo_id': todoId,
        'path': storagePath,
      });
    } on PostgrestException catch (e) {
      throw Exception('DB insert failed: ${e.message}');
    } catch (e) {
      throw Exception('Unknown DB error: $e');
    }
  }

  /// Fetch all attachments for a given todo in a workspace.
  Future<List<Map<String, dynamic>>> fetchAttachmentsForTodo({
    required String workspaceId,
    required String todoId,
  }) async {
    final rows = await _client
        .from(DbTables.attachments)
        .select()
        .eq('workspace_id', workspaceId)
        .eq('todo_id', todoId)
        .order('created_at');

    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Extract the file name from a storage path.
  String fileNameFromPath(String path) {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  /// Get a public URL for an attachment path.
  /// Works if your 'attachments' bucket is public.
  String getPublicUrl(String path) {
    return _client.storage.from('attachments').getPublicUrl(path);
  }

  /// Delete an attachment from storage and from the DB table.
  /// Here we delete by 'path'; you can extend this to delete by 'id' too.
  Future<void> deleteAttachment({
    required String path,
  }) async {
    // Remove from storage bucket
    try {
      await _client.storage.from('attachments').remove([path]);
    } on StorageException catch (e) {
      throw Exception('Storage delete failed: ${e.message}');
    } catch (e) {
      throw Exception('Unknown storage delete error: $e');
    }

    // Remove metadata row(s) from DB
    try {
      await _client
          .from(DbTables.attachments)
          .delete()
          .eq('path', path);
    } on PostgrestException catch (e) {
      throw Exception('DB delete failed: ${e.message}');
    } catch (e) {
      throw Exception('Unknown DB delete error: $e');
    }
  }
}
