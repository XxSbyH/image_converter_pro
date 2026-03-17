import 'dart:math' as math;

class FileSizeEstimate {
  const FileSizeEstimate({
    required this.estimatedBytes,
    required this.changeRatio,
  });

  final int estimatedBytes;
  final double changeRatio;
}

class FileSizeEstimator {
  const FileSizeEstimator._();

  static FileSizeEstimate estimate({
    required String inputPath,
    required int originalBytes,
    required String outputFormat,
    required int quality,
  }) {
    final safeBytes = math.max(1, originalBytes);
    final ext = _extension(inputPath);
    final target = outputFormat.toLowerCase();
    final q = quality.clamp(1, 100);

    double factor = 1.0;

    if (ext == 'heic' || ext == 'heif') {
      if (target == 'png') {
        factor = 7.5;
      } else if (target == 'jpg' || target == 'jpeg') {
        if (q >= 90) {
          factor = 3.8;
        } else if (q >= 80) {
          factor = 2.6;
        } else if (q >= 60) {
          factor = 1.9;
        } else {
          factor = 1.5;
        }
      } else if (target == 'webp') {
        factor = q >= 90 ? 1.9 : 1.6;
      }
    } else if (ext == 'jpg' || ext == 'jpeg') {
      if (target == 'png') {
        factor = 2.4;
      } else if (target == 'webp') {
        factor = q >= 90 ? 0.95 : 0.75;
      } else if (target == 'jpg' || target == 'jpeg') {
        factor = q >= 90 ? 1.05 : 0.9;
      }
    } else if (ext == 'png') {
      if (target == 'jpg' || target == 'jpeg') {
        factor = q >= 90 ? 0.55 : 0.4;
      } else if (target == 'webp') {
        factor = q >= 90 ? 0.7 : 0.5;
      } else if (target == 'png') {
        factor = 1.0;
      }
    } else if (ext == 'webp') {
      if (target == 'jpg' || target == 'jpeg') {
        factor = q >= 90 ? 1.25 : 1.05;
      } else if (target == 'png') {
        factor = 2.0;
      } else if (target == 'webp') {
        factor = q >= 90 ? 1.0 : 0.88;
      }
    } else {
      if (target == 'png') {
        factor = 1.8;
      } else if (target == 'webp') {
        factor = 0.9;
      } else {
        factor = 1.0;
      }
    }

    final estimated = math.max(1, (safeBytes * factor).round());
    final ratio = estimated / safeBytes;
    return FileSizeEstimate(estimatedBytes: estimated, changeRatio: ratio);
  }

  static String _extension(String path) {
    final lower = path.toLowerCase();
    final dot = lower.lastIndexOf('.');
    if (dot < 0 || dot >= lower.length - 1) {
      return '';
    }
    return lower.substring(dot + 1);
  }
}
