import 'package:flutter/material.dart';

class AnalysisResultDialog extends StatefulWidget {
  const AnalysisResultDialog({super.key, required this.analysis});

  final Map<String, dynamic> analysis;

  static Future<(String, int)?> show(
    BuildContext context, {
    required Map<String, dynamic> analysis,
  }) {
    return showDialog<(String, int)>(
      context: context,
      builder: (context) => AnalysisResultDialog(analysis: analysis),
    );
  }

  @override
  State<AnalysisResultDialog> createState() => _AnalysisResultDialogState();
}

class _AnalysisResultDialogState extends State<AnalysisResultDialog> {
  String? _selectedKey;

  @override
  Widget build(BuildContext context) {
    final overall = _asMap(widget.analysis['overall_recommendation']);
    final format = _stringValue(overall['format'], fallback: 'jpg');
    final quality = _intValue(overall['quality'], fallback: 85);
    final reason = _asStringList(overall['reason']);
    final reduction = _intValue(
      overall['estimated_reduction_percent'],
      fallback: 0,
    );
    final estimatedTotal = _intValue(
      overall['estimated_total_size'],
      fallback: 0,
    );
    final typeSummary = _asMap(overall['type_summary']);
    final alternatives = _collectAlternatives(widget.analysis);

    final selected = _selectedConfig(
      alternatives: alternatives,
      defaultFormat: format,
      defaultQuality: quality,
    );

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.psychology_rounded, color: Color(0xFF1565C0)),
          SizedBox(width: 8),
          Text('智能分析结果'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('图片类型分布'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: typeSummary.entries
                    .map(
                      (entry) => _chip(
                        '${_displayType(entry.key.toString())} ${entry.value}',
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              _sectionTitle('推荐配置'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${format.toUpperCase()} · 质量 $quality',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF0D3B66),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      estimatedTotal > 0
                          ? '预估总体积 ${_formatBytes(estimatedTotal)}，预计变化 ${reduction >= 0 ? '-' : '+'}${reduction.abs()}%'
                          : '已根据图片内容生成推荐参数',
                      style: const TextStyle(color: Color(0xFF365173)),
                    ),
                    if (reason.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final item in reason)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text('• $item'),
                        ),
                    ],
                  ],
                ),
              ),
              if (alternatives.isNotEmpty) ...[
                const SizedBox(height: 14),
                _sectionTitle('其他选项'),
                ...alternatives.map((alt) {
                  final key = '${alt.$1}_:${alt.$2}';
                  return RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: key,
                    groupValue: _selectedKey,
                    onChanged: (value) => setState(() => _selectedKey = value),
                    title: Text('${alt.$1.toUpperCase()} · 质量 ${alt.$2}'),
                    subtitle: Text(alt.$3),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.of(context).pop((selected.$1, selected.$2)),
          child: const Text('应用推荐'),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF3F4E63))),
    );
  }

  (String, int) _selectedConfig({
    required List<(String, int, String)> alternatives,
    required String defaultFormat,
    required int defaultQuality,
  }) {
    if (_selectedKey == null) {
      return (defaultFormat, defaultQuality);
    }
    for (final alt in alternatives) {
      if ('${alt.$1}_:${alt.$2}' == _selectedKey) {
        return (alt.$1, alt.$2);
      }
    }
    return (defaultFormat, defaultQuality);
  }

  List<(String, int, String)> _collectAlternatives(
    Map<String, dynamic> analysis,
  ) {
    final list = <(String, int, String)>[];
    final individual = analysis['individual_results'];
    if (individual is! List) {
      return list;
    }
    for (final item in individual) {
      final entry = _asMap(item);
      if (entry['success'] != true) {
        continue;
      }
      final alternatives = entry['alternatives'];
      if (alternatives is! List) {
        continue;
      }
      for (final alt in alternatives) {
        final altMap = _asMap(alt);
        final format = _stringValue(altMap['format']);
        final quality = _intValue(altMap['quality'], fallback: 85);
        final description = _stringValue(
          altMap['description'],
          fallback: '可选方案',
        );
        if (format.isEmpty) {
          continue;
        }
        if (!list.any((item) => item.$1 == format && item.$2 == quality)) {
          list.add((format, quality, description));
        }
      }
      if (list.length >= 3) {
        break;
      }
    }
    return list;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  List<String> _asStringList(Object? value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  int _intValue(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _displayType(String type) {
    return switch (type) {
      'photo' => '照片',
      'screenshot' => '截图',
      'graphic' => '图形',
      'mixed' => '混合',
      _ => type,
    };
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
