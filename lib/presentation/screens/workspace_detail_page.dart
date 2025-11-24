import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_application_1/logic/auth/activity/activity_bloc.dart';
import 'package:flutter_application_1/logic/auth/todos/todo_bloc.dart';

import 'package:flutter_application_1/presentation/screens/widgets/activity_log_list.dart';
import 'package:flutter_application_1/presentation/screens/widgets/todo_item_tile.dart';

import 'package:flutter_application_1/repositories/activity_repository.dart';
import 'package:flutter_application_1/repositories/storage_repository.dart';
import 'package:flutter_application_1/repositories/workspace_repository.dart';
import 'package:flutter_application_1/repositories/user_repository.dart';

import '../../data/models/workspace.dart';
import '../../data/models/todo_item.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../core/widgets/app_loader.dart';
import '../../core/widgets/app_error.dart';

class WorkspaceDetailPage extends StatefulWidget {
  final Workspace workspace;

  const WorkspaceDetailPage({super.key, required this.workspace});

  @override
  State<WorkspaceDetailPage> createState() => _WorkspaceDetailPageState();
}

class _WorkspaceDetailPageState extends State<WorkspaceDetailPage> {
  final _todoController = TextEditingController();
  bool _canInvite = false;
  bool _checkingInvitePermission = true;

