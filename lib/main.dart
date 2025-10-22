import 'theme/app_theme.dart';
import 'services/api_client.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const apiBase = 'http://localhost:4000';
    final api = ApiClient(baseUrl: apiBase);
    final auth = AuthService(api);
    return FutureBuilder(
      future: auth.init(),
      builder: (context, snapshot) {
        return MaterialApp(
          title: 'Ligdi Chat',
          theme: AppTheme.theme(),
          home: (auth.isAuthenticated)
              ? HomeScreen(api: api, auth: auth)
              : AuthScreen(api: api, auth: auth),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
