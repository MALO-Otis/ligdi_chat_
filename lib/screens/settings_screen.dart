import 'auth_screen.dart';
import '../services/api_client.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  final ApiClient api;
  final AuthService auth;
  const SettingsScreen({super.key, required this.api, required this.auth});

  @override
  Widget build(BuildContext context) {
    final me = auth.currentUser;
    final serverCtrl = TextEditingController(text: api.baseUrl);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 28)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(me?.displayName ?? me?.username ?? '', style: Theme.of(context).textTheme.titleMedium),
                  if (me != null) Text('@${me.username}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Compte', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: serverCtrl,
            decoration: const InputDecoration(labelText: 'Adresse du serveur (ex: http://192.168.1.23:4000)'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () async {
              final base = serverCtrl.text.trim();
              if (base.isEmpty) return;
              await auth.logout();
              final newApi = ApiClient(baseUrl: base);
              final newAuth = AuthService(newApi);
              await newAuth.init();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => AuthScreen(api: newApi, auth: newAuth)),
                  (route) => false,
                );
              }
            },
            child: const Text('Enregistrer & basculer sur ce serveur'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => AuthScreen(api: api, auth: auth)),
                  (route) => false,
                );
              }
            },
            child: const Text('Se déconnecter'),
          ),
          const SizedBox(height: 24),
          const Text('À venir'),
          const SizedBox(height: 8),
          const Text('- Modification du profil (nom, avatar)\n- Téléversement avatar\n- Préférences de notification'),
        ],
      ),
    );
  }
}
