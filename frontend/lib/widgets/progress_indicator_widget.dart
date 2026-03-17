import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  const ProgressIndicatorWidget({
    super.key,
    required this.total,
    required this.completed,
    required this.failed,
    this.etaSeconds,
  });

  final int total;
  final int completed;
  final int failed;
  final int? etaSeconds;

  @override
  Widget build(BuildContext context) {
    final processed = completed + failed;
    final remaining = math.max(0, total - processed);
    final percent = total == 0
        ? 0.0
        : (processed / total).clamp(0.0, 1.0).toDouble();
    final percentText = '${(percent * 100).toStringAsFixed(0)}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '正在处理 ($processed/$total)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  percentText,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearPercentIndicator(
              lineHeight: 10,
              percent: percent,
              barRadius: const Radius.circular(8),
              progressColor: Theme.of(context).colorScheme.primary,
              backgroundColor: const Color(0xFFDCE3EE),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            Text(
              '已完成: $completed  |  失败: $failed  |  剩余: $remaining',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (etaSeconds != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '预计剩余时间: ${_formatEta(etaSeconds!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF607089),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatEta(int seconds) {
    if (seconds <= 1) {
      return '不到 1 秒';
    }
    if (seconds < 60) {
      return '约 $seconds 秒';
    }
    final minutes = seconds ~/ 60;
    final remainSeconds = seconds % 60;
    if (remainSeconds == 0) {
      return '约 $minutes 分钟';
    }
    return '约 $minutes 分 $remainSeconds 秒';
  }
}
