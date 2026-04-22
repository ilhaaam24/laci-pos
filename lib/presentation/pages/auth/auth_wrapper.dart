import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../main_page.dart';
import 'login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        debugPrint('AuthWrapper State: $state');
        if (state is Authenticated) {
          return const MainPage();
        } else if (state is Unauthenticated || state is AuthError) {
          return const LoginPage();
        } else {
          // Splash screen or loading
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
