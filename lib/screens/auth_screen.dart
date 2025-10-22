import 'home_screen.dart';
import '../theme/app_theme.dart';
import '../services/api_client.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final ApiClient api;
  final AuthService auth;
  const AuthScreen({super.key, required this.api, required this.auth});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _serverCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _displayNameCtrl.dispose();
    _serverCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _serverCtrl.text = widget.api.baseUrl;
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await widget.auth.login(username: _usernameCtrl.text.trim(), password: _passwordCtrl.text);
      } else {
        await widget.auth.register(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _displayNameCtrl.text.trim().isEmpty ? null : _displayNameCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(api: widget.api, auth: widget.auth)),
      );
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ligdi Chat - Auth')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Server URL switcher to avoid rebuilds when testing on device
                TextField(
                  controller: _serverCtrl,
                  decoration: const InputDecoration(labelText: 'Adresse du serveur (ex: http://192.168.1.23:4000)'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton.tonal(
                      onPressed: _loading
                          ? null
                          : () async {
                              final base = _serverCtrl.text.trim();
                              if (base.isEmpty) return;
                              final newApi = ApiClient(baseUrl: base);
                              final newAuth = AuthService(newApi);
                              await newAuth.init();
                              if (!mounted) return;
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => AuthScreen(api: newApi, auth: newAuth),
                                ),
                              );
                            },
                      child: const Text('Enregistrer le serveur'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Astuce: utilisez l\'IP du PC pour un téléphone (ex: 192.168.x.x)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset('assets/images/logo.png', width: 36, height: 36,
                        errorBuilder: (_, __, ___) => const Icon(Icons.bolt, color: AppTheme.brandYellow),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Bienvenue', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(value: true, label: Text('Connexion')),
                    ButtonSegment<bool>(value: false, label: Text('Inscription')),
                  ],
                  selected: {_isLogin},
                  onSelectionChanged: (s) => setState(() => _isLogin = s.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom d\'utilisateur'),
                ),
                const SizedBox(height: 12),
                if (!_isLogin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _displayNameCtrl,
                      decoration: const InputDecoration(labelText: 'Nom affiché (optionnel)'),
                    ),
                  ),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_isLogin ? 'Se connecter' : 'Créer le compte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
