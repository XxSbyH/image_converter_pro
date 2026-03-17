import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/theme_config.dart';
import 'models/conversion_settings.dart';
import 'providers/conversion_provider.dart';
import 'providers/image_list_provider.dart';
import 'screens/loading_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedFormat = prefs.getString('last_format') ?? 'jpg';
  final savedQuality = (prefs.getInt('last_quality') ?? 85)
      .clamp(1, 100)
      .toInt();

  runApp(
    MyApp(
      initialSettings: ConversionSettings(
        outputFormat: savedFormat,
        quality: savedQuality,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialSettings});

  final ConversionSettings initialSettings;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ConversionProvider(initialSettings: initialSettings),
        ),
        ChangeNotifierProxyProvider<ConversionProvider, ImageListProvider>(
          create: (_) => ImageListProvider(),
          update: (_, conversion, imageList) {
            final provider = imageList ?? ImageListProvider();
            provider.updateEstimateConfig(
              outputFormat: conversion.settings.outputFormat,
              quality: conversion.settings.quality,
            );
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Image Converter Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoadingScreen(),
      ),
    );
  }
}
