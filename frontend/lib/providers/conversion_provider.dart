import 'package:flutter/foundation.dart';

import '../models/conversion_settings.dart';

class ConversionProvider extends ChangeNotifier {
  ConversionProvider({ConversionSettings? initialSettings})
    : _settings = initialSettings ?? const ConversionSettings();

  ConversionSettings _settings;
  bool _isProcessing = false;

  ConversionSettings get settings => _settings;
  bool get isProcessing => _isProcessing;

  void updateFormat(String format) {
    _settings = _settings.copyWith(outputFormat: format);
    notifyListeners();
  }

  void updateQuality(int quality) {
    _settings = _settings.copyWith(quality: quality);
    notifyListeners();
  }

  void updateOutputDirectory(String? outputDirectory) {
    _settings = _settings.copyWith(outputDirectory: outputDirectory);
    notifyListeners();
  }

  void setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }
}
