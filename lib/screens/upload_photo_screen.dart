import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../services/file_picker_service.dart';

/// 上传照片：支持从设备选择文件 或 粘贴图片链接
class UploadPhotoScreen extends StatefulWidget {
  final Album album;
  const UploadPhotoScreen({super.key, required this.album});

  @override
  State<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  final _caption = TextEditingController();
  final _url = TextEditingController();
  Uint8List? _bytes;
  String? _filename;
  bool _busy = false;
  int _mode = 0; // 0 本地文件  1 图片链接

  Future<void> _pick() async {
    final picked = await FilePickerService.pickImage();
    if (picked != null) {
      setState(() {
        _bytes = picked.bytes;
        _filename = picked.name;
      });
    }
  }

  Future<void> _submit() async {
    final api = context.read<AppProvider>().api;
    setState(() => _busy = true);
    try {
      String url;
      if (_mode == 0) {
        if (_bytes == null) throw Exception('请先选择一张图片');
        url = await api.upload(_bytes!, _filename ?? 'photo.jpg');
      } else {
        url = _url.text.trim();
        if (!url.startsWith('http')) throw Exception('请输入有效的图片链接');
      }
      await api.addPhoto(widget.album.id, url, _caption.text.trim().isEmpty ? null : _caption.text.trim());
      if (!mounted) return;
      showToast(context, '上传成功');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showToast(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('上传到「${widget.album.title}」')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('从设备选择'), icon: Icon(Icons.photo_library_outlined)),
                ButtonSegment(value: 1, label: Text('图片链接'), icon: Icon(Icons.link)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
              style: SegmentedButton.styleFrom(selectedBackgroundColor: AppColors.primaryLight, selectedForegroundColor: AppColors.primary),
            ),
            const SizedBox(height: 20),
            if (_mode == 0)
              GestureDetector(
                onTap: _pick,
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _bytes == null ? AppColors.divider : AppColors.primary, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _bytes == null
                      ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 56, color: AppColors.primary),
                          SizedBox(height: 12),
                          Text('点击选择照片', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('支持 JPG / PNG / GIF / WEBP，最大 50MB', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ])
                      : Stack(fit: StackFit.expand, children: [
                          Image.memory(_bytes!, fit: BoxFit.cover),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: IconButton.filled(
                              onPressed: () => setState(() => _bytes = null),
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                            ),
                          ),
                        ]),
                ),
              )
            else ...[
              TextField(
                controller: _url,
                decoration: const InputDecoration(hintText: 'https://... 图片地址', prefixIcon: Icon(Icons.image_outlined)),
                onChanged: (_) => setState(() {}),
              ),
              if (_url.text.trim().startsWith('http')) ...[
                const SizedBox(height: 14),
                NetImage(_url.text.trim(), height: 220, width: double.infinity, radius: BorderRadius.circular(20)),
              ],
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _caption,
              maxLines: 2,
              decoration: const InputDecoration(hintText: '写一句说明（选填），如：奶奶包的饺子最香', prefixIcon: Icon(Icons.edit_note_rounded)),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_busy ? '上传中...' : '确认上传'),
            ),
          ]),
        ),
      ),
    );
  }
}
