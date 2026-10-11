import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegister = false;
  bool _busy = false;
  bool _obscure = true;
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _nickname = TextEditingController();
  String _role = '家人';

  static const roles = ['爷爷', '奶奶', '外公', '外婆', '爸爸', '妈妈', '儿子', '女儿', '孙子', '孙女', '家人'];

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phone.text.trim();
    final pwd = _password.text;
    if (phone.length < 6) return showToast(context, '请输入正确的手机号', error: true);
    if (pwd.length < 6) return showToast(context, '密码至少 6 位', error: true);
    if (_isRegister && _nickname.text.trim().isEmpty) return showToast(context, '请输入昵称', error: true);

    setState(() => _busy = true);
    final app = context.read<AppProvider>();
    try {
      if (_isRegister) {
        await app.register(phone, pwd, _nickname.text.trim(), _role);
      } else {
        await app.login(phone, pwd);
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _quickLogin(String phone) {
    _phone.text = phone;
    _password.text = '123456';
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 24),
              const Text('家爱相册', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('记录家的温暖 · 珍藏金婚时光', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 40),

              // 切换
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  _tab('登录', !_isRegister, () => setState(() => _isRegister = false)),
                  _tab('注册', _isRegister, () => setState(() => _isRegister = true)),
                ]),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '手机号', prefixIcon: Icon(Icons.phone_android_rounded)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: '密码（至少 6 位）',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              if (_isRegister) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _nickname,
                  decoration: const InputDecoration(hintText: '昵称，如：王建国', prefixIcon: Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 14),
                const Text('我在家里是', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: roles
                      .map((r) => ChoiceChip(
                            label: Text(r),
                            selected: _role == r,
                            onSelected: (_) => setState(() => _role = r),
                            labelStyle: TextStyle(color: _role == r ? Colors.white : AppColors.textPrimary),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isRegister ? '注册并进入' : '登 录'),
              ),

              if (!_isRegister) ...[
                const SizedBox(height: 36),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('体验账号（密码 123456）', style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.8))),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _demo('爷爷 王建国', '13800000001'),
                    _demo('奶奶 李秀兰', '13800000002'),
                    _demo('爸爸 王海', '13800000003'),
                    _demo('孙女 王小雨', '13800000005'),
                  ],
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String text, bool selected, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)] : null,
            ),
            child: Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, color: selected ? AppColors.primary : AppColors.textSecondary)),
          ),
        ),
      );

  Widget _demo(String label, String phone) => ActionChip(
        avatar: const Icon(Icons.person_outline, size: 18, color: AppColors.primary),
        label: Text(label),
        onPressed: _busy ? null : () => _quickLogin(phone),
      );
}
