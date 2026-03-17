import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../config/app_config.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.backendBaseUrl,
              connectTimeout: AppConfig.requestTimeout,
              receiveTimeout: AppConfig.requestTimeout,
              sendTimeout: AppConfig.requestTimeout,
            ),
          );

  final Dio _dio;

  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/health');
      return response.statusCode == 200 &&
          response.data?['status'] == 'healthy';
    } on DioException {
      return false;
    }
  }

  Future<Map<String, dynamic>> getSupportedFormats() async {
    try {
      return _withRetry<Map<String, dynamic>>(() async {
        final response = await _dio.get<Map<String, dynamic>>('/api/formats');
        return response.data ?? <String, dynamic>{};
      });
    } on DioException catch (e) {
      throw ApiException(_mapDioError(e));
    } catch (_) {
      throw const ApiException('获取支持格式失败');
    }
  }

  Future<Map<String, dynamic>> convertImage({
    required File file,
    required String format,
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    void Function(int sent, int total)? onSendProgress,
    int retryCount = 2,
  }) async {
    try {
      return _withRetry<Map<String, dynamic>>(() async {
        final inputExt = p.extension(file.path).toLowerCase();
        final outputFmt = format.toLowerCase();
        final isHeicToPng =
            (inputExt == '.heic' || inputExt == '.heif') && outputFmt == 'png';
        final receiveTimeout = isHeicToPng
            ? const Duration(seconds: 180)
            : AppConfig.requestTimeout;

        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path,
            filename: p.basename(file.path),
          ),
          'format': format,
          'quality': quality,
          ...?maxWidth != null ? {'max_width': maxWidth} : null,
          ...?maxHeight != null ? {'max_height': maxHeight} : null,
        });
        final response = await _dio.post<Map<String, dynamic>>(
          '/api/convert',
          data: formData,
          options: Options(receiveTimeout: receiveTimeout),
          onSendProgress: onSendProgress,
        );
        return response.data ?? <String, dynamic>{};
      }, retryCount: retryCount);
    } on DioException catch (e) {
      throw ApiException(_mapDioError(e));
    } catch (_) {
      throw const ApiException('图片转换失败');
    }
  }

  Future<Map<String, dynamic>> batchConvert({
    required List<File> files,
    required String format,
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    int concurrentLimit = 3,
    int retryCount = 2,
  }) async {
    final limit = math.max(1, concurrentLimit);
    final results = List<Map<String, dynamic>>.generate(
      files.length,
      (_) => {},
    );
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        if (nextIndex >= files.length) {
          return;
        }
        final current = nextIndex;
        nextIndex++;
        final file = files[current];

        try {
          final response = await convertImage(
            file: file,
            format: format,
            quality: quality,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            retryCount: retryCount,
          );
          results[current] = {
            'filename': p.basename(file.path),
            'success': true,
            ...response,
          };
        } catch (e) {
          results[current] = {
            'filename': p.basename(file.path),
            'success': false,
            'error': e.toString(),
          };
        }
      }
    }

    final workers = List<Future<void>>.generate(
      math.min(limit, files.length),
      (_) => worker(),
    );
    await Future.wait(workers);

    return {'results': results};
  }

  Future<T> _withRetry<T>(
    Future<T> Function() action, {
    int retryCount = 2,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await action();
      } on DioException {
        if (attempt >= retryCount) {
          rethrow;
        }
      }
      attempt++;
      await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
    }
  }

  String _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return '网络连接超时';
    }
    if (error.type == DioExceptionType.receiveTimeout) {
      return '服务器响应超时';
    }
    if (error.type == DioExceptionType.sendTimeout) {
      return '请求发送超时';
    }
    if (error.type == DioExceptionType.connectionError) {
      return '网络错误，请检查连接';
    }
    if (error.response != null) {
      final status = error.response?.statusCode ?? 0;
      final detail = error.response?.data;
      if (detail is Map<String, dynamic> && detail['detail'] != null) {
        return detail['detail'].toString();
      }
      if (status == 400) {
        return '请求参数错误';
      }
      if (status >= 500) {
        return '服务器内部错误';
      }
      return '请求失败: $status';
    }
    return '网络错误，请检查连接';
  }
}
