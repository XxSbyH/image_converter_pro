import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/image_file_model.dart';
import '../providers/conversion_provider.dart';
import '../providers/image_list_provider.dart';
import '../screens/format_guide_screen.dart';
import '../services/api_service.dart';
import '../services/backend_manager.dart';
import '../widgets/conversion_controls.dart';
import '../widgets/drop_zone_widget.dart';
import '../widgets/format_suggestion_dialog.dart';
import '../widgets/image_list_item.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/quick_format_guide.dart';
import '../widgets/size_warning_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;
  DateTime? _processingStartedAt;
  int _processingTotal = 0;
  int _processingCompleted = 0;
  int _processingFailed = 0;
  final Map<String, double> _lastProgressValueByPath = {};
  final Map<String, DateTime> _lastProgressUpdateByPath = {};

  static const int _maxFileSizeBytes = 50 * 1024 * 1024;
  static const Duration _progressUpdateInterval = Duration(milliseconds: 180);
  static const double _progressMinDelta = 0.02;

  static const Set<String> _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  };

  @override
  void dispose() {
    BackendManager().stopBackend();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = context.watch<ImageListProvider>();
    final images = imageProvider.images;
    final failedCount = images.where((item) => item.status == 'failed').length;
    final etaSeconds = _estimateRemainingSeconds();

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyO, control: true):
            _PickFilesIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _StartConversionIntent(),
        SingleActivator(LogicalKeyboardKey.enter, control: true):
            _StartConversionIntent(),
        SingleActivator(LogicalKeyboardKey.keyL, control: true):
            _ClearListIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _PickFilesIntent: CallbackAction<_PickFilesIntent>(
            onInvoke: (_) => _pickFiles(),
          ),
          _StartConversionIntent: CallbackAction<_StartConversionIntent>(
            onInvoke: (_) => _startConversionWithCurrentSettings(),
          ),
          _ClearListIntent: CallbackAction<_ClearListIntent>(
            onInvoke: (_) => _clearAllWithConfirm(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(AppConfig.appName),
              actions: [
                IconButton(
                  tooltip: '格式指南',
                  icon: const Icon(Icons.help_outline_rounded),
                  onPressed: _openFormatGuide,
                ),
              ],
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF3F6FC), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_isProcessing)
                        ProgressIndicatorWidget(
                          total: _processingTotal,
                          completed: _processingCompleted,
                          failed: _processingFailed,
                          etaSeconds: etaSeconds,
                        ),
                      if (_isProcessing) const SizedBox(height: 10),
                      if (images.isNotEmpty)
                        _buildListToolbar(failedCount: failedCount),
                      if (images.isNotEmpty) const SizedBox(height: 10),
                      Expanded(
                        child: images.isEmpty
                            ? _buildEmptyState()
                            : DropZoneWidget(
                                onEntriesDropped: _handleDroppedEntries,
                                showHint: false,
                                minHeight: 320,
                                child: ListView.builder(
                                  itemCount: images.length,
                                  itemBuilder: (context, index) {
                                    final imageFile = images[index];
                                    return ImageListItem(
                                      imageFile: imageFile,
                                      onDelete: () {
                                        if (imageFile.status == 'processing') {
                                          _showSnackBar(
                                            '该文件正在处理中，无法删除',
                                            isError: true,
                                          );
                                          return;
                                        }
                                        final removed = context
                                            .read<ImageListProvider>()
                                            .removeImageByPath(
                                              imageFile.filePath,
                                            );
                                        if (!removed) {
                                          _showSnackBar(
                                            '删除失败，请重试',
                                            isError: true,
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                      ),
                      if (images.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ConversionControls(
                          isProcessing: _isProcessing,
                          onPickFiles: _pickFiles,
                          onPickFolder: _pickFolder,
                          onStartConversion: _startConversion,
                          onOpenFormatGuide: _showQuickFormatGuide,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListToolbar({required int failedCount}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '批量操作',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            OutlinedButton.icon(
              onPressed: _isProcessing || failedCount == 0
                  ? null
                  : _retryFailedItems,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试失败项'),
            ),
            OutlinedButton.icon(
              onPressed: failedCount == 0 ? null : _clearFailedWithConfirm,
              icon: const Icon(Icons.cleaning_services_outlined),
              label: const Text('清除失败项'),
            ),
            TextButton.icon(
              onPressed: _clearAllWithConfirm,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('清空全部'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = math.min(1020.0, constraints.maxWidth);
        final reservedForActions = 210.0;
        final zoneHeight = math.max(
          300.0,
          math.min(500.0, constraints.maxHeight - reservedForActions),
        );

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: zoneHeight,
                  width: double.infinity,
                  child: DropZoneWidget(
                    onEntriesDropped: _handleDroppedEntries,
                    minHeight: zoneHeight,
                    title: '拖拽图片或文件到这里开始转换',
                    subtitle: '支持 JPG、PNG、WebP、HEIC',
                    description: '批量处理 · 快速转换 · 高质量输出',
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('选择图片'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickFolder,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('选择文件夹'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '提示：选择文件夹时，仅处理该文件夹内的图片',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF74839A),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: _allowedExtensions.toList(),
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final paths = result.paths.whereType<String>().toList();
    await _addEntries(paths);
  }

  Future<void> _pickFolder() async {
    final folderPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择图片文件夹',
    );
    if (folderPath == null || folderPath.isEmpty) {
      return;
    }
    _showSnackBar('正在扫描文件夹...');
    await _addEntries([folderPath], fromFolderPicker: true);
  }

  Future<void> _handleDroppedEntries(List<String> paths) async {
    await _addEntries(paths);
  }

  Future<void> _addEntries(
    List<String> paths, {
    bool fromFolderPicker = false,
  }) async {
    final imageProvider = context.read<ImageListProvider>();
    final beforeCount = imageProvider.images.length;
    final filesToAdd = <File>[];
    var skippedUnreadable = 0;
    var scannedFolders = 0;
    var unsupportedCount = 0;

    for (final rawPath in paths) {
      final path = rawPath.trim();
      if (path.isEmpty) {
        continue;
      }
      final file = File(path);
      if (file.existsSync()) {
        if (_isSupportedImagePath(path)) {
          filesToAdd.add(file);
        } else {
          unsupportedCount++;
        }
        continue;
      }

      final directory = Directory(path);
      if (!directory.existsSync()) {
        continue;
      }
      scannedFolders++;
      final scanResult = await _scanFolderImages(directory.path);
      filesToAdd.addAll(scanResult.files);
      skippedUnreadable += scanResult.skipped;
    }

    if (filesToAdd.isEmpty) {
      if (unsupportedCount > 0 && scannedFolders == 0 && !fromFolderPicker) {
        _showSnackBar('不支持该文件格式，仅支持 JPG/PNG/WebP/HEIC', isError: true);
        return;
      }
      if (scannedFolders > 0 || fromFolderPicker) {
        _showSnackBar('该文件夹中未找到支持的图片格式', isError: true);
      } else {
        _showSnackBar('未检测到可用图片文件', isError: true);
      }
      return;
    }

    if (filesToAdd.length > 100) {
      final confirm = await _confirmAction(
        title: '检测到大量图片',
        content: '检测到 ${filesToAdd.length} 张图片，是否全部添加？',
        confirmText: '全部添加',
      );
      if (!confirm) {
        return;
      }
    }

    await _maybeSuggestFormatForHeic(filesToAdd);

    imageProvider.addImages(filesToAdd);
    final addedCount = imageProvider.images.length - beforeCount;
    if (addedCount <= 0) {
      _showSnackBar('文件已存在于列表中，无新增图片');
      return;
    }

    if (scannedFolders > 0 || fromFolderPicker) {
      if (skippedUnreadable > 0) {
        _showSnackBar('已添加 $addedCount 张，跳过 $skippedUnreadable 张无法读取的文件');
      } else {
        _showSnackBar('已从文件夹添加 $addedCount 张图片');
      }
      return;
    }
    if (unsupportedCount > 0) {
      _showSnackBar('已添加 $addedCount 张图片，忽略 $unsupportedCount 个不支持的文件');
      return;
    }
    _showSnackBar('已添加 $addedCount 张图片');
  }

  Future<({List<File> files, int skipped})> _scanFolderImages(
    String folderPath,
  ) async {
    final files = <File>[];
    var skipped = 0;

    try {
      await for (final entity in Directory(
        folderPath,
      ).list(recursive: false, followLinks: false)) {
        if (entity is! File) {
          continue;
        }
        if (!_isSupportedImagePath(entity.path)) {
          continue;
        }
        try {
          if (await entity.exists()) {
            await entity.length();
            files.add(entity);
          } else {
            skipped++;
          }
        } catch (_) {
          skipped++;
        }
      }
    } catch (_) {
      return (files: <File>[], skipped: 0);
    }

    return (files: files, skipped: skipped);
  }

  bool _isSupportedImagePath(String filePath) {
    final ext = p.extension(filePath).toLowerCase().replaceFirst('.', '');
    return _allowedExtensions.contains(ext);
  }

  Future<void> _startConversionWithCurrentSettings({
    List<int>? targetIndexes,
  }) async {
    final settings = context.read<ConversionProvider>().settings;
    await _startConversion(
      settings.outputFormat,
      settings.quality,
      targetIndexes: targetIndexes,
    );
  }

  Future<void> _startConversion(
    String format,
    int quality, {
    List<int>? targetIndexes,
  }) async {
    if (_isProcessing) {
      return;
    }

    final imageProvider = context.read<ImageListProvider>();
    final allImages = imageProvider.images.toList();
    if (allImages.isEmpty) {
      _showSnackBar('请先添加要转换的图片', isError: true);
      return;
    }

    final targetPaths = targetIndexes == null
        ? allImages.map((image) => image.filePath).toList()
        : targetIndexes
              .where((index) => index >= 0 && index < allImages.length)
              .map((index) => allImages[index].filePath)
              .toList();
    if (targetPaths.isEmpty) {
      _showSnackBar('没有可处理的文件', isError: true);
      return;
    }

    final targetImages = targetPaths
        .map(imageProvider.getByPath)
        .whereType<ImageFileModel>()
        .toList();
    if (targetImages.isEmpty) {
      _showSnackBar('没有可处理的文件', isError: true);
      return;
    }

    var selectedFormat = format.toLowerCase();
    var selectedQuality = quality.clamp(1, 100).toInt();
    final warningDecision = await _handleSizeWarningBeforeConversion(
      targetImages: targetImages,
      currentFormat: selectedFormat,
      currentQuality: selectedQuality,
    );
    if (warningDecision == null) {
      return;
    }
    selectedFormat = warningDecision.$1;
    selectedQuality = warningDecision.$2;

    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择输出目录',
    );
    if (outputDir == null || outputDir.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }

    final conversionProvider = context.read<ConversionProvider>();
    setState(() {
      _isProcessing = true;
      _processingStartedAt = DateTime.now();
      _processingTotal = targetPaths.length;
      _processingCompleted = 0;
      _processingFailed = 0;
    });

    conversionProvider
      ..setProcessing(true)
      ..updateFormat(selectedFormat)
      ..updateQuality(selectedQuality)
      ..updateOutputDirectory(outputDir);

    _showSnackBar('开始处理 ${targetPaths.length} 张图片...');

    var successCount = 0;
    var failedCount = 0;
    var totalOriginalBytes = 0;
    var totalOutputBytes = 0;
    var hasFatalError = false;

    _lastProgressValueByPath.clear();
    _lastProgressUpdateByPath.clear();

    try {
      for (final filePath in targetPaths) {
        final image = imageProvider.getByPath(filePath);
        if (image == null) {
          if (!mounted) {
            break;
          }
          setState(() {
            _processingTotal = math.max(0, _processingTotal - 1);
          });
          continue;
        }

        imageProvider.updateImageStatusByPath(
          filePath,
          'processing',
          error: null,
          progress: 0.0,
          compressionRatio: null,
          outputFileSize: null,
        );

        try {
          final sourceFile = File(image.filePath);
          await _validateSourceFile(sourceFile);

          final response = await _apiService.convertImage(
            file: sourceFile,
            format: selectedFormat,
            quality: selectedQuality,
            onSendProgress: (sent, total) {
              final rawProgress = total <= 0 ? 0.0 : sent / total;
              _updateProgressThrottled(
                imageProvider,
                filePath,
                rawProgress.clamp(0.0, 1.0).toDouble(),
              );
            },
          );

          final outputBase64 = response['output_base64']?.toString();
          if (outputBase64 == null || outputBase64.isEmpty) {
            throw const ApiException('后端未返回有效图片数据');
          }

          final outputBytes = base64Decode(outputBase64);
          final outputPath = p.join(
            outputDir,
            '${p.basenameWithoutExtension(image.fileName)}.${selectedFormat.toLowerCase()}',
          );
          await File(outputPath).writeAsBytes(outputBytes, flush: true);

          final originalSize =
              _parseSize(response['original_size']) ?? image.fileSize;
          final outputSize =
              _parseSize(response['compressed_size']) ?? outputBytes.length;
          imageProvider.updateImageStatusByPath(
            filePath,
            'completed',
            error: null,
            progress: 1.0,
            compressionRatio: response['compression_ratio']?.toString(),
            outputFileSize: outputSize,
          );

          successCount++;
          totalOriginalBytes += originalSize;
          totalOutputBytes += outputSize;
        } catch (error) {
          imageProvider.updateImageStatusByPath(
            filePath,
            'failed',
            error: _friendlyError(error),
            progress: null,
            compressionRatio: null,
            outputFileSize: null,
          );
          failedCount++;
        } finally {
          _clearProgressThrottle(filePath);
        }

        if (!mounted) {
          break;
        }
        setState(() {
          _processingCompleted = successCount;
          _processingFailed = failedCount;
        });

        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    } catch (error, stackTrace) {
      hasFatalError = true;
      debugPrint('批量转换出现未捕获异常: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _lastProgressValueByPath.clear();
      _lastProgressUpdateByPath.clear();
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      conversionProvider.setProcessing(false);
    }

    if (!mounted) {
      return;
    }
    if (hasFatalError) {
      _showSnackBar('转换过程中出现异常，已停止后续任务', isError: true);
      return;
    }

    final storageDelta = totalOriginalBytes - totalOutputBytes;
    if (failedCount == 0) {
      final message =
          '转换完成！成功 $successCount 张，${_buildStorageSummary(storageDelta)}';
      _showResultSnackBar(message, outputDir);
      return;
    }
    if (successCount > 0) {
      final message =
          '完成 $successCount 张，失败 $failedCount 张，${_buildStorageSummary(storageDelta)}';
      _showResultSnackBar(message, outputDir);
      return;
    }
    _showSnackBar('转换失败，请检查错误原因后重试', isError: true);
  }

  Future<void> _maybeSuggestFormatForHeic(List<File> files) async {
    final heicCount = files.where((file) => _isHeicPath(file.path)).length;
    if (heicCount == 0) {
      return;
    }

    final conversionProvider = context.read<ConversionProvider>();
    final currentFormat = conversionProvider.settings.outputFormat
        .toLowerCase();
    if (currentFormat != 'png') {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final disabled = prefs.getBool('heic_format_suggestion_disabled') ?? false;
    final preferred = (prefs.getString('preferred_heic_output_format') ?? '')
        .toLowerCase();
    if (disabled && AppConfig.supportedFormats.contains(preferred)) {
      if (preferred != currentFormat) {
        conversionProvider.updateFormat(preferred);
        context.read<ImageListProvider>().updateEstimateConfig(
          outputFormat: preferred,
          quality: conversionProvider.settings.quality,
        );
        _showSnackBar('检测到 HEIC，已按偏好自动切换为 ${preferred.toUpperCase()}');
      }
      return;
    }

    if (!mounted) {
      return;
    }
    final decision = await FormatSuggestionDialog.show(
      context,
      heicCount: heicCount,
    );
    if (decision == null) {
      return;
    }

    final selected = decision.selectedFormat.toLowerCase();
    if (AppConfig.supportedFormats.contains(selected) &&
        selected != currentFormat) {
      conversionProvider.updateFormat(selected);
      context.read<ImageListProvider>().updateEstimateConfig(
        outputFormat: selected,
        quality: conversionProvider.settings.quality,
      );
      _showSnackBar('已将输出格式切换为 ${selected.toUpperCase()}');
    }

    if (decision.neverShowAgain) {
      await prefs.setBool('heic_format_suggestion_disabled', true);
      await prefs.setString('preferred_heic_output_format', selected);
    }
  }

  Future<(String, int)?> _handleSizeWarningBeforeConversion({
    required List<ImageFileModel> targetImages,
    required String currentFormat,
    required int currentQuality,
  }) async {
    final format = currentFormat.toLowerCase();
    if (format != 'png' && format != 'webp') {
      return (currentFormat, currentQuality);
    }

    final heicFiles = targetImages
        .where((item) => _isHeicPath(item.filePath))
        .toList();
    if (heicFiles.isEmpty) {
      return (currentFormat, currentQuality);
    }

    final riskyFiles = heicFiles.where((item) {
      final ratio = item.estimatedChangeRatio ?? 1.0;
      return ratio > 3.0;
    }).toList();
    if (riskyFiles.isEmpty) {
      return (currentFormat, currentQuality);
    }

    final totalOriginalBytes = riskyFiles.fold<int>(
      0,
      (sum, item) => sum + item.fileSize,
    );
    final totalEstimatedBytes = riskyFiles.fold<int>(
      0,
      (sum, item) => sum + (item.estimatedOutputSize ?? item.fileSize),
    );

    if (!mounted) {
      return null;
    }

    final decision = await SizeWarningDialog.show(
      context,
      riskyFiles: riskyFiles,
      totalOriginalBytes: totalOriginalBytes,
      totalEstimatedBytes: totalEstimatedBytes,
      sourceFormatLabel: 'HEIC/HEIF',
      currentFormat: currentFormat,
      currentQuality: currentQuality,
    );
    if (decision == null || decision.action == SizeWarningAction.cancel) {
      return null;
    }

    final conversionProvider = context.read<ConversionProvider>();
    switch (decision.action) {
      case SizeWarningAction.useJpg:
        conversionProvider
          ..updateFormat('jpg')
          ..updateQuality(85);
        context.read<ImageListProvider>().updateEstimateConfig(
          outputFormat: 'jpg',
          quality: 85,
        );
        return ('jpg', 85);
      case SizeWarningAction.lowerQuality:
        final lowered = (decision.suggestedQuality ?? 80).clamp(1, 100).toInt();
        conversionProvider.updateQuality(lowered);
        context.read<ImageListProvider>().updateEstimateConfig(
          outputFormat: currentFormat,
          quality: lowered,
        );
        return (currentFormat, lowered);
      case SizeWarningAction.continueCurrent:
        return (currentFormat, currentQuality);
      case SizeWarningAction.cancel:
        return null;
    }
  }

  bool _isHeicPath(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.heic' || ext == '.heif';
  }

  void _openFormatGuide() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FormatGuideScreen()));
  }

  Future<void> _showQuickFormatGuide() async {
    await QuickFormatGuideDialog.show(context);
  }

  void _updateProgressThrottled(
    ImageListProvider imageProvider,
    String filePath,
    double progress,
  ) {
    var normalized = progress.clamp(0.0, 1.0).toDouble();
    if (normalized >= 1.0) {
      normalized = 0.95;
    }

    final now = DateTime.now();
    final lastValue = _lastProgressValueByPath[filePath];
    final lastTime = _lastProgressUpdateByPath[filePath];
    final hasMeaningfulDelta =
        lastValue == null ||
        (normalized - lastValue).abs() >= _progressMinDelta;
    final isIntervalReached =
        lastTime == null || now.difference(lastTime) >= _progressUpdateInterval;

    if (!hasMeaningfulDelta && !isIntervalReached && normalized < 0.95) {
      return;
    }

    _lastProgressValueByPath[filePath] = normalized;
    _lastProgressUpdateByPath[filePath] = now;
    imageProvider.updateImageStatusByPath(
      filePath,
      'processing',
      progress: normalized,
    );
  }

  void _clearProgressThrottle(String filePath) {
    _lastProgressValueByPath.remove(filePath);
    _lastProgressUpdateByPath.remove(filePath);
  }

  int? _estimateRemainingSeconds() {
    if (!_isProcessing || _processingStartedAt == null) {
      return null;
    }
    final processed = _processingCompleted + _processingFailed;
    if (processed <= 0) {
      return null;
    }
    final remaining = _processingTotal - processed;
    if (remaining <= 0) {
      return 0;
    }
    final elapsedMs = DateTime.now()
        .difference(_processingStartedAt!)
        .inMilliseconds;
    final avgPerItemMs = elapsedMs / processed;
    final etaMs = avgPerItemMs * remaining;
    return (etaMs / 1000).ceil();
  }

  Future<void> _validateSourceFile(File sourceFile) async {
    if (!sourceFile.existsSync()) {
      throw const ApiException('文件不存在或无法读取');
    }

    final ext = p
        .extension(sourceFile.path)
        .toLowerCase()
        .replaceFirst('.', '');
    if (!_allowedExtensions.contains(ext)) {
      throw const ApiException('不支持该格式');
    }

    final fileSize = await sourceFile.length();
    if (fileSize > _maxFileSizeBytes) {
      throw const ApiException('文件过大');
    }

    if (!await _canReadFile(sourceFile)) {
      throw const ApiException('文件无法读取');
    }
  }

  Future<bool> _canReadFile(File file) async {
    try {
      await file.openRead(0, 1).drain<void>();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _clearAllWithConfirm() async {
    final provider = context.read<ImageListProvider>();
    if (!provider.hasProcessing) {
      final shouldClear = await _confirmAction(
        title: '清空全部文件',
        content: '确定要清空当前列表中的所有文件吗？',
        confirmText: '清空',
      );
      if (!shouldClear || !mounted) {
        return;
      }
      provider.clearAll();
      return;
    }

    final shouldClearOthers = await _confirmAction(
      title: '存在正在处理的文件',
      content: '正在处理中的文件无法删除，是否删除其他文件？',
      confirmText: '删除其他文件',
    );
    if (!shouldClearOthers || !mounted) {
      return;
    }
    final removed = provider.clearDeletable();
    if (removed > 0) {
      _showSnackBar('已删除 $removed 个非处理中项');
    } else {
      _showSnackBar('没有可删除的文件');
    }
  }

  Future<void> _clearFailedWithConfirm() async {
    final shouldClear = await _confirmAction(
      title: '清除失败项',
      content: '仅删除处理失败的文件，保留待处理和已完成项。',
      confirmText: '清除',
    );
    if (!shouldClear || !mounted) {
      return;
    }
    final removed = context.read<ImageListProvider>().clearFailed();
    if (removed > 0) {
      _showSnackBar('已清除 $removed 个失败项');
    } else {
      _showSnackBar('没有失败项可清除');
    }
  }

  Future<void> _retryFailedItems() async {
    if (_isProcessing) {
      return;
    }
    final images = context.read<ImageListProvider>().images;
    final failedIndexes = <int>[];
    for (var i = 0; i < images.length; i++) {
      if (images[i].status == 'failed') {
        failedIndexes.add(i);
      }
    }
    if (failedIndexes.isEmpty) {
      _showSnackBar('没有可重试的失败项', isError: true);
      return;
    }
    await _startConversionWithCurrentSettings(targetIndexes: failedIndexes);
  }

  String _friendlyError(Object error) {
    final message = switch (error) {
      ApiException apiException => apiException.message,
      _ => error.toString(),
    };
    final lower = message.toLowerCase();

    if (lower.contains('receive timeout')) {
      return '处理超时 - 文件可能过大，建议降低质量或分批处理';
    }
    if (lower.contains('connect timeout')) {
      return '连接超时 - 请检查网络连接或稍后重试';
    }
    if (lower.contains('send timeout')) {
      return '发送超时 - 请检查网络状态后重试';
    }
    if (lower.contains('connection refused') ||
        lower.contains('actively refused')) {
      return '服务未启动 - 请重启应用后重试';
    }
    if (lower.contains('socketexception')) {
      return '网络连接失败 - 请检查网络或后端服务状态';
    }
    if (message.contains('超时')) {
      return '处理超时 - 文件可能较大，建议降低质量或分批处理';
    }
    if (message.contains('网络错误') || message.contains('连接失败')) {
      return '网络连接失败 - 请检查网络或后端服务状态';
    }
    if (message.contains('文件不存在') ||
        message.contains('无法读取') ||
        lower.contains('filesystemexception') ||
        lower.contains('permission denied') ||
        lower.contains('no such file or directory')) {
      return '文件访问失败 - 请检查文件是否被占用、移动或无权限';
    }
    if (message.contains('不支持') || lower.contains('unsupported image format')) {
      return '格式不支持 - 请选择 JPG、PNG、WebP 或 HEIC 格式';
    }
    if (lower.contains('image decode error') ||
        lower.contains('unidentifiedimageerror') ||
        lower.contains('cannot identify image file')) {
      return '图片损坏 - 该图片可能已损坏，请重新导出后重试';
    }
    if (message.contains('文件过大') ||
        lower.contains('file too large') ||
        lower.contains('413')) {
      return '文件过大 - 单文件需小于 50MB，请压缩后重试';
    }
    if (message.contains('请求参数错误') || lower.contains('http 400')) {
      return '参数错误 - 请检查输出格式和质量设置';
    }
    if (message.contains('服务器内部错误') || lower.contains('http 500')) {
      return '服务器错误 - 服务处理异常，请稍后重试';
    }

    return '处理失败 - 请重试或联系支持';
  }

  String _buildStorageSummary(int storageDelta) {
    if (storageDelta > 0) {
      return '总节省 ${_formatBytes(storageDelta)}';
    }
    if (storageDelta < 0) {
      return '体积增加 ${_formatBytes(storageDelta.abs())}';
    }
    return '总体积无变化';
  }

  Future<bool> _confirmAction({
    required String title,
    required String content,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  int? _parseSize(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
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

  Future<void> _openOutputDirectory(String outputDir) async {
    if (!Directory(outputDir).existsSync()) {
      return;
    }
    await Process.run('explorer.exe', [outputDir]);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFC62828)
            : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showResultSnackBar(String message, String outputDir) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2E7D32),
        action: SnackBarAction(
          label: '打开文件夹',
          onPressed: () => _openOutputDirectory(outputDir),
        ),
      ),
    );
  }
}

class _PickFilesIntent extends Intent {
  const _PickFilesIntent();
}

class _StartConversionIntent extends Intent {
  const _StartConversionIntent();
}

class _ClearListIntent extends Intent {
  const _ClearListIntent();
}
