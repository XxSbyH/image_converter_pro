import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/image_file_model.dart';
import '../utils/file_size_estimator.dart';

class ImageListProvider extends ChangeNotifier {
  static const Object _unset = Object();
  final List<ImageFileModel> _images = [];
  String _estimateOutputFormat = 'jpg';
  int _estimateQuality = 85;

  UnmodifiableListView<ImageFileModel> get images =>
      UnmodifiableListView<ImageFileModel>(_images);

  bool get hasProcessing =>
      _images.any((image) => image.status == 'processing');

  ImageFileModel? getByPath(String filePath) {
    for (final image in _images) {
      if (image.filePath == filePath) {
        return image;
      }
    }
    return null;
  }

  void addImages(List<File> files) {
    final existingPaths = _images.map((e) => e.filePath).toSet();
    var hasAdded = false;
    for (final file in files) {
      if (!file.existsSync()) {
        continue;
      }
      if (existingPaths.contains(file.path)) {
        continue;
      }
      _images.add(
        _withEstimate(
          ImageFileModel(
            filePath: file.path,
            fileName: p.basename(file.path),
            fileSize: file.lengthSync(),
          ),
        ),
      );
      existingPaths.add(file.path);
      hasAdded = true;
    }
    if (hasAdded) {
      notifyListeners();
    }
  }

  void removeImage(int index) {
    if (index < 0 || index >= _images.length) {
      return;
    }
    _images.removeAt(index);
    notifyListeners();
  }

  bool removeImageByPath(String filePath, {bool allowProcessing = false}) {
    final index = _images.indexWhere((image) => image.filePath == filePath);
    if (index < 0) {
      return false;
    }
    if (!allowProcessing && _images[index].status == 'processing') {
      return false;
    }
    _images.removeAt(index);
    notifyListeners();
    return true;
  }

  void updateImageStatus(
    int index,
    String status, {
    Object? error = _unset,
    Object? progress = _unset,
    Object? compressionRatio = _unset,
    Object? outputFileSize = _unset,
  }) {
    if (index < 0 || index >= _images.length) {
      return;
    }
    final current = _images[index];
    var updated = current.copyWith(
      status: status,
      errorMessage: error,
      progress: progress,
      compressionRatio: compressionRatio,
      outputFileSize: outputFileSize,
    );
    if (updated.status == 'pending') {
      updated = _withEstimate(updated);
    }
    if (_isSameState(current, updated)) {
      return;
    }
    _images[index] = updated;
    notifyListeners();
  }

  void updateImageStatusByPath(
    String filePath,
    String status, {
    Object? error = _unset,
    Object? progress = _unset,
    Object? compressionRatio = _unset,
    Object? outputFileSize = _unset,
  }) {
    final index = _images.indexWhere((image) => image.filePath == filePath);
    if (index < 0) {
      return;
    }
    final current = _images[index];
    var updated = current.copyWith(
      status: status,
      errorMessage: error,
      progress: progress,
      compressionRatio: compressionRatio,
      outputFileSize: outputFileSize,
    );
    if (updated.status == 'pending') {
      updated = _withEstimate(updated);
    }
    if (_isSameState(current, updated)) {
      return;
    }
    _images[index] = updated;
    notifyListeners();
  }

  int clearFailed() {
    final before = _images.length;
    _images.removeWhere((image) => image.status == 'failed');
    final removed = before - _images.length;
    if (removed > 0) {
      notifyListeners();
    }
    return removed;
  }

  void retryFailed() {
    var updated = false;
    for (var i = 0; i < _images.length; i++) {
      if (_images[i].status != 'failed') {
        continue;
      }
      _images[i] = _withEstimate(
        _images[i].copyWith(
          status: 'pending',
          errorMessage: null,
          progress: null,
          compressionRatio: null,
          outputFileSize: null,
        ),
      );
      updated = true;
    }
    if (updated) {
      notifyListeners();
    }
  }

  void clearAll() {
    if (_images.isEmpty) {
      return;
    }
    _images.clear();
    notifyListeners();
  }

  int clearDeletable() {
    final before = _images.length;
    _images.removeWhere((image) => image.status != 'processing');
    final removed = before - _images.length;
    if (removed > 0) {
      notifyListeners();
    }
    return removed;
  }

  void updateEstimateConfig({
    required String outputFormat,
    required int quality,
  }) {
    final normalizedFormat = outputFormat.toLowerCase();
    final normalizedQuality = quality.clamp(1, 100).toInt();
    if (_estimateOutputFormat == normalizedFormat &&
        _estimateQuality == normalizedQuality) {
      return;
    }
    _estimateOutputFormat = normalizedFormat;
    _estimateQuality = normalizedQuality;

    var changed = false;
    for (var i = 0; i < _images.length; i++) {
      final image = _images[i];
      if (image.status != 'pending') {
        continue;
      }
      final updated = _withEstimate(image);
      if (_isSameState(image, updated)) {
        continue;
      }
      _images[i] = updated;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  bool _isSameState(ImageFileModel left, ImageFileModel right) {
    return left.filePath == right.filePath &&
        left.fileName == right.fileName &&
        left.fileSize == right.fileSize &&
        left.status == right.status &&
        left.errorMessage == right.errorMessage &&
        left.progress == right.progress &&
        left.compressionRatio == right.compressionRatio &&
        left.outputFileSize == right.outputFileSize &&
        left.estimatedOutputSize == right.estimatedOutputSize &&
        left.estimatedChangeRatio == right.estimatedChangeRatio;
  }

  ImageFileModel _withEstimate(ImageFileModel model) {
    final estimate = FileSizeEstimator.estimate(
      inputPath: model.filePath,
      originalBytes: model.fileSize,
      outputFormat: _estimateOutputFormat,
      quality: _estimateQuality,
    );
    return model.copyWith(
      estimatedOutputSize: estimate.estimatedBytes,
      estimatedChangeRatio: estimate.changeRatio,
    );
  }
}
