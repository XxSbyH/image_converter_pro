import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'api_service.dart';

class BackendManager {
  BackendManager._();

  static final BackendManager _instance = BackendManager._();
  factory BackendManager() => _instance;

  final ApiService _apiService = ApiService();

  Process? _backendProcess;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<bool> startBackend() async {
    if (await checkHealth()) {
      _isRunning = true;
      return true;
    }

    try {
      final exePath = await _resolveExecutablePath();

      _backendProcess = await Process.start(
        exePath,
        const [],
        workingDirectory: p.dirname(exePath),
        runInShell: false,
      );

      _backendProcess?.stdout
          .transform(utf8.decoder)
          .listen((data) => debugPrint('[backend] $data'));
      _backendProcess?.stderr
          .transform(utf8.decoder)
          .listen((data) => debugPrint('[backend-error] $data'));

      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (await checkHealth()) {
          _isRunning = true;
          return true;
        }
      }
    } catch (e) {
      debugPrint('后端启动失败: $e');
    }

    await stopBackend();
    return false;
  }

  Future<void> stopBackend() async {
    if (_backendProcess != null) {
      _backendProcess?.kill(ProcessSignal.sigterm);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      _backendProcess?.kill(ProcessSignal.sigkill);
    }
    _backendProcess = null;
    _isRunning = false;
  }

  Future<bool> checkHealth() async {
    return _apiService.checkHealth();
  }

  Future<String> _resolveExecutablePath() async {
    final runtimeExe = await _copyAssetToTemp();
    if (runtimeExe != null) {
      return runtimeExe;
    }

    final candidates = <String>[
      p.join(
        Directory.current.path,
        'data',
        'flutter_assets',
        'assets',
        'backend',
        'image_converter_service.exe',
      ),
      p.join(
        Directory.current.path,
        'assets',
        'backend',
        'image_converter_service.exe',
      ),
      p.join(Directory.current.path, 'image_converter_service.exe'),
      p.join(
        Directory.current.path,
        '..',
        '..',
        'backend',
        'dist',
        'image_converter_service.exe',
      ),
      p.join(
        Directory.current.path,
        '..',
        'backend',
        'dist',
        'image_converter_service.exe',
      ),
    ];

    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        return p.normalize(candidate);
      }
    }
    throw Exception('未找到后端可执行文件 image_converter_service.exe');
  }

  Future<String?> _copyAssetToTemp() async {
    try {
      final data = await rootBundle.load(
        'assets/backend/image_converter_service.exe',
      );
      final tempDir = await getTemporaryDirectory();
      final exePath = p.join(tempDir.path, 'image_converter_service.exe');
      await File(exePath).writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      return exePath;
    } catch (_) {
      return null;
    }
  }
}
