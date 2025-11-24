import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/models/todo_item.dart';

class TodoItemTile extends StatelessWidget {
  final TodoItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onAddAttachment;

  const TodoItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onRename,
    required this.onAddAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: item.completed,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          decoration:
              item.completed ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: onAddAttachment,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onRename,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
