import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import '../../../core/routing/main_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = Supabase.instance.client.auth;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        _auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? _auth.currentSession;

        if (session != null) {
          return const MainShell();
        }

        return const LoginScreen();
      },
    );
  }
}
