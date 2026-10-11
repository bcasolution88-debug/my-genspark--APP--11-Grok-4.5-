import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

String fmtDate(DateTime? d, {String pattern = 'yyyy年M月d日'}) =>
    d == null ? '' : DateFormat(pattern).format(d.toLocal());

String timeAgo(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
  if (diff.inDays < 1) return '${diff.inHours}小时前';
  if (diff.inDays < 30) return '${diff.inDays}天前';
  return fmtDate(d, pattern: 'M月d日');
}

void showToast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.primaryDark : AppColors.textPrimary,
    ));
}

/// 网络图片（带占位与错误处理）
class NetImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width, height;
  final BorderRadius? radius;

  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.width, this.height, this.radius});

  @override
  Widget build(BuildContext context) {
    Widget child = url == null || url!.isEmpty
        ? _placeholder()
        : Image.network(
            url!,
            fit: fit,
            width: width,
            height: height,
            loadingBuilder: (c, w, p) => p == null ? w : _placeholder(loading: true),
            errorBuilder: (c, e, s) => _placeholder(),
          );
    if (radius != null) child = ClipRRect(borderRadius: radius!, child: child);
    return child;
  }

  Widget _placeholder({bool loading = false}) => Container(
        width: width,
        height: height,
        color: AppColors.primaryLight,
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
            : const Icon(Icons.photo_outlined, color: AppColors.primary, size: 32),
      );
}

/// 圆形头像
class Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  final bool bordered;
  const Avatar({super.key, this.url, required this.name, this.size = 48, this.bordered = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight,
        border: bordered ? Border.all(color: AppColors.primary, width: 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url!.isEmpty
          ? Center(
              child: Text(name.isNotEmpty ? name.characters.first : '?',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: size * 0.4)))
          : Image.network(url!, fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Center(
                  child: Text(name.isNotEmpty ? name.characters.first : '?',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: size * 0.4)))),
    );
  }
}

/// 区块标题
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Row(children: [
                Text(action!, style: const TextStyle(color: AppColors.textSecondary)),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
              ]),
            ),
        ],
      ),
    );
  }
}

/// 加载 / 错误 / 空状态
class StateView extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool empty;
  final String emptyText;
  final IconData emptyIcon;
  final VoidCallback? onRetry;
  final Widget child;

  const StateView({
    super.key,
    this.loading = false,
    this.error,
    this.empty = false,
    this.emptyText = '暂无内容',
    this.emptyIcon = Icons.inbox_outlined,
    this.onRetry,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            if (onRetry != null) SizedBox(width: 140, child: ElevatedButton(onPressed: onRetry, child: const Text('重试'))),
          ]),
        ),
      );
    }
    if (empty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(emptyIcon, size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(emptyText, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ]),
      );
    }
    return child;
  }
}

/// 分享结果弹窗
Future<void> showShareSheet(BuildContext context, String url, String title) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            const Icon(Icons.share_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text('分享「$title」', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: SelectableText(url, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 8),
          const Text('链接 30 天内有效，家人无需登录即可查看', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  Navigator.pop(ctx);
                  showToast(context, '链接已复制，可粘贴到微信发送');
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('复制链接'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '【家爱相册】$title\n$url'));
                  Navigator.pop(ctx);
                  showToast(context, '已复制，打开微信粘贴发送给家人');
                },
                icon: const Icon(Icons.wechat),
                label: const Text('分享到微信'),
              ),
            ),
          ]),
        ]),
      ),
    ),
  );
}
