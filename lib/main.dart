import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_router.dart';
import 'core/env.dart';

import 'logic/auth/auth_bloc.dart';
import 'logic/auth/activity/activity_bloc.dart';
import 'logic/auth/todos/todo_bloc.dart';
import 'logic/auth/workspaces/workspace_bloc.dart';

import 'repositories/activity_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/storage_repository.dart';
import 'repositories/todo_repository.dart';
import 'repositories/workspace_repository.dart';
import 'repositories/user_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  final client = Supabase.instance.client;

  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  final SupabaseClient client;

  const MyApp({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    // Repositories
    final authRepository = AuthRepository(client);
    final workspaceRepository = WorkspaceRepository(client);
    final todoRepository = TodoRepository(client);
    final activityRepository = ActivityRepository(client);
    final storageRepository = StorageRepository(client);
    final userRepository = UserRepository(client); // for invite-by-email

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<WorkspaceRepository>.value(
          value: workspaceRepository,
        ),
        RepositoryProvider<TodoRepository>.value(
          value: todoRepository,
        ),
        RepositoryProvider<ActivityRepository>.value(
          value: activityRepository,
        ),
        RepositoryProvider<StorageRepository>.value(
          value: storageRepository,
        ),
        RepositoryProvider<UserRepository>.value(
          value: userRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(authRepository),
          ),
          BlocProvider<WorkspaceBloc>(
            create: (_) => WorkspaceBloc(workspaceRepository),
          ),
          BlocProvider<TodoBloc>(
            create: (_) => TodoBloc(todoRepository),
          ),
          BlocProvider<ActivityBloc>(
            create: (_) => ActivityBloc(activityRepository),
          ),
        ],
        child: MaterialApp(
          title: 'Shared Workspace',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          onGenerateRoute: AppRouter.onGenerateRoute,
          // Splash listens to AuthBloc and routes accordingly
          initialRoute: AppRouter.splash,
        ),
      ),
    );
  }
}