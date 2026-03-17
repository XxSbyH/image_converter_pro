import 'package:flutter/material.dart';

class QuickFormatGuideDialog extends StatelessWidget {
  const QuickFormatGuideDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const QuickFormatGuideDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('格式快速说明'),
      content: const SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuideRow(title: 'JPG', desc: '照片首选，体积适中，兼容性最好，建议质量 85-90'),
            SizedBox(height: 8),
            _GuideRow(title: 'PNG', desc: '无损格式，支持透明，文件通常较大'),
            SizedBox(height: 8),
            _GuideRow(title: 'WebP', desc: '体积更小，适合网页和现代应用场景'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.title, required this.desc});

  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: Text(desc)),
      ],
    );
  }
}