  @override
  void initState() {
    super.initState();
    final workspaceId = widget.workspace.id;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Subscribe to todos & activity
      context.read<TodoBloc>().add(
            TodoSubscriptionRequested(workspaceId),
          );

      context.read<ActivityBloc>().add(
            ActivitySubscriptionRequested(workspaceId),
          );

      // Check if current user can invite (owner/admin)
      final auth = context.read<AuthBloc>().state;
      if (auth is Authenticated) {
        final repo = context.read<WorkspaceRepository>();
        final canInvite =
            await repo.canInvite(widget.workspace.id, auth.user.id);
        if (mounted) {
          setState(() {
            _canInvite = canInvite;
            _checkingInvitePermission = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _canInvite = false;
            _checkingInvitePermission = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  String _currentUserEmail(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    if (auth is Authenticated) return auth.user.email;
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final email = _currentUserEmail(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workspace.name),
        actions: [
          if (_checkingInvitePermission)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_canInvite)
            IconButton(
              tooltip: 'Invite member',
              icon: const Icon(Icons.person_add_alt),
              onPressed: _showInviteDialog,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Center(
              child: Text(
                email,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTodosColumn(context),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: _buildActivityColumn(),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(child: _buildTodosColumn(context)),
                const Divider(height: 1),
                SizedBox(
                  height: constraints.maxHeight * 0.4,
                  child: _buildActivityColumn(),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // ----------------- TODOS COLUMN -----------------

  Widget _buildTodosColumn(BuildContext context) {
    return Column(
      children: [
        _buildAddTodoRow(context),
        Expanded(
          child: BlocBuilder<TodoBloc, TodoState>(
            builder: (context, state) {
              if (state is TodoLoading) {
                return const AppLoader(message: 'Loading todos...');
              } else if (state is TodoError) {
                return AppError(state.message);
              } else if (state is TodoLoaded) {
                final todos = state.todos;
                if (todos.isEmpty) {
                  return const Center(child: Text('No todos yet. Add one!'));
                }

                final storageRepo = context.read<StorageRepository>();
                final activityRepo = context.read<ActivityRepository>();

                return ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final item = todos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TodoItemTile(
                              item: item,
                              onToggle: () => _toggleTodo(item),
                              onDelete: () => _deleteTodo(item),
                              onRename: () => _renameTodo(item),
                              onAddAttachment: () => _addAttachment(item),
                            ),
                            // Attachments shown under each todo
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: storageRepo.fetchAttachmentsForTodo(
                                workspaceId: widget.workspace.id,
                                todoId: item.id,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const SizedBox.shrink();
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final attachments = snapshot.data!;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Attachments:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: attachments.map((att) {
                                          final path =
                                              att['path'] as String? ?? '';
                                          final fileName = storageRepo
                                              .fileNameFromPath(path);

                                          return InputChip(
                                            label: Text(
                                              fileName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            avatar: const Icon(
                                              Icons.attach_file,
                                              size: 16,
                                            ),
                                            // Open attachment
                                            onPressed: () async {
                                              final url = storageRepo
                                                  .getPublicUrl(path);
                                              final uri = Uri.parse(url);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(
                                                  uri,
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              } else {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Could not open $fileName',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            // Delete attachment
                                            onDeleted: () async {
                                              try {
                                                await storageRepo
                                                    .deleteAttachment(
                                                  path: path,
                                                );

                                                final email =
                                                    _currentUserEmail(context);

                                                await activityRepo.addLog(
                                                  workspaceId:
                                                      widget.workspace.id,
                                                  description:
                                                      'Deleted attachment "$fileName" from "${item.title}"',
                                                  userEmail: email,
                                                );

                                                if (mounted) {
                                                  setState(() {});
                                                }
                                              } catch (e) {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Failed to delete attachment: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddTodoRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _todoController,
              decoration: const InputDecoration(
                hintText: 'New to-do item',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final text = _todoController.text.trim();
              if (text.isEmpty) return;

              context.read<TodoBloc>().add(
                    TodoAddRequested(
                      workspaceId: widget.workspace.id,
                      title: text,
                    ),
                  );

              final email = _currentUserEmail(context);
              context.read<ActivityRepository>().addLog(
                    workspaceId: widget.workspace.id,
                    description: 'Created todo "$text"',
                    userEmail: email,
                  );

              _todoController.clear();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _toggleTodo(TodoItem item) {
    final email = _currentUserEmail(context);

    context.read<TodoBloc>().add(TodoToggleRequested(item));

    context.read<ActivityRepository>().addLog(
          workspaceId: widget.workspace.id,
          description:
              '${item.completed ? 'Marked incomplete' : 'Marked complete'}: "${item.title}"',
          userEmail: email,
        );
  }

  void _deleteTodo(TodoItem item) {
    final email = _currentUserEmail(context);

    context.read<TodoBloc>().add(TodoDeleteRequested(item.id));

    context.read<ActivityRepository>().addLog(
          workspaceId: widget.workspace.id,
          description: 'Deleted todo "${item.title}"',
          userEmail: email,
        );
  }

  void _renameTodo(TodoItem item) {
    final controller = TextEditingController(text: item.title);
    final email = _currentUserEmail(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename todo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isEmpty) return;

              context.read<TodoBloc>().add(
                    TodoRenameRequested(
                      id: item.id,
                      title: title,
                    ),
                  );

              context.read<ActivityRepository>().addLog(
                    workspaceId: widget.workspace.id,
                    description:
                        'Renamed todo "${item.title}" to "$title"',
                    userEmail: email,
                  );

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAttachment(TodoItem item) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null) return;

    final picked = result.files.single;
    if (picked.bytes == null) return;

    final storageRepo = context.read<StorageRepository>();
    final activityRepo = context.read<ActivityRepository>();
    final email = _currentUserEmail(context);

    try {
      await storageRepo.uploadAttachment(
        bytes: picked.bytes!,
        workspaceId: widget.workspace.id,
        todoId: item.id,
        fileName: picked.name,
      );

      await activityRepo.addLog(
        workspaceId: widget.workspace.id,
        description: 'Attached file "${picked.name}" to "${item.title}"',
        userEmail: email,
      );

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload attachment: $e')),
      );
    }
  }

  // ----------------- ACTIVITY COLUMN -----------------

  Widget _buildActivityColumn() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: BlocBuilder<ActivityBloc, ActivityState>(
            builder: (context, state) {
              if (state is ActivityLoading) {
                return const AppLoader(message: 'Loading activity...');
              } else if (state is ActivityError) {
                return AppError(state.message);
              } else if (state is ActivityLoaded) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ActivityLogList(logs: state.logs),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  // ----------------- INVITE DIALOG -----------------

  void _showInviteDialog() {
    final emailController = TextEditingController();
    String selectedRole = 'member'; // or 'admin'

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Invite member'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: 'User email',
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Role',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                RadioListTile<String>(
                  title: const Text('Member'),
                  value: 'member',
                  groupValue: selectedRole,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedRole = value);
                  },
                  dense: true,
                ),
                RadioListTile<String>(
                  title: const Text('Admin'),
                  value: 'admin',
                  groupValue: selectedRole,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedRole = value);
                  },
                  dense: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) return;

                  final userRepo = context.read<UserRepository>();
                  final workspaceRepo =
                      context.read<WorkspaceRepository>();
                  final activityRepo =
                      context.read<ActivityRepository>();

                  try {
                    final userId = await userRepo.findUserIdByEmail(email);

                    if (userId == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No user found with that email'),
                          ),
                        );
                      }
                      return;
                    }

                    await workspaceRepo.inviteUserByUserId(
                      workspaceId: widget.workspace.id,
                      invitedUserId: userId,
                      role: selectedRole,
                    );

                    final currentEmail = _currentUserEmail(context);
                    await activityRepo.addLog(
                      workspaceId: widget.workspace.id,
                      description:
                          'Invited $email as $selectedRole to the workspace',
                      userEmail: currentEmail,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Invitation sent to $email as $selectedRole',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to invite user: $e')),
                    );
                  }
                },
                child: const Text('Invite'),
              ),
            ],
          );
        },
      ),
    );
  }
}
