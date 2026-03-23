import 'package:flutter/material.dart';

class ConversionSummaryDialog extends StatelessWidget {
  const ConversionSummaryDialog({
    super.key,
    required this.total,
    required this.success,
    required this.failed,
    required this.storageSummary,
    required this.onOpenOutput,
    this.onRetryFailed,
  });

  final int total;
  final int success;
  final int failed;
  final String storageSummary;
  final VoidCallback onOpenOutput;
  final VoidCallback? onRetryFailed;

  static Future<void> show(
    BuildContext context, {
    required int total,
    required int success,
    required int failed,
    required String storageSummary,
    required VoidCallback onOpenOutput,
    VoidCallback? onRetryFailed,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => ConversionSummaryDialog(
        total: total,
        success: success,
        failed: failed,
        storageSummary: storageSummary,
        onOpenOutput: onOpenOutput,
        onRetryFailed: onRetryFailed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSuccess = failed == 0;
    final iconColor = allSuccess
        ? const Color(0xFF2E7D32)
        : const Color(0xFFEF6C00);
    final icon = allSuccess
        ? Icons.check_circle_rounded
        : Icons.warning_amber_rounded;

    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          const Text('转换完成'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildInlineStat(
                  label: '总计',
                  value: '$total 张',
                  color: const Color(0xFF0D3B66),
                ),
                const Text('｜', style: TextStyle(color: Color(0xFFB6C3D8))),
                _buildInlineStat(
                  label: '成功',
                  value: '$success 张',
                  color: const Color(0xFF2E7D32),
                ),
                const Text('｜', style: TextStyle(color: Color(0xFFB6C3D8))),
                _buildInlineStat(
                  label: '失败',
                  value: '$failed 张',
                  color: failed > 0
                      ? const Color(0xFFC62828)
                      : const Color(0xFF8E9AAC),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                storageSummary,
                style: const TextStyle(
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!allSuccess) ...[
              const SizedBox(height: 10),
              const Text(
                '部分文件失败，可在列表中查看详情并重试。',
                style: TextStyle(color: Color(0xFF6F7D93)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (failed > 0 && onRetryFailed != null)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetryFailed!.call();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试失败项'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onOpenOutput();
          },
          child: const Text('打开输出文件夹'),
        ),
      ],
    );
  }

  Widget _buildInlineStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label：',
            style: const TextStyle(
              color: Color(0xFF44546A),
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
