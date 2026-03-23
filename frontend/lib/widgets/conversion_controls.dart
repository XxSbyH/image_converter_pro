import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/conversion_preset.dart';
import '../providers/conversion_provider.dart';
import '../services/preset_service.dart';
import 'advanced_options_dialog.dart';

class ConversionControls extends StatefulWidget {
  const ConversionControls({
    super.key,
    required this.isProcessing,
    required this.onPickFiles,
    required this.onPickFolder,
    required this.onStartConversion,
    required this.onOpenFormatGuide,
    required this.onAnalyze,
    required this.canAnalyze,
  });

  final bool isProcessing;
  final VoidCallback onPickFiles;
  final VoidCallback onPickFolder;
  final void Function(String format, int quality) onStartConversion;
  final VoidCallback onOpenFormatGuide;
  final VoidCallback onAnalyze;
  final bool canAnalyze;

  @override
  State<ConversionControls> createState() => _ConversionControlsState();
}

class _ConversionControlsState extends State<ConversionControls> {
  static const String _customPresetId = 'custom';
  static const String _moreAdvanced = 'advanced';
  static const String _moreAnalyze = 'analyze';
  static const String _moreGuide = 'guide';
  static const String _morePresetPrefix = 'preset:';

  late String _selectedFormat;
  double _quality = 85;
  final PresetService _presetService = PresetService();
  List<ConversionPreset> _presets = const [
    ConversionPreset(
      id: _customPresetId,
      name: '自定义',
      outputFormat: 'jpg',
      quality: 85,
    ),
  ];
  String _selectedPresetId = _customPresetId;

