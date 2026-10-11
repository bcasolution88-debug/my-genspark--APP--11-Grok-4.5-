import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'blessing_screen.dart';

class AnniversaryScreen extends StatefulWidget {
  const AnniversaryScreen({super.key});

  @override
  State<AnniversaryScreen> createState() => AnniversaryScreenState();
}

class AnniversaryScreenState extends State<AnniversaryScreen> {
  Anniversary? _an;
  bool _loading = true;
  String? _error;
  bool _notCreated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    setState(() {
      _loading = true;
      _error = null;
      _notCreated = false;
    });
    try {
      final an = await context.read<AppProvider>().api.anniversary();
      if (mounted) setState(() => _an = an);
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('还未创建')) {
        setState(() => _notCreated = true);
      } else {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share() async {
    if (_an == null) return;
    try {
      final link = await context.read<AppProvider>().api.share('anniversary', _an!.id);
      if (mounted) showShareSheet(context, link.url, '${_an!.husbandName} ❤ ${_an!.wifeName} ${_an!.title}');
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    }
  }

  Future<void> _showCreate() async {
    final h = TextEditingController(text: _an?.husbandName);
    final w = TextEditingController(text: _an?.wifeName);
    final story = TextEditingController(text: _an?.story);
    DateTime wedding = _an?.weddingDate ?? DateTime(1975, 10, 1);
    DateTime? celebration = _an?.celebrationDate;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(_an == null ? '创建金婚纪念专区' : '编辑纪念信息', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: TextField(controller: h, decoration: const InputDecoration(hintText: '爷爷姓名'))),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.favorite, color: AppColors.primary)),
                Expanded(child: TextField(controller: w, decoration: const InputDecoration(hintText: '奶奶姓名'))),
              ]),
              const SizedBox(height: 12),
              _dateTile(ctx, '结婚日期', wedding, (d) => setS(() => wedding = d), firstDate: DateTime(1900)),
              const SizedBox(height: 8),
              _dateTile(ctx, '庆典日期（选填）', celebration, (d) => setS(() => celebration = d), firstDate: DateTime(2000), lastDate: DateTime(2100)),
              const SizedBox(height: 12),
              TextField(controller: story, maxLines: 4, decoration: const InputDecoration(hintText: '他们的爱情故事（选填）')),
              const SizedBox(height: 22),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
            ]),
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    if (h.text.trim().isEmpty || w.text.trim().isEmpty) return showToast(context, '请填写两位老人的姓名', error: true);
    try {
      await context.read<AppProvider>().api.saveAnniversary({
        'husband_name': h.text.trim(),
        'wife_name': w.text.trim(),
        'wedding_date': wedding.toIso8601String(),
        'celebration_date': celebration?.toIso8601String(),
        'story': story.text.trim().isEmpty ? null : story.text.trim(),
        'cover_url': _an?.coverUrl ?? 'https://images.unsplash.com/photo-1519741497674-611481863552?w=900&q=80',
      });
      if (!mounted) return;
      showToast(context, '已保存');
      load();
      context.read<AppProvider>().refreshHome();
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    }
  }

  Widget _dateTile(BuildContext ctx, String label, DateTime? value, ValueChanged<DateTime> onPick, {required DateTime firstDate, DateTime? lastDate}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.divider)),
      leading: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      subtitle: Text(value == null ? '点击选择' : fmtDate(value), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      onTap: () async {
        final d = await showDatePicker(context: ctx, initialDate: value ?? DateTime.now(), firstDate: firstDate, lastDate: lastDate ?? DateTime.now());
        if (d != null) onPick(d);
      },
    );
  }

  Future<void> _addTimeline() async {
    final title = TextEditingController();
    final desc = TextEditingController();
    DateTime date = DateTime.now();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('添加时光轴事件', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            _dateTile(ctx, '事件日期', date, (d) => setS(() => date = d), firstDate: DateTime(1900)),
            const SizedBox(height: 12),
            TextField(controller: title, decoration: const InputDecoration(hintText: '事件标题，如：搬进新家')),
            const SizedBox(height: 12),
            TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(hintText: '描述（选填）')),
            const SizedBox(height: 22),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('添加')),
          ]),
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty || !mounted) return;
    try {
      await context.read<AppProvider>().api.addTimeline(date, title.text.trim(), desc.text.trim().isEmpty ? null : desc.text.trim());
      load();
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notCreated) {
      return Scaffold(
        appBar: AppBar(title: const Text('金婚纪念')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(color: AppColors.goldLight, shape: BoxShape.circle),
                child: const Icon(Icons.favorite_rounded, color: AppColors.gold, size: 60),
              ),
              const SizedBox(height: 24),
              const Text('为家里的老人建一个纪念专区', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('记录他们携手走过的岁月，收集全家人的祝福', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 28),
              ElevatedButton.icon(onPressed: _showCreate, icon: const Icon(Icons.add), label: const Text('创建纪念专区')),
            ]),
          ),
        ),
      );
    }

    final an = _an;
    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: load,
        child: StateView(
          loading: _loading && an == null,
          error: an == null ? _error : null,
          onRetry: load,
          child: an == null
              ? const SizedBox()
              : CustomScrollView(slivers: [
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    backgroundColor: const Color(0xFFB83A2C),
                    foregroundColor: Colors.white,
                    actions: [
                      IconButton(onPressed: _showCreate, icon: const Icon(Icons.edit_outlined)),
                      IconButton(onPressed: _share, icon: const Icon(Icons.share_outlined)),
                    ],
                    flexibleSpace: FlexibleSpaceBar(background: _Hero(an)),
                  ),
                  SliverToBoxAdapter(child: _Stats(an)),
                  if (an.story != null && an.story!.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Row(children: [
                                Icon(Icons.format_quote_rounded, color: AppColors.gold),
                                SizedBox(width: 6),
                                Text('他们的故事', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              ]),
                              const SizedBox(height: 10),
                              Text(an.story!, style: const TextStyle(fontSize: 15, height: 1.7)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(child: SectionHeader('爱情时光轴', action: '添加', onAction: _addTimeline)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (c, i) => _TimelineTile(an.timeline[i], isFirst: i == 0, isLast: i == an.timeline.length - 1),
                      childCount: an.timeline.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      '祝福墙 (${an.blessingCount})',
                      action: '全部',
                      onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlessingScreen(anniversary: an))).then((_) => load()),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (c, i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: BlessingCard(an.blessings[i], onChanged: load)),
                        childCount: an.blessings.length > 3 ? 3 : an.blessings.length,
                      ),
                    ),
                  ),
                ]),
        ),
      ),
      floatingActionButton: an == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlessingScreen(anniversary: an, openCompose: true))).then((_) => load()),
              backgroundColor: AppColors.gold,
              icon: const Icon(Icons.card_giftcard_rounded),
              label: const Text('送上祝福'),
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  final Anniversary an;
  const _Hero(this.an);

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      NetImage(an.coverUrl),
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, const Color(0xFF8B2E22).withValues(alpha: 0.95)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.3, 1],
          ),
        ),
      ),
      Positioned(
        left: 20,
        right: 20,
        bottom: 24,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF2C94C), Color(0xFFE2A93B)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text('${an.title} · ${an.yearsTogether} 周年', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 12),
          Text('${an.husbandName}  ❤  ${an.wifeName}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text('结婚于 ${fmtDate(an.weddingDate)}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ]),
      ),
    ]);
  }
}

