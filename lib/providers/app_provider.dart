import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// 全局状态：登录态 / 用户 / 首页数据 / 适老化模式
class AppProvider extends ChangeNotifier {
  final ApiService api = ApiService();

  User? _user;
  HomeSummary? _home;
  bool _initialized = false;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  HomeSummary? get home => _home;
  bool get isLoggedIn => _user != null;
  bool get initialized => _initialized;
  bool get loading => _loading;
  String? get error => _error;
  bool get elderMode => _user?.elderMode ?? false;
  bool get hasFamily => _home?.family != null;

  static const _kToken = 'auth_token';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    if (token != null) {
      api.setToken(token);
      try {
        _user = await api.me();
        await refreshHome();
      } catch (_) {
        await prefs.remove(_kToken);
        api.setToken(null);
        _user = null;
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveSession(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    api.setToken(token);
    _user = user;
    notifyListeners();
    await refreshHome();
  }

  Future<void> login(String phone, String password) async {
    final (token, user) = await api.login(phone, password);
    await _saveSession(token, user);
  }

  Future<void> register(String phone, String password, String nickname, String roleName) async {
    final (token, user) = await api.register(phone, password, nickname, roleName);
    await _saveSession(token, user);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    api.setToken(null);
    _user = null;
    _home = null;
    notifyListeners();
  }

  Future<void> refreshHome() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _home = await api.home();
      _user = _home!.user;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> toggleElderMode(bool value) async {
    if (_user == null) return;
    _user = _user!.copyWith(elderMode: value);
    notifyListeners();
    try {
      _user = await api.updateMe({'elder_mode': value});
    } catch (_) {}
    notifyListeners();
  }

  Future<void> updateProfile({String? nickname, String? roleName}) async {
    _user = await api.updateMe({
      if (nickname != null) 'nickname': nickname,
      if (roleName != null) 'role_name': roleName,
    });
    notifyListeners();
  }

  Future<void> createFamily(String name, String? motto) async {
    await api.createFamily(name, motto);
    await refreshHome();
  }

  Future<void> joinFamily(String code) async {
    await api.joinFamily(code);
    await refreshHome();
  }
}
