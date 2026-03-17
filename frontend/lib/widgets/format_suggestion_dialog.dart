import 'package:flutter/material.dart';

class FormatSuggestionDecision {
  const FormatSuggestionDecision({
    required this.selectedFormat,
    required this.neverShowAgain,
  });

  final String selectedFormat;
  final bool neverShowAgain;
}

class FormatSuggestionDialog extends StatefulWidget {
  const FormatSuggestionDialog({super.key, required this.heicCount});

  final int heicCount;

  static Future<FormatSuggestionDecision?> show(
    BuildContext context, {
    required int heicCount,
  }) {
    return showDialog<FormatSuggestionDecision>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FormatSuggestionDialog(heicCount: heicCount),
    );
  }

  @override
  State<FormatSuggestionDialog> createState() => _FormatSuggestionDialogState();
}

class _FormatSuggestionDialogState extends State<FormatSuggestionDialog> {
  bool _neverShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF0D47A1)),
          SizedBox(width: 8),
          Text('格式建议'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('检测到 ${widget.heicCount} 张 HEIC/HEIF 照片。'),
              const SizedBox(height: 8),
              const Text('HEIC 转 PNG 通常会明显变大（约 5-10 倍），若用于日常查看与分享，建议改为 JPG。'),
              const SizedBox(height: 14),
              _FormatCard(
                title: 'JPG（推荐）',
                subtitle: '体积适中，兼容性最佳',
                color: const Color(0xFF1B5E20),
              ),
              const SizedBox(height: 8),
              _FormatCard(
                title: 'PNG',
                subtitle: '无损但体积最大，适合设计素材',
                color: const Color(0xFFB26A00),
              ),
              const SizedBox(height: 8),
              _FormatCard(
                title: 'WebP',
                subtitle: '体积更小，适合网页场景',
                color: const Color(0xFF0D47A1),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _neverShowAgain,
                title: const Text('不再提示（以后自动应用本次选择）'),
                onChanged: (value) {
                  setState(() => _neverShowAgain = value ?? false);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _submit('png'),
          child: const Text('继续 PNG'),
        ),
        OutlinedButton(
          onPressed: () => _submit('webp'),
          child: const Text('使用 WebP'),
        ),
        FilledButton(
          onPressed: () => _submit('jpg'),
          child: const Text('使用 JPG（推荐）'),
        ),
      ],
    );
  }

  void _submit(String format) {
    Navigator.of(context).pop(
      FormatSuggestionDecision(
        selectedFormat: format,
        neverShowAgain: _neverShowAgain,
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFF4A5970))),
        ],
      ),
    );
  }
}
