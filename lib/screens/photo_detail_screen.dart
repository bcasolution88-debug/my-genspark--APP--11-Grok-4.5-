import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class PhotoDetailScreen extends StatefulWidget {
  final String photoId;
  final List<Photo>? photos;
  final int initialIndex;
  const PhotoDetailScreen({super.key, required this.photoId, this.photos, this.initialIndex = 0});

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late PageController _page;
  late int _index;
  Photo? _photo;
  bool _loading = true;
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _page = PageController(initialPage: _index);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(_currentId));
  }

  String get _currentId => widget.photos != null ? widget.photos![_index].id : widget.photoId;

  Future<void> _load(String id) async {
    setState(() => _loading = true);
    try {
      final p = await context.read<AppProvider>().api.photoDetail(id);
      if (mounted) setState(() => _photo = p);
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _like() async {
    if (_photo == null) return;
    try {
      final p = await context.read<AppProvider>().api.likePhoto(_photo!.id);
      if (mounted) setState(() => _photo = p);
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty || _photo == null) return;
    setState(() => _sending = true);
    try {
      await context.read<AppProvider>().api.comment(_photo!.id, text);
      _comment.clear();
      await _load(_photo!.id);
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _share() async {
    if (_photo == null) return;
    try {
      final link = await context.read<AppProvider>().api.share('photo', _photo!.id);
      if (mounted) showShareSheet(context, link.url, _photo!.caption ?? '家庭照片');
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    }
  }

  Future<void> _delete() async {
    if (_photo == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除照片'),
        content: const Text('确定删除这张照片吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AppProvider>().api.deletePhoto(_photo!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final canDelete = _photo != null && (_photo!.uploadedBy == app.user?.id || app.home?.family?.ownerId == app.user?.id);
    final photos = widget.photos;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: photos != null ? Text('${_index + 1} / ${photos.length}', style: const TextStyle(color: Colors.white, fontSize: 16)) : null,
        actions: [
          IconButton(onPressed: _share, icon: const Icon(Icons.share_outlined)),
          if (canDelete) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: Column(children: [
        Expanded(
          flex: 5,
          child: photos != null
              ? PageView.builder(
                  controller: _page,
                  itemCount: photos.length,
                  onPageChanged: (i) {
                    setState(() => _index = i);
                    _load(photos[i].id);
                  },
                  itemBuilder: (c, i) => InteractiveViewer(
                    child: Hero(tag: 'photo_${photos[i].id}', child: Center(child: NetImage(photos[i].url, fit: BoxFit.contain))),
                  ),
                )
              : InteractiveViewer(child: Center(child: _photo == null ? const CircularProgressIndicator(color: Colors.white) : NetImage(_photo!.url, fit: BoxFit.contain))),
        ),
        // 信息与评论
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: _photo == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_photo!.caption ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('${_photo!.uploaderName ?? ''} · ${fmtDate(_photo!.takenAt ?? _photo!.createdAt)}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ]),
                        ),
                        TextButton.icon(
                          onPressed: _like,
                          icon: const Icon(Icons.favorite, color: AppColors.primary),
                          label: Text('${_photo!.likes}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _loading && _photo!.comments.isEmpty
                          ? const SizedBox()
                          : _photo!.comments.isEmpty
                              ? const Center(child: Text('还没有评论，说点什么吧', style: TextStyle(color: AppColors.textSecondary)))
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  itemCount: _photo!.comments.length,
                                  itemBuilder: (c, i) {
                                    final cm = _photo!.comments[i];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Avatar(url: cm.avatarUrl, name: cm.nickname, size: 36),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Row(children: [
                                              Text(cm.nickname, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                              const SizedBox(width: 8),
                                              Text(timeAgo(cm.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                            ]),
                                            const SizedBox(height: 2),
                                            Text(cm.content, style: const TextStyle(fontSize: 15, height: 1.4)),
                                          ]),
                                        ),
                                      ]),
                                    );
                                  },
                                ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(children: [
                          Expanded(
                            child: TextField(
                              controller: _comment,
                              decoration: const InputDecoration(hintText: '写评论...', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _sending ? null : _send,
                            icon: const Icon(Icons.send_rounded),
                            style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                          ),
                        ]),
                      ),
                    ),
                  ]),
          ),
        ),
      ]),
    );
  }
}
