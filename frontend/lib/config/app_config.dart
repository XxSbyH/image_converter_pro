class AppConfig {
  const AppConfig._();

  static const String appName = 'Image Converter Pro';
  static const String backendBaseUrl = 'http://127.0.0.1:8000';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const List<String> supportedFormats = ['jpg', 'png', 'webp'];
}
