import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    this.baseUrl = const String.fromEnvironment(
      'NOVA_API_URL',
      defaultValue: 'https://nova-api-6eie.onrender.com/api/v1',
    ),
  });

  static const _tokenKey = 'nova_access_token';
  final String baseUrl;
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<void> setToken(String value) async {
    token = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, value);
  }

  Future<bool> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_tokenKey);
    if (stored == null || stored.isEmpty) return false;
    token = stored;
    try {
      await getMe();
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        token = null;
        await preferences.remove(_tokenKey);
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> clearSession() async {
    token = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
  }

  Future<Map<String, dynamic>> register({required String username, required String email, required String displayName, required String password}) =>
      _post('/auth/register', {'username': username, 'email': email, 'display_name': displayName, 'password': password});
  Future<Map<String, dynamic>> login({required String login, required String password}) => _post('/auth/login', {'login': login, 'password': password});
  Future<Map<String, dynamic>> getMe() => _getMap('/auth/me');
  Future<Map<String, dynamic>> changePassword({required String currentPassword, required String newPassword}) =>
      _post('/auth/password/change', {'current_password': currentPassword, 'new_password': newPassword});
  Future<Map<String, dynamic>> forgotPassword(String email) => _post('/auth/password/forgot', {'email': email});
  Future<Map<String, dynamic>> resetPassword({required String resetToken, required String newPassword}) =>
      _post('/auth/password/reset', {'token': resetToken, 'new_password': newPassword});

  Future<Map<String, dynamic>> updateMyProfile({required String displayName, required String bio}) =>
      _patch('/users/me', {'display_name': displayName, 'bio': bio});
  Future<Map<String, dynamic>> deleteAccount() => _delete('/users/me');
  Future<Map<String, dynamic>> getProfile(String username) => _getMap('/users/$username');
  Future<Map<String, dynamic>> toggleFollow(String username) => _put('/users/$username/follow', {});
  Future<Map<String, dynamic>> toggleBlock(String username) => _put('/users/$username/block', {});

  Future<List<dynamic>> getFeed() => _getList('/feed');
  Future<Map<String, dynamic>> getExplore() => _getMap('/explore');
  Future<Map<String, dynamic>> search(String query) => _getMap('/search?q=${Uri.encodeQueryComponent(query)}');
  Future<Map<String, dynamic>> createPost(String content, {bool anonymous = false}) =>
      _post('/posts', {'content': content, 'is_anonymous': anonymous});
  Future<Map<String, dynamic>> deletePost(int postId) => _delete('/posts/$postId');
  Future<Map<String, dynamic>> revealAuthor(int postId) => _post('/posts/$postId/reveal', {});
  Future<Map<String, dynamic>> toggleSave(int postId) => _put('/posts/$postId/save', {});
  Future<List<dynamic>> getSavedPosts() => _getList('/users/me/saved');
  Future<Map<String, dynamic>> setReaction(int postId, String reactionType) => _put('/posts/$postId/reaction', {'reaction_type': reactionType});

  Future<List<dynamic>> getComments(int postId) => _getList('/posts/$postId/comments');
  Future<Map<String, dynamic>> createComment(int postId, String content, {int? parentId}) =>
      _post('/posts/$postId/comments', {'content': content, 'parent_id': parentId});
  Future<Map<String, dynamic>> toggleCommentLike(int commentId) => _put('/comments/$commentId/like', {});

  Future<Map<String, dynamic>> getDailyQuestion() => _getMap('/questions/today');
  Future<Map<String, dynamic>> answerDailyQuestion(String content, {bool anonymous = false}) =>
      _post('/questions/today/answer', {'content': content, 'is_anonymous': anonymous});

  Future<List<dynamic>> getNotifications() => _getList('/notifications');
  Future<Map<String, dynamic>> markNotificationRead(int id) => _put('/notifications/$id/read', {});
  Future<Map<String, dynamic>> markAllNotificationsRead() => _put('/notifications/read-all', {});

  Future<Map<String, dynamic>> report({required String targetType, required int targetId, required String reason, String details = ''}) =>
      _post('/reports', {'target_type': targetType, 'target_id': targetId, 'reason': reason, 'details': details});
  Future<Map<String, dynamic>> logEvent(String eventName, {int? postId, Map<String, dynamic> metadata = const {}}) =>
      _post('/analytics/event', {'event_name': eventName, 'post_id': postId, 'metadata': metadata});
  Future<Map<String, dynamic>> getMyAnalytics() => _getMap('/analytics/me');

  Future<Map<String, dynamic>> _getMap(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: _headers).timeout(const Duration(seconds: 20));
    return _decode(response) as Map<String, dynamic>;
  }

  Future<List<dynamic>> _getList(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: _headers).timeout(const Duration(seconds: 20));
    return _decode(response) as List<dynamic>;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final response = await http.put(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _patch(String path, Map<String, dynamic> body) async {
    final response = await http.patch(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
    return _decode(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final response = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers).timeout(const Duration(seconds: 20));
    return _decode(response) as Map<String, dynamic>;
  }

  dynamic _decode(http.Response response) {
    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } catch (_) {
      throw ApiException('Sunucudan geÃ§ersiz bir yanÄ±t geldi.', response.statusCode);
    }
    if (response.statusCode >= 400) throw ApiException(_message(decoded), response.statusCode);
    return decoded;
  }

  String _message(dynamic decoded) {
    if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
      final detail = decoded['detail'];
      if (detail is List && detail.isNotEmpty && detail.first is Map && detail.first['msg'] != null) return detail.first['msg'].toString();
      return detail.toString();
    }
    return 'Bir ÅŸey ters gitti.';
  }
}

