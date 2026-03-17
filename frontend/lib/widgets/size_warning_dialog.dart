import 'package:flutter/material.dart';

import '../models/image_file_model.dart';

enum SizeWarningAction { useJpg, lowerQuality, continueCurrent, cancel }

class SizeWarningDecision {
  const SizeWarningDecision({required this.action, this.suggestedQuality});

  final SizeWarningAction action;
  final int? suggestedQuality;
}

class SizeWarningDialog extends StatefulWidget {
  const SizeWarningDialog({
    super.key,
    required this.riskyFiles,
    required this.totalOriginalBytes,
    required this.totalEstimatedBytes,
    required this.sourceFormatLabel,
    required this.currentFormat,
    required this.currentQuality,
  });

  final List<ImageFileModel> riskyFiles;
  final int totalOriginalBytes;
  final int totalEstimatedBytes;
  final String sourceFormatLabel;
  final String currentFormat;
  final int currentQuality;

  static Future<SizeWarningDecision?> show(
    BuildContext context, {
    required List<ImageFileModel> riskyFiles,
    required int totalOriginalBytes,
    required int totalEstimatedBytes,
    required String sourceFormatLabel,
    required String currentFormat,
    required int currentQuality,
  }) {
    return showDialog<SizeWarningDecision>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SizeWarningDialog(
        riskyFiles: riskyFiles,
        totalOriginalBytes: totalOriginalBytes,
        totalEstimatedBytes: totalEstimatedBytes,
        sourceFormatLabel: sourceFormatLabel,
        currentFormat: currentFormat,
        currentQuality: currentQuality,
      ),
    );
  }

  @override
  State<SizeWarningDialog> createState() => _SizeWarningDialogState();
}

class _SizeWarningDialogState extends State<SizeWarningDialog> {
  late double _quality;

  @override
  void initState() {
    super.initState();
    final suggested = widget.currentQuality > 80 ? 80 : widget.currentQuality;
    _quality = suggested.clamp(60, 90).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFB26A00)),
          SizedBox(width: 8),
          Text('文件大小提醒'),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.sourceFormatLabel} → ${widget.currentFormat.toUpperCase()} 转换会显著增大体积：',
              ),
              const SizedBox(height: 10),
              ...widget.riskyFiles.take(5).map(_buildRiskItem),
              if (widget.riskyFiles.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '还有 ${widget.riskyFiles.length - 5} 张未展开显示',
                    style: const TextStyle(color: Color(0xFF6F7D93)),
                  ),
                ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '总计：${_formatBytes(widget.totalOriginalBytes)} → 约 ${_formatBytes(widget.totalEstimatedBytes)}',
                ),
              ),
              const SizedBox(height: 12),
              const Text('可选快速操作：'),
              const SizedBox(height: 6),
              Text(
                '• 改用 JPG：通常能显著减小输出体积\n'
                '• 降低质量：当前 ${widget.currentQuality}，建议 $_quality',
                style: const TextStyle(color: Color(0xFF4A5970)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('建议质量'),
                  Expanded(
                    child: Slider(
                      min: 60,
                      max: 90,
                      divisions: 30,
                      value: _quality,
                      onChanged: (value) => setState(() => _quality = value),
                    ),
                  ),
                  Text(_quality.toInt().toString()),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _submit(SizeWarningAction.cancel),
          child: const Text('取消'),
        ),
        OutlinedButton(
          onPressed: () => _submit(SizeWarningAction.continueCurrent),
          child: Text('继续使用 ${widget.currentFormat.toUpperCase()}'),
        ),
        OutlinedButton(
          onPressed: () => _submit(
            SizeWarningAction.lowerQuality,
            quality: _quality.toInt(),
          ),
          child: const Text('降低质量'),
        ),
        FilledButton(
          onPressed: () => _submit(SizeWarningAction.useJpg),
          child: const Text('改用 JPG（推荐）'),
        ),
      ],
    );
  }

  Widget _buildRiskItem(ImageFileModel item) {
    final estimated = item.estimatedOutputSize ?? item.fileSize;
    final ratio = item.estimatedChangeRatio ?? 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        '• ${item.fileName}: ${_formatBytes(item.fileSize)} → 约 ${_formatBytes(estimated)}（约 ${ratio.toStringAsFixed(1)} 倍）',
      ),
    );
  }

  void _submit(SizeWarningAction action, {int? quality}) {
    Navigator.of(
      context,
    ).pop(SizeWarningDecision(action: action, suggestedQuality: quality));
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
