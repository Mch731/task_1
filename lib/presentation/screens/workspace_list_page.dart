import 'package:flutter/material.dart';
import 'package:flutter_application_1/logic/auth/workspaces/workspace_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/auth/auth_bloc.dart';
import '../../core/widgets/app_loader.dart';
import '../../core/widgets/app_error.dart';
import '../../core/app_router.dart';

class WorkspaceListPage extends StatefulWidget {
  const WorkspaceListPage({super.key});

  @override
  State<WorkspaceListPage> createState() => _WorkspaceListPageState();
}

class _WorkspaceListPageState extends State<WorkspaceListPage> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        context
            .read<WorkspaceBloc>()
            .add(WorkspaceSubscriptionRequested(authState.user.id));
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showCreateWorkspaceDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create workspace'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Workspace name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;

              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                context.read<WorkspaceBloc>().add(
                      WorkspaceCreateRequested(
                        name,
                        authState.user.id,
                      ),
                    );
              }

              _nameController.clear();
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final email =
        authState is Authenticated ? authState.user.email : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Workspaces ($email)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthSignOutRequested());
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.signIn,
                (route) => false,
              );
            },
          )
        ],
      ),
      body: BlocBuilder<WorkspaceBloc, WorkspaceState>(
        builder: (context, state) {
          if (state is WorkspaceLoading) {
            return const AppLoader(message: 'Loading workspaces...');
          } else if (state is WorkspaceError) {
            return AppError(
              state.message,
              onRetry: () {
                final auth = context.read<AuthBloc>().state;
                if (auth is Authenticated) {
                  context
                      .read<WorkspaceBloc>()
                      .add(WorkspaceSubscriptionRequested(auth.user.id));
                }
              },
            );
          } else if (state is WorkspaceLoaded) {
            final workspaces = state.workspaces;
            if (workspaces.isEmpty) {
              return const Center(
                child: Text('No workspaces yet. Create one!'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: workspaces.length,
              itemBuilder: (context, index) {
                final w = workspaces[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: ListTile(
                    title: Text(w.name),
                    subtitle: Text('Owner: ${w.ownerId}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.workspaceDetail,
                        arguments: w,
                      );
                    },
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateWorkspaceDialog,
        icon: const Icon(Icons.add),
        label: const Text('New workspace'),
      ),
    );
  }
}
