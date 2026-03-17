import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:image_converter_pro/config/theme_config.dart';
import 'package:image_converter_pro/models/conversion_settings.dart';
import 'package:image_converter_pro/providers/conversion_provider.dart';
import 'package:image_converter_pro/providers/image_list_provider.dart';
import 'package:image_converter_pro/screens/home_screen.dart';

void main() {
  testWidgets('首页基础元素显示正常', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ImageListProvider()),
          ChangeNotifierProvider(
            create: (_) =>
                ConversionProvider(initialSettings: const ConversionSettings()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    expect(find.text('Image Converter Pro'), findsOneWidget);
    expect(find.text('拖拽图片或文件到这里开始转换'), findsOneWidget);
    expect(find.text('选择图片'), findsOneWidget);
    expect(find.text('选择文件夹'), findsOneWidget);
    expect(find.text('开始转换'), findsNothing);
  });
}