  @override
  void initState() {
    super.initState();
    final settings = context.read<ConversionProvider>().settings;
    _selectedFormat = settings.outputFormat;
    _quality = settings.quality.toDouble();
    _persistCurrentSettings();
    _loadPresets();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ConversionProvider>().settings;
    if (_selectedFormat != settings.outputFormat ||
        _quality.toInt() != settings.quality) {
      _selectedFormat = settings.outputFormat;
      _quality = settings.quality.toDouble();
    }

    final disabled = widget.isProcessing;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      opacity: disabled ? 0.72 : 1,
      duration: const Duration(milliseconds: 180),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '基础设置',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0F9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '预设：${_presetNameById(_selectedPresetId)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF365173),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 760) {
                    return Column(
                      children: [
                        _buildFormatSelector(disabled),
                        const SizedBox(height: 12),
                        _buildQualitySlider(disabled),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 270, child: _buildFormatSelector(disabled)),
                      const SizedBox(width: 18),
                      Expanded(child: _buildQualitySlider(disabled)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 760) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSecondaryButton(
                                onPressed: disabled ? null : widget.onPickFiles,
                                icon: Icons.add_photo_alternate_outlined,
                                label: '选择图片',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildSecondaryButton(
                                onPressed: disabled ? null : widget.onPickFolder,
                                icon: Icons.folder_open_outlined,
                                label: '选择文件夹',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildMoreMenuButton(disabled),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _buildPrimaryStartButton(
                            disabled: disabled,
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildSecondaryButton(
                            onPressed: disabled ? null : widget.onPickFiles,
                            icon: Icons.add_photo_alternate_outlined,
                            label: '选择图片',
                          ),
                          _buildSecondaryButton(
                            onPressed: disabled ? null : widget.onPickFolder,
                            icon: Icons.folder_open_outlined,
                            label: '选择文件夹',
                          ),
                          _buildMoreMenuButton(disabled),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: _buildPrimaryStartButton(
                          disabled: disabled,
                          colorScheme: colorScheme,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatSelector(bool disabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '输出格式',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: widget.onOpenFormatGuide,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.info_outline, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedFormat),
          initialValue: _selectedFormat,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.image_outlined),
          ),
          items: AppConfig.supportedFormats
              .map(
                (format) => DropdownMenuItem<String>(
                  value: format,
                  child: Text(format.toUpperCase()),
                ),
              )
              .toList(),
          onChanged: disabled
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selectedFormat = value);
                  _markAsCustomPreset();
                  context.read<ConversionProvider>().updateFormat(value);
                  _persistCurrentSettings();
                },
        ),
      ],
    );
  }

  Widget _buildQualitySlider(bool disabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '输出质量',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Container(
              width: 54,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE6ECF6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _quality.toInt().toString(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        Slider(
          min: 1,
          max: 100,
          divisions: 99,
          label: _quality.toInt().toString(),
          value: _quality,
          onChanged: disabled
              ? null
              : (value) {
                  setState(() => _quality = value);
                  _markAsCustomPreset();
                  context.read<ConversionProvider>().updateQuality(value.toInt());
                  _persistCurrentSettings();
                },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: TextStyle(fontSize: 12, color: Color(0xFF6F7D93))),
              Text(
                '100',
                style: TextStyle(fontSize: 12, color: Color(0xFF6F7D93)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF365173),
        minimumSize: const Size(0, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(
          color: onPressed == null
              ? const Color(0xFFCFD6E2)
              : const Color(0xFFB6C3D8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      ),
    );
  }

  Widget _buildPrimaryStartButton({
    required bool disabled,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: disabled
            ? null
            : () => widget.onStartConversion(_selectedFormat, _quality.toInt()),
        icon: disabled
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                ),
              )
            : const Icon(Icons.play_arrow_rounded),
        label: Text(disabled ? '处理中...' : '开始转换'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D3B66),
          foregroundColor: Colors.white,
          elevation: disabled ? 0 : 3,
          disabledBackgroundColor: const Color(0xFF9FAAB9),
          disabledForegroundColor: Colors.white,
          shadowColor: const Color(0xFF0D3B66).withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildMoreMenuButton(bool disabled) {
    if (disabled) {
      return _buildSecondaryButton(
        onPressed: null,
        icon: Icons.more_horiz_rounded,
        label: '更多',
      );
    }

    return PopupMenuButton<String>(
      onSelected: _handleMoreAction,
      offset: const Offset(0, 44),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      itemBuilder: (context) {
        final entries = <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: _moreAdvanced,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.tune_rounded, size: 18),
              title: Text('高级选项'),
            ),
          ),
          PopupMenuItem<String>(
            value: _moreAnalyze,
            enabled: widget.canAnalyze,
            child: const ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.psychology_rounded, size: 18),
              title: Text('智能分析'),
            ),
          ),
          const PopupMenuItem<String>(
            value: _moreGuide,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.help_outline_rounded, size: 18),
              title: Text('格式指南'),
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            enabled: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '快捷预设',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6F7D93),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ];

        for (final preset in _presets) {
          if (preset.id == _customPresetId) {
            continue;
          }
          entries.add(
            PopupMenuItem<String>(
              value: '$_morePresetPrefix${preset.id}',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _selectedPresetId == preset.id
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                ),
                title: Text(preset.name),
                subtitle: Text(
                  '${preset.outputFormat.toUpperCase()} · 质量 ${preset.quality}',
                ),
              ),
            ),
          );
        }
        return entries;
      },
      child: IgnorePointer(
        child: _buildSecondaryButton(
          onPressed: () {},
          icon: Icons.more_horiz_rounded,
          label: '更多',
        ),
      ),
    );
  }

  void _handleMoreAction(String value) {
    if (value == _moreAdvanced) {
      unawaited(_openAdvancedOptions());
      return;
    }
    if (value == _moreAnalyze) {
      widget.onAnalyze();
      return;
    }
    if (value == _moreGuide) {
      widget.onOpenFormatGuide();
      return;
    }
    if (value.startsWith(_morePresetPrefix)) {
      final presetId = value.substring(_morePresetPrefix.length);
      _applyPresetById(presetId);
    }
  }

  String _presetNameById(String presetId) {
    for (final preset in _presets) {
      if (preset.id == presetId) {
        return preset.name;
      }
    }
    return '自定义';
  }

  Future<void> _persistCurrentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_format', _selectedFormat);
    await prefs.setInt('last_quality', _quality.toInt());
  }

  Future<void> _loadPresets() async {
    final loaded = await _presetService.loadAllPresets();
    if (!mounted) {
      return;
    }

    final withCustom = <ConversionPreset>[
      const ConversionPreset(
        id: _customPresetId,
        name: '自定义',
        outputFormat: 'jpg',
        quality: 85,
      ),
      ...loaded,
    ];

    ConversionPreset? matchedPreset;
    for (final preset in loaded) {
      if (preset.outputFormat == _selectedFormat &&
          preset.quality == _quality.toInt()) {
        matchedPreset = preset;
        break;
      }
    }

    final lastPresetId = await _presetService.loadLastPresetId();
    final existsLast = withCustom.any((preset) => preset.id == lastPresetId);

    if (!mounted) {
      return;
    }
    setState(() {
      _presets = withCustom;
      if (existsLast && lastPresetId != null) {
        _selectedPresetId = lastPresetId;
      } else if (matchedPreset != null) {
        _selectedPresetId = matchedPreset.id;
      } else {
        _selectedPresetId = _customPresetId;
      }
    });
  }

  void _applyPresetById(String? presetId) {
    if (presetId == null) {
      return;
    }
    ConversionPreset? preset;
    for (final item in _presets) {
      if (item.id == presetId) {
        preset = item;
        break;
      }
    }
    if (preset == null) {
      return;
    }

    final selectedPreset = preset;
    setState(() => _selectedPresetId = selectedPreset.id);
    unawaited(_presetService.saveLastPresetId(selectedPreset.id));
    if (selectedPreset.id == _customPresetId) {
      return;
    }

    _selectedFormat = selectedPreset.outputFormat;
    _quality = selectedPreset.quality.toDouble();
    final provider = context.read<ConversionProvider>();
    provider.updateFormat(_selectedFormat);
    provider.updateQuality(_quality.toInt());
    _persistCurrentSettings();
  }

  void _markAsCustomPreset() {
    if (_selectedPresetId == _customPresetId) {
      return;
    }
    setState(() => _selectedPresetId = _customPresetId);
    unawaited(_presetService.saveLastPresetId(_customPresetId));
  }

  Future<void> _openAdvancedOptions() async {
    final provider = context.read<ConversionProvider>();
    final updated = await AdvancedOptionsDialog.show(
      context,
      initialSettings: provider.settings,
    );
    if (updated == null || !mounted) {
      return;
    }
    provider.updateSettings(updated);
    if (_selectedFormat != updated.outputFormat ||
        _quality.toInt() != updated.quality) {
      _selectedFormat = updated.outputFormat;
      _quality = updated.quality.toDouble();
      _markAsCustomPreset();
      _persistCurrentSettings();
    }
  }
}
