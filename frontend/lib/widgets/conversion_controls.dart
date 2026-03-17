import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../providers/conversion_provider.dart';

class ConversionControls extends StatefulWidget {
  const ConversionControls({
    super.key,
    required this.isProcessing,
    required this.onPickFiles,
    required this.onPickFolder,
    required this.onStartConversion,
    required this.onOpenFormatGuide,
  });

  final bool isProcessing;
  final VoidCallback onPickFiles;
  final VoidCallback onPickFolder;
  final void Function(String format, int quality) onStartConversion;
  final VoidCallback onOpenFormatGuide;

  @override
  State<ConversionControls> createState() => _ConversionControlsState();
}

class _ConversionControlsState extends State<ConversionControls> {
  late String _selectedFormat;
  double _quality = 85;

  @override
  void initState() {
    super.initState();
    final settings = context.read<ConversionProvider>().settings;
    _selectedFormat = settings.outputFormat;
    _quality = settings.quality.toDouble();
    _persistCurrentSettings();
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
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 12,
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: Column(
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
                              context.read<ConversionProvider>().updateFormat(
                                value,
                              );
                              _persistCurrentSettings();
                            },
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '输出质量',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Container(
                          width: 54,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                              context.read<ConversionProvider>().updateQuality(
                                value.toInt(),
                              );
                              _persistCurrentSettings();
                            },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '1',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6F7D93),
                            ),
                          ),
                          Text(
                            '100',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6F7D93),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: disabled ? null : widget.onPickFiles,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('选择文件'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF365173),
                  side: BorderSide(
                    color: disabled
                        ? const Color(0xFFCFD6E2)
                        : const Color(0xFFB6C3D8),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: disabled ? null : widget.onPickFolder,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('选择文件夹'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF365173),
                  side: BorderSide(
                    color: disabled
                        ? const Color(0xFFCFD6E2)
                        : const Color(0xFFB6C3D8),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: disabled
                    ? null
                    : () => widget.onStartConversion(
                        _selectedFormat,
                        _quality.toInt(),
                      ),
                icon: disabled
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _persistCurrentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_format', _selectedFormat);
    await prefs.setInt('last_quality', _quality.toInt());
  }
}
