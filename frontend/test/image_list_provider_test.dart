import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:image_converter_pro/providers/image_list_provider.dart';

void main() {
  group('ImageListProvider', () {
    late Directory tempDir;
    late File fileA;
    late File fileB;
    late File fileC;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('image_provider_test_');
      fileA = File('${tempDir.path}\\a.jpg')..writeAsBytesSync(<int>[1, 2, 3]);
      fileB = File('${tempDir.path}\\b.jpg')..writeAsBytesSync(<int>[1, 2, 3]);
      fileC = File('${tempDir.path}\\c.jpg')..writeAsBytesSync(<int>[1, 2, 3]);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('reorderPending 仅重排 pending 项', () {
      final provider = ImageListProvider();
      provider.addImages(<File>[fileA, fileB, fileC]);
      provider.updateImageStatus(1, 'completed');

      provider.reorderPending(2, 0);

      final names = provider.images.map((item) => item.fileName).toList();
      expect(names, <String>['c.jpg', 'b.jpg', 'a.jpg']);
      expect(provider.images[1].status, 'completed');
    });

    test('retrySingleFailed 可以恢复失败项', () {
      final provider = ImageListProvider();
      provider.addImages(<File>[fileA]);
      final targetPath = provider.images.first.filePath;

      provider.updateImageStatusByPath(targetPath, 'failed', error: '处理失败');
      final ok = provider.retrySingleFailed(targetPath);

      expect(ok, isTrue);
      expect(provider.images.first.status, 'pending');
      expect(provider.images.first.errorMessage, isNull);
    });
  });
}
