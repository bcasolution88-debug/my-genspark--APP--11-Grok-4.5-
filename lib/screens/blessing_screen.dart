import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'anniversary_screen.dart';

/// 祝福墙：全部祝福 + 发送文字祝福
class BlessingScreen extends StatefulWidget {
  final Anniversary anniversary;
  final bool openCompose;
  const BlessingScreen({super.key, required this.anniversary, this.openCompose = false});

  @override
  State<BlessingScreen> createState() => _BlessingScreenState();
}

class _BlessingScreenState extends State<BlessingScreen> {
  late List<Blessing> _list = widget.anniversary.blessings;
  final _text = TextEditingController();
  bool _sending = false;

  static const templates = [
    '祝爷爷奶奶金婚快乐，健康长寿，永远幸福！',
    '五十年风雨同舟，你们是我们最好的榜样。',
    '愿你们的爱情像美酒一样，越陈越香。',
    '感谢你们用一生诠释了什么是真爱。',
    '祝福二老福如东海、寿比南山，相伴永远！',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.openCompose) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _compose());
    }
  }

  Future<void> _reload() async {
    try {
      final an = await context.read<AppProvider>().api.anniversary();
      if (mounted) setState(() => _list = an.blessings);
    } catch (_) {}
  }

  Future<void> _send(String content) async {
    if (content.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await context.read<AppProvider>().api.addBlessing(content: content.trim());
      _text.clear();
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst || r.settings.name != 'compose');
      showToast(context, '祝福已送达 ❤');
      await _reload();
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _compose() {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      routeSettings: const RouteSettings(name: 'compose'),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.card_giftcard_rounded, color: AppColors.gold),
            const SizedBox(width: 8),
            Text('给 ${widget.anniversary.husbandName} 和 ${widget.anniversary.wifeName} 送上祝福',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(hintText: '写下你的祝福...'),
          ),
          const SizedBox(height: 12),
          const Text('快捷祝福语', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (c, i) => ActionChip(
                label: Text(templates[i].length > 14 ? '${templates[i].substring(0, 14)}…' : templates[i], style: const TextStyle(fontSize: 12)),
                onPressed: () => _text.text = templates[i],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showToast(ctx, '语音祝福：移动端将唤起录音，Web 预览暂不支持'),
                icon: const Icon(Icons.mic_rounded),
                label: const Text('语音祝福'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : () => _send(_text.text),
                icon: const Icon(Icons.send_rounded),
                label: const Text('送出祝福'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('祝福墙 (${_list.length})')),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _reload,
          child: StateView(
            empty: _list.isEmpty,
            emptyText: '还没有祝福，做第一个送祝福的人吧',
            emptyIcon: Icons.card_giftcard_rounded,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: _list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (c, i) => BlessingCard(_list[i], onChanged: _reload),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
        backgroundColor: AppColors.gold,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('写祝福'),
      ),
    );
  }
}
