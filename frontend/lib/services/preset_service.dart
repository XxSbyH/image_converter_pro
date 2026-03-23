import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/conversion_preset.dart';

class PresetService {
  static const String _customPresetsKey = 'conversion_custom_presets_v1';
  static const String _lastPresetIdKey = 'conversion_last_preset_id_v1';

  static const List<ConversionPreset> builtInPresets = <ConversionPreset>[
    ConversionPreset(
      id: 'preset_web_light',
      name: '网页优化',
      outputFormat: 'jpg',
      quality: 80,
      isBuiltIn: true,
    ),
    ConversionPreset(
      id: 'preset_high_quality',
      name: '高质量',
      outputFormat: 'jpg',
      quality: 92,
      isBuiltIn: true,
    ),
    ConversionPreset(
      id: 'preset_small_size',
      name: '最小体积',
      outputFormat: 'webp',
      quality: 75,
      isBuiltIn: true,
    ),
    ConversionPreset(
      id: 'preset_text_clear',
      name: '文字清晰',
      outputFormat: 'png',
      quality: 100,
      isBuiltIn: true,
    ),
  ];

  Future<List<ConversionPreset>> loadAllPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customPresetsKey);
    if (raw == null || raw.isEmpty) {
      return <ConversionPreset>[...builtInPresets];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <ConversionPreset>[...builtInPresets];
      }
      final custom = decoded
          .whereType<Map>()
          .map(
            (item) => ConversionPreset.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
      return <ConversionPreset>[...builtInPresets, ...custom];
    } catch (_) {
      return <ConversionPreset>[...builtInPresets];
    }
  }

  Future<void> saveCustomPresets(List<ConversionPreset> presets) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = presets.where((item) => !item.isBuiltIn).toList();
    await prefs.setString(
      _customPresetsKey,
      jsonEncode(custom.map((item) => item.toJson()).toList()),
    );
  }

  Future<String?> loadLastPresetId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_lastPresetIdKey);
    if (id == null || id.isEmpty) {
      return null;
    }
    return id;
  }

  Future<void> saveLastPresetId(String presetId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPresetIdKey, presetId);
  }
}
