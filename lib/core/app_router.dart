import 'package:flutter/material.dart';

import '../presentation/screens/splash_page.dart';
import '../presentation/screens/sign_in_page.dart';
import '../presentation/screens/workspace_list_page.dart';
import '../presentation/screens/workspace_detail_page.dart';
import '../data/models/workspace.dart';

class AppRouter {
  static const splash = '/';
  static const signIn = '/sign-in';
  static const workspaceList = '/workspaces';
  static const workspaceDetail = '/workspace-detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case signIn:
        return MaterialPageRoute(builder: (_) => const SignInPage());
      case workspaceList:
        return MaterialPageRoute(builder: (_) => const WorkspaceListPage());
      case workspaceDetail:
        final workspace = settings.arguments as Workspace;
        return MaterialPageRoute(
          builder: (_) => WorkspaceDetailPage(workspace: workspace),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Unknown route')),
          ),
        );
    }
  }
}
