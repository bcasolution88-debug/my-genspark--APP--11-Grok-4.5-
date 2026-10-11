import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  List<Member>? _members;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final list = await context.read<AppProvider>().api.members();
      if (mounted) setState(() => _members = list);
    } catch (_) {}
  }

  Future<void> _remove(Member m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移除成员'),
        content: Text('确定将 ${m.nickname} 移出家庭圈吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('移除', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AppProvider>().api.removeMember(m.id);
      _load();
      if (mounted) context.read<AppProvider>().refreshHome();
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    }
  }

  void _showInvite(Family f) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('邀请家人加入', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('让家人在「家爱相册」中输入以下邀请码', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFFF08A6B)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(f.inviteCode, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 12)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '快来加入我们的家庭圈「${f.name}」！打开家爱相册，输入邀请码：${f.inviteCode}'));
                Navigator.pop(ctx);
                showToast(context, '邀请文案已复制，粘贴到微信发送给家人');
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('复制邀请文案'),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final f = app.home?.family;
    final members = _members ?? app.home?.members ?? [];
    final isOwner = f?.ownerId == app.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('家人圈'),
        actions: [if (f != null) IconButton(onPressed: () => _showInvite(f), icon: const Icon(Icons.person_add_alt_1_outlined))],
      ),
      body: SafeArea(
        child: f == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await _load();
                  await app.refreshHome();
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // 家庭卡片
                    Container(
                      height: 170,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(fit: StackFit.expand, children: [
                        NetImage(f.coverUrl),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.7)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                            Text(f.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                            if (f.motto != null) Text('「${f.motto}」', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 10),
                            Row(children: [
                              _chip(Icons.people_outline, '${f.memberCount} 位家人'),
                              const SizedBox(width: 8),
                              _chip(Icons.photo_album_outlined, '${f.albumCount} 本相册'),
                              const SizedBox(width: 8),
                              _chip(Icons.photo_outlined, '${f.photoCount} 张'),
                            ]),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    // 邀请码
                    GestureDetector(
                      onTap: () => _showInvite(f),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('家庭邀请码', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                Text('点击查看并邀请更多家人', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ]),
                            ),
                            Text(f.inviteCode, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 3)),
                          ]),
                        ),
                      ),
                    ),
                    SectionHeader('家庭成员 (${members.length})'),
                    ...members.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: Avatar(url: m.avatarUrl, name: m.nickname, size: 50, bordered: m.userId == app.user?.id),
                              title: Row(children: [
                                Text(m.nickname, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                const SizedBox(width: 8),
                                if (m.isOwner)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(8)),
                                    child: const Text('创建者', style: TextStyle(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.w700)),
                                  ),
                                if (m.userId == app.user?.id)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                                    child: const Text('我', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700)),
                                  ),
                              ]),
                              subtitle: Text('${m.roleName ?? '家人'} · ${fmtDate(m.joinedAt, pattern: 'yyyy年M月')}加入', style: const TextStyle(fontSize: 12)),
                              trailing: isOwner && !m.isOwner
                                  ? IconButton(onPressed: () => _remove(m), icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary))
                                  : null,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
}
