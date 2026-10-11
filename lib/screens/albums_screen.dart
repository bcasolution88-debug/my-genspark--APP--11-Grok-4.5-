import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

const albumCategories = ['全部', '节日', '生日', '旅行', '日常', '金婚'];

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => AlbumsScreenState();
}

class AlbumsScreenState extends State<AlbumsScreen> {
  String _category = '全部';
  List<Album> _albums = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<AppProvider>().api.albums(category: _category == '全部' ? null : _category);
      if (mounted) setState(() => _albums = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> showCreateDialog() async {
    final title = TextEditingController();
    final desc = TextEditingController();
    String cat = '日常';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('新建相册', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            TextField(controller: title, decoration: const InputDecoration(hintText: '相册名称，如：中秋团圆')),
            const SizedBox(height: 12),
            TextField(controller: desc, maxLines: 2, decoration: const InputDecoration(hintText: '描述（选填）')),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: albumCategories
                  .skip(1)
                  .map((c) => ChoiceChip(
                        label: Text(c),
                        selected: cat == c,
                        onSelected: (_) => setS(() => cat = c),
                        labelStyle: TextStyle(color: cat == c ? Colors.white : AppColors.textPrimary),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 22),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('创建')),
          ]),
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty || !mounted) return;
    try {
      await context.read<AppProvider>().api.createAlbum(title.text.trim(), cat, desc.text.trim().isEmpty ? null : desc.text.trim());
      if (!mounted) return;
      showToast(context, '相册已创建');
      load();
      context.read<AppProvider>().refreshHome();
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('家庭相册')),
      body: SafeArea(
        child: Column(children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: albumCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (c, i) {
                final cat = albumCategories[i];
                final sel = cat == _category;
                return ChoiceChip(
                  label: Text(cat),
                  selected: sel,
                  labelStyle: TextStyle(color: sel ? Colors.white : AppColors.textPrimary),
                  onSelected: (_) {
                    setState(() => _category = cat);
                    load();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: load,
              child: StateView(
                loading: _loading && _albums.isEmpty,
                error: _error,
                onRetry: load,
                empty: !_loading && _albums.isEmpty,
                emptyText: '这个分类下还没有相册',
                emptyIcon: Icons.photo_album_outlined,
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.85),
                  itemCount: _albums.length,
                  itemBuilder: (c, i) => AlbumCard(_albums[i]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
