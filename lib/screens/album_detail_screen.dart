import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'photo_detail_screen.dart';
import 'upload_photo_screen.dart';

class AlbumDetailScreen extends StatefulWidget {
  final Album album;
  const AlbumDetailScreen({super.key, required this.album});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<Photo> _photos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<AppProvider>().api.photos(widget.album.id);
      if (mounted) setState(() => _photos = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share() async {
    try {
      final link = await context.read<AppProvider>().api.share('album', widget.album.id);
      if (mounted) showShareSheet(context, link.url, widget.album.title);
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除相册'),
        content: Text('确定删除「${widget.album.title}」及其中所有照片吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AppProvider>().api.deleteAlbum(widget.album.id);
      if (!mounted) return;
      context.read<AppProvider>().refreshHome();
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.album;
    final app = context.read<AppProvider>();
    final canDelete = a.createdBy == app.user?.id || app.home?.family?.ownerId == app.user?.id;

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(onPressed: _share, icon: const Icon(Icons.share_outlined)),
            if (canDelete) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700, shadows: [Shadow(blurRadius: 8, color: Colors.black45)])),
            background: Stack(fit: StackFit.expand, children: [
              NetImage(a.coverUrl ?? (_photos.isNotEmpty ? _photos.first.url : null)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.transparent, Colors.black54], begin: Alignment.center, end: Alignment.bottomCenter),
                ),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: Text(a.category, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Text('${_photos.length} 张 · ${a.creatorName ?? ''} 创建 · ${fmtDate(a.eventDate ?? a.createdAt)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
              if (a.description != null && a.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(a.description!, style: const TextStyle(fontSize: 15, height: 1.5)),
              ],
            ]),
          ),
        ),
        if (_loading && _photos.isEmpty)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        else if (_error != null)
          SliverFillRemaining(child: StateView(error: _error, onRetry: _load, child: const SizedBox()))
        else if (_photos.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: StateView(empty: true, emptyText: '还没有照片，点击右下角上传', emptyIcon: Icons.add_photo_alternate_outlined, child: SizedBox()),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6),
              delegate: SliverChildBuilderDelegate(
                (c, i) {
                  final p = _photos[i];
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoDetailScreen(photoId: p.id, photos: _photos, initialIndex: i)));
                      _load();
                    },
                    child: Hero(tag: 'photo_${p.id}', child: NetImage(p.thumb, radius: BorderRadius.circular(12))),
                  );
                },
                childCount: _photos.length,
              ),
            ),
          ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final provider = context.read<AppProvider>();
          final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => UploadPhotoScreen(album: a)));
          if (added == true) {
            _load();
            provider.refreshHome();
          }
        },
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('上传照片'),
      ),
    );
  }
}
