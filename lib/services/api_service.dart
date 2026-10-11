import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

/// 后端 REST API 封装
class ApiService {
  /// 默认后端地址：
  /// - 可通过 `--dart-define=API_BASE_URL=https://xxx` 覆盖
  /// - Android 模拟器访问宿主机请用 http://10.0.2.2:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  String? _token;
  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  dynamic _handle(http.Response res) {
    final body = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    String msg = '请求失败 (${res.statusCode})';
    if (body is Map && body['detail'] != null) {
      final d = body['detail'];
      msg = d is String ? d : (d is List && d.isNotEmpty ? (d.first['msg']?.toString() ?? msg) : msg);
    }
    throw ApiException(res.statusCode, msg);
  }

  Future<dynamic> _get(String path, [Map<String, String>? q]) async {
    try {
      return _handle(await http.get(_uri(path, q), headers: _headers).timeout(const Duration(seconds: 20)));
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('GET $path error: $e');
      throw ApiException(0, '网络连接失败，请检查后端服务是否启动');
    }
  }

  Future<dynamic> _post(String path, [Object? body]) async {
    try {
      return _handle(await http
          .post(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body))
          .timeout(const Duration(seconds: 20)));
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('POST $path error: $e');
      throw ApiException(0, '网络连接失败，请检查后端服务是否启动');
    }
  }

  Future<dynamic> _put(String path, Object body) async {
    try {
      return _handle(await http
          .put(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20)));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, '网络连接失败');
    }
  }

  Future<dynamic> _delete(String path) async {
    try {
      return _handle(await http.delete(_uri(path), headers: _headers).timeout(const Duration(seconds: 20)));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, '网络连接失败');
    }
  }

  // ---------- Auth ----------
  Future<(String, User)> login(String phone, String password) async {
    final r = await _post('/api/auth/login', {'phone': phone, 'password': password});
    return (r['access_token'] as String, User.fromJson(r['user']));
  }

  Future<(String, User)> register(String phone, String password, String nickname, String roleName) async {
    final r = await _post('/api/auth/register',
        {'phone': phone, 'password': password, 'nickname': nickname, 'role_name': roleName});
    return (r['access_token'] as String, User.fromJson(r['user']));
  }

  Future<User> me() async => User.fromJson(await _get('/api/auth/me'));

  Future<User> updateMe(Map<String, dynamic> data) async => User.fromJson(await _put('/api/auth/me', data));

  // ---------- Home ----------
  Future<HomeSummary> home() async => HomeSummary.fromJson(await _get('/api/home'));

  // ---------- Family ----------
  Future<Family> createFamily(String name, String? motto) async =>
      Family.fromJson(await _post('/api/family/create', {'name': name, 'motto': motto}));

  Future<Family> joinFamily(String code) async =>
      Family.fromJson(await _post('/api/family/join', {'invite_code': code}));

  Future<Family> myFamily() async => Family.fromJson(await _get('/api/family/mine'));

  Future<List<Member>> members() async =>
      (await _get('/api/family/members') as List).map((m) => Member.fromJson(m)).toList();

  Future<void> removeMember(String memberId) => _delete('/api/family/members/$memberId');

  // ---------- Album ----------
  Future<List<Album>> albums({String? category}) async {
    final r = await _get('/api/albums', category == null ? null : {'category': category});
    return (r as List).map((a) => Album.fromJson(a)).toList();
  }

  Future<Album> createAlbum(String title, String category, String? description) async =>
      Album.fromJson(await _post('/api/albums', {'title': title, 'category': category, 'description': description}));

  Future<void> deleteAlbum(String id) => _delete('/api/albums/$id');

  Future<List<Photo>> photos(String albumId) async =>
      (await _get('/api/albums/$albumId/photos') as List).map((p) => Photo.fromJson(p)).toList();

  Future<Photo> addPhoto(String albumId, String url, String? caption) async =>
      Photo.fromJson(await _post('/api/albums/$albumId/photos', {'url': url, 'caption': caption}));

  Future<Photo> photoDetail(String id) async => Photo.fromJson(await _get('/api/photos/$id'));

  Future<Photo> likePhoto(String id) async => Photo.fromJson(await _post('/api/photos/$id/like'));

  Future<Comment> comment(String photoId, String content) async =>
      Comment.fromJson(await _post('/api/photos/$photoId/comments', {'content': content}));

  Future<void> deletePhoto(String id) => _delete('/api/photos/$id');

  /// 上传文件（multipart），返回可访问 URL
  Future<String> upload(Uint8List bytes, String filename) async {
    final req = http.MultipartRequest('POST', _uri('/api/upload'));
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    return _handle(res)['url'] as String;
  }

  // ---------- Anniversary ----------
  Future<Anniversary> anniversary() async => Anniversary.fromJson(await _get('/api/anniversary'));

  Future<Anniversary> saveAnniversary(Map<String, dynamic> data) async =>
      Anniversary.fromJson(await _post('/api/anniversary', data));

  Future<TimelineEvent> addTimeline(DateTime date, String title, String? desc) async =>
      TimelineEvent.fromJson(await _post('/api/anniversary/timeline',
          {'event_date': date.toIso8601String(), 'title': title, 'description': desc}));

  Future<Blessing> addBlessing({String? content, String? audioUrl, int duration = 0}) async =>
      Blessing.fromJson(await _post('/api/anniversary/blessings',
          {'content': content, 'audio_url': audioUrl, 'audio_duration': duration}));

  Future<Blessing> likeBlessing(String id) async =>
      Blessing.fromJson(await _post('/api/anniversary/blessings/$id/like'));

  // ---------- Share ----------
  Future<ShareLink> share(String type, String id) async =>
      ShareLink.fromJson(await _post('/api/share', {'target_type': type, 'target_id': id}));
}
