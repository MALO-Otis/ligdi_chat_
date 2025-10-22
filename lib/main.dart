import 'theme/app_theme.dart';
import 'screens/chat_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ligdi Chat',
      theme: AppTheme.theme(),
      home: const ChatScreen(apiBase: 'http://localhost:4000'),
      debugShowCheckedModeBanner: false,
    );
  }
}
