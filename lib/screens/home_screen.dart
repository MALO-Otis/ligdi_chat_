import 'search_screen.dart';
import 'settings_screen.dart';
import '../services/api_client.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final ApiClient api;
  final AuthService auth;
  const HomeScreen({super.key, required this.api, required this.auth});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 1; // default to Search

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _ChatsPlaceholder(),
      SearchScreen(api: widget.api, auth: widget.auth),
      SettingsScreen(api: widget.api, auth: widget.auth),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Ligdi Chat')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Rechercher'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Réglages'),
        ],
      ),
    );
  }
}

class _ChatsPlaceholder extends StatelessWidget {
  const _ChatsPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.chat_bubble_outline, size: 48),
            SizedBox(height: 12),
            Text('Vos conversations apparaitront ici.'),
            SizedBox(height: 4),
            Text('Commencez par rechercher un utilisateur pour discuter.'),
          ],
        ),
      ),
    );
  }
}
