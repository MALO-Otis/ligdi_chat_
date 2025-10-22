import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;


class ApiClient {
  final String baseUrl;
  String? _token;

  ApiClient({required this.baseUrl});

  void setAuthToken(String? token) {
    _token = token;
  }

  Map<String, String> _jsonHeaders({Map<String, String>? extra}) {
    final h = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      h[HttpHeaders.authorizationHeader] = 'Bearer $_token';
    }
    if (extra != null) h.addAll(extra);
    return h;
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register({required String username, required String password, String? displayName}) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/register'),
        headers: _jsonHeaders(),
        body: jsonEncode({'username': username, 'password': password, if (displayName != null) 'displayName': displayName}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw HttpException('Failed to register: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> login({required String username, required String password}) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/login'),
        headers: _jsonHeaders(),
        body: jsonEncode({'username': username, 'password': password}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw HttpException('Failed to login: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> me() async {
    final res = await http.get(Uri.parse('$baseUrl/users/me'), headers: _jsonHeaders());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw HttpException('Failed to load current user: ${res.statusCode} ${res.body}');
  }

  Future<List<dynamic>> searchUsers(String q) async {
    final res = await http.get(Uri.parse('$baseUrl/users/search?q=${Uri.encodeQueryComponent(q)}'), headers: _jsonHeaders());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw HttpException('Failed to search users: ${res.statusCode} ${res.body}');
  }

  // Legacy helper (no longer used once auth is wired). Kept for backward compatibility.
  Future<Map<String, dynamic>> createUser(String username) async {
    final res = await http.post(Uri.parse('$baseUrl/users'), headers: _jsonHeaders(), body: jsonEncode({'username': username}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw HttpException('Failed to create user: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> createConversation(List<String> memberIds) async {
    final res = await http.post(Uri.parse('$baseUrl/conversations'), headers: _jsonHeaders(), body: jsonEncode({'memberIds': memberIds}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw HttpException('Failed to create conversation: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> findOrCreateConversation(List<String> memberIds) async {
    final res = await http.post(Uri.parse('$baseUrl/conversations/find-or-create'), headers: _jsonHeaders(), body: jsonEncode({'memberIds': memberIds}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw HttpException('Failed to find-or-create conversation: ${res.statusCode}');
  }

  Future<List<dynamic>> getMessages(String conversationId) async {
    final res = await http.get(Uri.parse('$baseUrl/conversations/$conversationId/messages'), headers: _jsonHeaders());
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw HttpException('Failed to fetch messages: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> sendTextMessage({required String conversationId, required String senderId, required String text}) async {
    final res = await http.post(Uri.parse('$baseUrl/conversations/$conversationId/messages'), headers: _jsonHeaders(), body: jsonEncode({'senderId': senderId, 'text': text}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw HttpException('Failed to send text message: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> uploadMedia({required String endpoint, required String conversationId, required String senderId, required String filePath, int? durationMs}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final req = http.MultipartRequest('POST', uri)
      ..fields['conversationId'] = conversationId
      ..fields['senderId'] = senderId;
    if (durationMs != null) {
      req.fields['durationMs'] = durationMs.toString();
    }
    req.files.add(await http.MultipartFile.fromPath('file', filePath));
    if (_token != null && _token!.isNotEmpty) {
      req.headers[HttpHeaders.authorizationHeader] = 'Bearer $_token';
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw HttpException('Failed to upload media: ${res.statusCode}');
  }
}
