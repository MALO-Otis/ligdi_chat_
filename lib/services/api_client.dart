import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;


class ApiClient {
  final String baseUrl;
  ApiClient({required this.baseUrl});

  Future<Map<String, dynamic>> createUser(String username) async {
    final res = await http.post(Uri.parse('$baseUrl/users'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode({'username': username}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw HttpException('Failed to create user: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> createConversation(List<String> memberIds) async {
    final res = await http.post(Uri.parse('$baseUrl/conversations'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode({'memberIds': memberIds}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw HttpException('Failed to create conversation: ${res.statusCode}');
  }

  Future<List<dynamic>> getMessages(String conversationId) async {
    final res = await http.get(Uri.parse('$baseUrl/conversations/$conversationId/messages'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw HttpException('Failed to fetch messages: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> sendTextMessage({required String conversationId, required String senderId, required String text}) async {
    final res = await http.post(Uri.parse('$baseUrl/conversations/$conversationId/messages'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode({'senderId': senderId, 'text': text}));
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
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw HttpException('Failed to upload media: ${res.statusCode}');
  }
}
