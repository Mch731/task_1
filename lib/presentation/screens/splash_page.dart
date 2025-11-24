import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/auth/auth_bloc.dart';
import '../../core/app_router.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  void _handleState(BuildContext context, AuthState state) {
    if (state is Authenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.workspaceList,
        (route) => false,
      );
    } else if (state is Unauthenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.signIn,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _handleState,
      child: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
