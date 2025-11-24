import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/models/activity_log.dart';
import 'package:intl/intl.dart';


class ActivityLogList extends StatelessWidget {
  final List<ActivityLog> logs;

  const ActivityLogList({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(child: Text('No activity yet.'));
    }

    final df = DateFormat('yyyy-MM-dd HH:mm');

    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(log.description),
          subtitle: Text(
            '${log.userEmail ?? 'System'} • ${df.format(log.createdAt)}',
          ),
        );
      },
    );
  }
}
