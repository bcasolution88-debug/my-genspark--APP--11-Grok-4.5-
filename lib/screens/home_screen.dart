import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'album_detail_screen.dart';
import 'photo_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int) onSwitchTab;
  const HomeScreen({super.key, required this.onSwitchTab});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return '夜深了';
    if (h < 11) return '早上好';
    if (h < 14) return '中午好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final home = app.home;
    final user = app.user!;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: app.refreshHome,
          child: StateView(
            loading: home == null && app.loading,
            error: home == null ? app.error : null,
            onRetry: app.refreshHome,
            child: home == null
                ? const SizedBox()
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      // 顶部
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(children: [
                          Avatar(url: user.avatarUrl, name: user.nickname, size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${_greeting()}，${user.nickname}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                              Text(home.family?.name ?? '家爱相册', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ]),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => onSwitchTab(3),
                            icon: const Icon(Icons.group_outlined),
                            style: IconButton.styleFrom(backgroundColor: Colors.white),
                          ),
                        ]),
                      ),

                      // 家庭成员
                      if (home.members.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 92,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: home.members.length + 1,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (c, i) {
                              if (i == home.members.length) {
                                return GestureDetector(
                                  onTap: () => onSwitchTab(3),
                                  child: Column(children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 1.5, style: BorderStyle.solid)),
                                      child: const Icon(Icons.add, color: AppColors.primary),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text('邀请', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ]),
                                );
                              }
                              final m = home.members[i];
                              return Column(children: [
                                Avatar(url: m.avatarUrl, name: m.nickname, size: 58, bordered: m.userId == user.id),
                                const SizedBox(height: 6),
                                Text(m.roleName ?? m.nickname, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ]);
                            },
                          ),
                        ),
                      ],

                      // 金婚横幅
                      if (home.anniversary != null) ...[
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _AnniversaryBanner(home.anniversary!, onTap: () => onSwitchTab(2)),
                        ),
                      ],

                      // 今日回忆
                      if (home.memoryOfDay != null) ...[
                        const SectionHeader('今日回忆'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _MemoryCard(home.memoryOfDay!),
                        ),
                      ],

                      // 最近相册
                      SectionHeader('最近相册', action: '全部', onAction: () => onSwitchTab(1)),
                      if (home.recentAlbums.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('还没有相册，点右下角 + 创建第一个吧', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.85),
                            itemCount: home.recentAlbums.length > 4 ? 4 : home.recentAlbums.length,
                            itemBuilder: (c, i) => AlbumCard(home.recentAlbums[i]),
                          ),
                        ),

                      // 最新照片
                      if (home.recentPhotos.isNotEmpty) ...[
                        const SectionHeader('最新动态'),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: home.recentPhotos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (c, i) {
                              final p = home.recentPhotos[i];
                              return GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoDetailScreen(photoId: p.id))),
                                child: NetImage(p.thumb, width: 120, height: 120, radius: BorderRadius.circular(16)),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _AnniversaryBanner extends StatelessWidget {
  final Anniversary an;
  final VoidCallback onTap;
  const _AnniversaryBanner(this.an, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [
          NetImage(an.coverUrl),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF8B2E22).withValues(alpha: 0.92), const Color(0xFFC94535).withValues(alpha: 0.55), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(20)),
                child: Text('${an.title} · ${an.yearsTogether}周年', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              Text('${an.husbandName} ❤ ${an.wifeName}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                an.daysUntilCelebration != null && an.daysUntilCelebration! >= 0
                    ? '距庆典还有 ${an.daysUntilCelebration} 天 · ${an.blessingCount} 条祝福'
                    : '携手 ${an.daysTogether} 天 · ${an.blessingCount} 条祝福',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final Photo p;
  const _MemoryCard(this.p);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoDetailScreen(photoId: p.id))),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          NetImage(p.url, height: 200, width: double.infinity),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.auto_awesome, color: AppColors.gold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.caption ?? '一张珍贵的回忆', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${fmtDate(p.takenAt ?? p.createdAt)} · ${p.uploaderName ?? ''} 上传', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// 相册卡片（首页与相册页复用）
class AlbumCard extends StatelessWidget {
  final Album album;
  const AlbumCard(this.album, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlbumDetailScreen(album: album))),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              NetImage(album.coverUrl),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(10)),
                  child: Text(album.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(album.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text('${album.photoCount} 张 · ${fmtDate(album.eventDate ?? album.createdAt, pattern: 'yyyy.M.d')}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ),
        ]),
      ),
    );
  }
}
