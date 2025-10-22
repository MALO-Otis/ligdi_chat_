import 'chat_page.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../models/conversation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SearchScreen extends StatefulWidget {
  final ApiClient api;
  final AuthService auth;
  const SearchScreen({super.key, required this.api, required this.auth});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryCtrl = TextEditingController();
  List<AppUser> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load initial users (up to 20) with empty query
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _search('');
    });
  }

  Future<void> _search(String q) async {
    setState(() { _loading = true; });
    try {
      final list = await widget.api.searchUsers(q);
      setState(() {
        final meId = widget.auth.currentUser?.id;
        _results = list
            .map((e) => AppUser.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((u) => u.id != meId)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _startChat(AppUser peer) async {
    try {
      final me = widget.auth.currentUser;
      if (me == null) return;
      final convJson = await widget.api.findOrCreateConversation([me.id, peer.id]);
      final conv = Conversation.fromJson(convJson);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatPage(api: widget.api, auth: widget.auth, conversation: conv, peer: peer),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            controller: _queryCtrl,
            decoration: InputDecoration(
              labelText: 'Rechercher des utilisateurs',
              suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () => _search(_queryCtrl.text)),
            ),
            onSubmitted: _search,
          ),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final u = _results[i];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(u.displayName ?? u.username),
                  subtitle: Text('@${u.username}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _startChat(u),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