class _Stats extends StatelessWidget {
  final Anniversary an;
  const _Stats(this.an);

  @override
  Widget build(BuildContext context) {
    final until = an.daysUntilCelebration;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(children: [
        _stat('${an.yearsTogether}', '年', '携手走过'),
        const SizedBox(width: 12),
        _stat('${an.daysTogether}', '天', '朝夕相伴'),
        const SizedBox(width: 12),
        if (until != null && until >= 0)
          _stat('$until', '天', '距离庆典', highlight: true)
        else
          _stat('${an.blessingCount}', '条', '收到祝福', highlight: true),
      ]),
    );
  }

  Widget _stat(String num, String unit, String label, {bool highlight = false}) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: highlight ? AppColors.goldLight : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: highlight ? Border.all(color: AppColors.gold.withValues(alpha: 0.5)) : null,
          ),
          child: Column(children: [
            RichText(
              text: TextSpan(children: [
                TextSpan(text: num, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: highlight ? AppColors.gold : AppColors.primary)),
                TextSpan(text: ' $unit', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ]),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
      );
}

class _TimelineTile extends StatelessWidget {
  final TimelineEvent e;
  final bool isFirst, isLast;
  const _TimelineTile(this.e, {required this.isFirst, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 64,
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const SizedBox(height: 14),
              Text('${e.eventDate.year}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 15)),
              Text(fmtDate(e.eventDate, pattern: 'M月d日'), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(width: 12),
          Column(children: [
            Container(width: 2, height: 14, color: isFirst ? Colors.transparent : AppColors.divider),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(shape: BoxShape.circle, color: isLast ? AppColors.gold : AppColors.primary, border: Border.all(color: Colors.white, width: 2.5)),
            ),
            Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : AppColors.divider)),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (e.imageUrl != null) NetImage(e.imageUrl, height: 130, width: double.infinity),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      if (e.description != null) ...[
                        const SizedBox(height: 4),
                        Text(e.description!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                      ],
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// 祝福卡片（金婚页与祝福墙复用）
class BlessingCard extends StatelessWidget {
  final Blessing b;
  final VoidCallback? onChanged;
  const BlessingCard(this.b, {super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Avatar(url: b.avatarUrl, name: b.nickname, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(b.nickname, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  if (b.roleName != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(8)),
                      child: Text(b.roleName!, style: const TextStyle(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
                Text(timeAgo(b.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ),
            TextButton.icon(
              onPressed: () async {
                try {
                  await context.read<AppProvider>().api.likeBlessing(b.id);
                  onChanged?.call();
                } catch (_) {}
              },
              icon: const Icon(Icons.favorite_border, size: 18, color: AppColors.primary),
              label: Text('${b.likes}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
            ),
          ]),
          const SizedBox(height: 12),
          if (b.isVoice)
            _VoiceBubble(b)
          else
            Text(b.content ?? '', style: const TextStyle(fontSize: 16, height: 1.6)),
        ]),
      ),
    );
  }
}

class _VoiceBubble extends StatelessWidget {
  final Blessing b;
  const _VoiceBubble(this.b);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showToast(context, '语音播放：${b.audioDuration}″（移动端将调用系统播放器）'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFFF08A6B)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: List.generate(18, (i) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  height: 8 + ((i * 7) % 16).toDouble(),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(2)),
                ),
              )),
            ),
          ),
          const SizedBox(width: 12),
          Text('${b.audioDuration}″', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
