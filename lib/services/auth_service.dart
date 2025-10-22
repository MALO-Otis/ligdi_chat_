import 'dart:convert';
import 'api_client.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';

  final ApiClient api;
  String? _token;
  AppUser? _user;

  AuthService(this.api);

  String? get token => _token;
  AppUser? get currentUser => _user;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty && _user != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    final userJson = prefs.getString(_keyUser);
    if (userJson != null) {
      _user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
    api.setAuthToken(_token);
    if (_token != null && _user == null) {
      try {
        final me = await api.me();
        _user = AppUser.fromJson(me);
        await _persist();
      } catch (_) {}
    }
  }

  Future<void> login({required String username, required String password}) async {
    final res = await api.login(username: username, password: password);
    final token = res['token'] as String?;
    final user = res['user'] as Map<String, dynamic>?;
    if (token == null || user == null) {
      throw Exception('Invalid login response');
    }
    _token = token;
    _user = AppUser.fromJson(user);
    api.setAuthToken(_token);
    await _persist();
  }

  Future<void> register({required String username, required String password, String? displayName}) async {
    final res = await api.register(username: username, password: password, displayName: displayName);
    // If API returns token+user directly, use them; otherwise log in after register.
    final token = res['token'] as String?;
    final user = res['user'] as Map<String, dynamic>?;
    if (token != null && user != null) {
      _token = token;
      _user = AppUser.fromJson(user);
      api.setAuthToken(_token);
      await _persist();
    } else {
      // Try immediate login fallback
      await login(username: username, password: password);
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    api.setAuthToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString(_keyToken, _token!);
    if (_user != null) await prefs.setString(_keyUser, jsonEncode({
      'id': _user!.id,
      'username': _user!.username,
      'displayName': _user!.displayName,
      'avatarUrl': _user!.avatarUrl,
    }));
  }
}
