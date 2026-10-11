import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// 未加入家庭圈时：创建 / 加入
class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  final _name = TextEditingController();
  final _motto = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  int _mode = 0; // 0 加入  1 创建

  Future<void> _submit() async {
    final app = context.read<AppProvider>();
    setState(() => _busy = true);
    try {
      if (_mode == 0) {
        if (_code.text.trim().length != 6) throw Exception('请输入 6 位邀请码');
        await app.joinFamily(_code.text.trim());
      } else {
        if (_name.text.trim().isEmpty) throw Exception('请输入家庭圈名称');
        await app.createFamily(_name.text.trim(), _motto.text.trim().isEmpty ? null : _motto.text.trim());
      }
    } catch (e) {
      if (mounted) showToast(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('加入家庭圈'),
        actions: [TextButton(onPressed: app.logout, child: const Text('退出登录', style: TextStyle(color: AppColors.textSecondary)))],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFFF08A6B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(children: [
                Avatar(url: app.user?.avatarUrl, name: app.user?.nickname ?? '', size: 56, bordered: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('你好，${app.user?.nickname}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('加入或创建一个家庭圈，开始记录家的故事', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: _modeCard(0, Icons.vpn_key_rounded, '加入家庭圈', '输入家人分享的邀请码')),
              const SizedBox(width: 12),
              Expanded(child: _modeCard(1, Icons.add_home_rounded, '创建家庭圈', '成为家庭圈的发起人')),
            ]),
            const SizedBox(height: 28),
            if (_mode == 0) ...[
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(hintText: '6 位邀请码', counterText: ''),
              ),
              const SizedBox(height: 8),
              const Text('体验邀请码：888888（王家大院）', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ] else ...[
              TextField(controller: _name, decoration: const InputDecoration(hintText: '家庭圈名称，如：王家大院', prefixIcon: Icon(Icons.home_outlined))),
              const SizedBox(height: 14),
              TextField(controller: _motto, decoration: const InputDecoration(hintText: '家训 / 一句话（选填）', prefixIcon: Icon(Icons.format_quote_rounded))),
            ],
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_mode == 0 ? '加入' : '创建'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _modeCard(int mode, IconData icon, String title, String sub) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
      ),
    );
  }
}
