import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/conversion_settings.dart';

class AdvancedOptionsDialog extends StatefulWidget {
  const AdvancedOptionsDialog({super.key, required this.initialSettings});

  final ConversionSettings initialSettings;

  static Future<ConversionSettings?> show(
    BuildContext context, {
    required ConversionSettings initialSettings,
  }) {
    return showDialog<ConversionSettings>(
      context: context,
      builder: (context) =>
          AdvancedOptionsDialog(initialSettings: initialSettings),
    );
  }

  @override
  State<AdvancedOptionsDialog> createState() => _AdvancedOptionsDialogState();
}

class _AdvancedOptionsDialogState extends State<AdvancedOptionsDialog> {
  static const List<String> _watermarkPositions = <String>[
    'top_left',
    'top_right',
    'bottom_left',
    'bottom_right',
    'center',
  ];

  late bool _enableWatermark;
  late String _watermarkType;
  late String _watermarkText;
  String? _watermarkImagePath;
  late double _watermarkOpacity;
  late String _watermarkPosition;
  late double _watermarkFontSize;

  late bool _stripMetadata;
  late TextEditingController _authorController;
  late TextEditingController _copyrightController;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    final settings = widget.initialSettings;
    _enableWatermark = settings.enableWatermark;
    _watermarkType = settings.watermarkType;
    _watermarkText = settings.watermarkText;
    _watermarkImagePath = settings.watermarkImagePath;
    _watermarkOpacity = settings.watermarkOpacity.toDouble();
    _watermarkPosition = settings.watermarkPosition;
    _watermarkFontSize = settings.watermarkFontSize.toDouble();

    _stripMetadata = settings.stripMetadata;
    _authorController = TextEditingController(
      text: settings.metadataAuthor ?? '',
    );
    _copyrightController = TextEditingController(
      text: settings.metadataCopyright ?? '',
    );
    _commentController = TextEditingController(
      text: settings.metadataComment ?? '',
    );
  }

  @override
  void dispose() {
    _authorController.dispose();
    _copyrightController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('高级选项'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('水印配置'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _enableWatermark,
                onChanged: (value) => setState(() => _enableWatermark = value),
                title: const Text('启用水印'),
                subtitle: const Text('支持文字水印或图片水印'),
              ),
              if (_enableWatermark) ...[
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'text',
                      icon: Icon(Icons.text_fields_rounded),
                      label: Text('文字水印'),
                    ),
                    ButtonSegment(
                      value: 'image',
                      icon: Icon(Icons.image_rounded),
                      label: Text('图片水印'),
                    ),
                  ],
                  selected: <String>{_watermarkType},
                  onSelectionChanged: (value) =>
                      setState(() => _watermarkType = value.first),
                ),
                const SizedBox(height: 10),
                if (_watermarkType == 'text')
                  TextFormField(
                    initialValue: _watermarkText,
                    decoration: const InputDecoration(
                      labelText: '水印文字',
                      hintText: '例如：Image Converter Pro',
                    ),
                    onChanged: (value) => _watermarkText = value,
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          initialValue: _watermarkImagePath ?? '',
                          decoration: const InputDecoration(
                            labelText: '水印图片',
                            hintText: '请选择 PNG/WebP 等图片',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _pickWatermarkImage,
                        icon: const Icon(Icons.folder_open_rounded),
                        label: const Text('选择'),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Text('透明度: ${_watermarkOpacity.toInt()}%'),
                Slider(
                  value: _watermarkOpacity,
                  min: 5,
                  max: 100,
                  divisions: 19,
                  label: '${_watermarkOpacity.toInt()}%',
                  onChanged: (value) =>
                      setState(() => _watermarkOpacity = value),
                ),
                DropdownButtonFormField<String>(
                  value: _watermarkPosition,
                  decoration: const InputDecoration(labelText: '位置'),
                  items: _watermarkPositions
                      .map(
                        (position) => DropdownMenuItem(
                          value: position,
                          child: Text(_displayPosition(position)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _watermarkPosition = value);
                  },
                ),
                const SizedBox(height: 8),
                Text('文字字号: ${_watermarkFontSize.toInt()}'),
                Slider(
                  value: _watermarkFontSize,
                  min: 10,
                  max: 72,
                  divisions: 31,
                  onChanged: _watermarkType == 'text'
                      ? (value) => setState(() => _watermarkFontSize = value)
                      : null,
                ),
              ],
              const SizedBox(height: 18),
              _buildSectionTitle('元数据配置'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _stripMetadata,
                onChanged: (value) => setState(() => _stripMetadata = value),
                title: const Text('清除原始元数据'),
                subtitle: const Text('用于隐私保护，可移除拍摄设备与定位等信息'),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: '作者 (可选)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _copyrightController,
                decoration: const InputDecoration(labelText: '版权信息 (可选)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '备注/说明 (可选)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(onPressed: _apply, child: const Text('应用')),
      ],
    );
  }

  Future<void> _pickWatermarkImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }
    setState(() => _watermarkImagePath = path);
  }

  void _apply() {
    if (_enableWatermark &&
        _watermarkType == 'text' &&
        _watermarkText.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('启用文字水印时，请输入水印文字')));
      return;
    }

    if (_enableWatermark &&
        _watermarkType == 'image' &&
        (_watermarkImagePath == null || _watermarkImagePath!.trim().isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('启用图片水印时，请选择水印图片')));
      return;
    }

    final updated = widget.initialSettings.copyWith(
      enableWatermark: _enableWatermark,
      watermarkType: _watermarkType,
      watermarkText: _watermarkText.trim(),
      watermarkImagePath: _enableWatermark && _watermarkType == 'image'
          ? _watermarkImagePath?.trim()
          : null,
      watermarkOpacity: _watermarkOpacity.toInt().clamp(0, 100),
      watermarkPosition: _watermarkPosition,
      watermarkFontSize: _watermarkFontSize.toInt().clamp(8, 160),
      stripMetadata: _stripMetadata,
      metadataAuthor: _trimToNullable(_authorController.text),
      metadataCopyright: _trimToNullable(_copyrightController.text),
      metadataComment: _trimToNullable(_commentController.text),
    );
    Navigator.of(context).pop(updated);
  }

  String _displayPosition(String value) {
    return switch (value) {
      'top_left' => '左上',
      'top_right' => '右上',
      'bottom_left' => '左下',
      'bottom_right' => '右下',
      'center' => '居中',
      _ => '右下',
    };
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  String? _trimToNullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
