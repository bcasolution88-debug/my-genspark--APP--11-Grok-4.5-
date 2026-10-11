import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editProfile(BuildContext context) async {
    final app = context.read<AppProvider>();
    final nick = TextEditingController(text: app.user?.nickname);
    String role = app.user?.roleName ?? '家人';
    const roles = ['爷爷', '奶奶', '外公', '外婆', '爸爸', '妈妈', '儿子', '女儿', '孙子', '孙女', '家人'];

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('编辑资料', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            TextField(controller: nick, decoration: const InputDecoration(hintText: '昵称')),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles
                  .map((r) => ChoiceChip(
                        label: Text(r),
                        selected: role == r,
                        onSelected: (_) => setS(() => role = r),
                        labelStyle: TextStyle(color: role == r ? Colors.white : AppColors.textPrimary),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 22),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
          ]),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await app.updateProfile(nickname: nick.text.trim(), roleName: role);
      await app.refreshHome();
      if (context.mounted) showToast(context, '资料已更新');
    } catch (e) {
      if (context.mounted) showToast(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final u = app.user!;
    final f = app.home?.family;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // 个人卡片
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFFF08A6B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Row(children: [
                Avatar(url: u.avatarUrl, name: u.nickname, size: 68, bordered: true),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u.nickname, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${u.roleName ?? '家人'} · ${f?.name ?? '未加入家庭圈'}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(u.phone, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ]),
                ),
                IconButton(onPressed: () => _editProfile(context), icon: const Icon(Icons.edit_outlined, color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 20),

            // 适老化模式
            Card(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                secondary: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.text_increase_rounded, color: AppColors.gold),
                ),
                title: const Text('长辈模式', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                subtitle: const Text('更大的字体和按钮，操作更轻松', style: TextStyle(fontSize: 12)),
                value: app.elderMode,
                activeThumbColor: AppColors.primary,
                onChanged: app.toggleElderMode,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(children: [
                _tile(Icons.photo_library_outlined, '我上传的照片', '查看我在家庭相册中的所有上传', () => showToast(context, '功能开发中')),
                const Divider(height: 1, indent: 72),
                _tile(Icons.favorite_outline, '我的祝福', '我送出的金婚祝福', () => showToast(context, '功能开发中')),
                const Divider(height: 1, indent: 72),
                _tile(Icons.notifications_outlined, '消息通知', '家人评论、点赞提醒', () => showToast(context, '功能开发中')),
              ]),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(children: [
                _tile(Icons.help_outline_rounded, '使用帮助', '如何邀请家人、上传照片', () => showToast(context, '功能开发中')),
                const Divider(height: 1, indent: 72),
                _tile(Icons.info_outline_rounded, '关于家爱相册', '版本 1.0.0', () {
                  showAboutDialog(
                    context: context,
                    applicationName: '家爱相册',
                    applicationVersion: '1.0.0',
                    applicationIcon: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/images/app_icon.png', width: 48, height: 48)),
                    children: const [Text('家庭相册及老人金婚分享平台\n记录家的温暖，珍藏金婚时光。')],
                  );
                }),
              ]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('退出登录'),
                    content: const Text('确定要退出当前账号吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('退出', style: TextStyle(color: AppColors.primary))),
                    ],
                  ),
                );
                if (ok == true) app.logout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('退出登录'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String sub, VoidCallback onTap) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      );
}
