import 'package:flutter/material.dart';

import '../models/image_file_model.dart';

class ErrorDetailDialog extends StatelessWidget {
  const ErrorDetailDialog({super.key, required this.imageFile, this.onRetry});

  final ImageFileModel imageFile;
  final VoidCallback? onRetry;

  static Future<void> show(
    BuildContext context, {
    required ImageFileModel imageFile,
    VoidCallback? onRetry,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) =>
          ErrorDetailDialog(imageFile: imageFile, onRetry: onRetry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = imageFile.errorMessage ?? '未知错误';
    final suggestions = _suggestions(error);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Color(0xFFC62828)),
          SizedBox(width: 8),
          Text('错误详情'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow('文件', imageFile.fileName),
              _infoRow('大小', _formatBytes(imageFile.fileSize)),
              const SizedBox(height: 12),
              const Text('错误信息', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error,
                  style: const TextStyle(color: Color(0xFFB71C1C)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('建议处理', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              for (final suggestion in suggestions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $suggestion'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        if (onRetry != null)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!.call();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '$label：',
              style: const TextStyle(color: Color(0xFF607089)),
            ),
          ),
          Expanded(
            child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  List<String> _suggestions(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('超时')) {
      return <String>['降低输出质量后重试', '优先改为 JPG 格式再转换', '减少同时处理的文件数量'];
    }
    if (lower.contains('损坏') || lower.contains('无法识别')) {
      return <String>['检查原图是否完整可打开', '重新导出后再尝试转换'];
    }
    if (lower.contains('服务未启动') || lower.contains('网络')) {
      return <String>['确认应用服务正常运行', '稍后重新点击重试'];
    }
    if (lower.contains('文件过大')) {
      return <String>['先压缩原图再转换', '拆分批次逐步处理'];
    }
    return <String>['重新尝试一次转换', '如持续失败可更换输出格式'];
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }
}
