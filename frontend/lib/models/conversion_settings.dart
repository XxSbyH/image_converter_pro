class ConversionSettings {
  const ConversionSettings({
    this.outputFormat = 'jpg',
    this.quality = 85,
    this.maxWidth,
    this.maxHeight,
    this.outputDirectory,
  });

  final String outputFormat;
  final int quality;
  final int? maxWidth;
  final int? maxHeight;
  final String? outputDirectory;

  ConversionSettings copyWith({
    String? outputFormat,
    int? quality,
    int? maxWidth,
    int? maxHeight,
    String? outputDirectory,
  }) {
    return ConversionSettings(
      outputFormat: outputFormat ?? this.outputFormat,
      quality: quality ?? this.quality,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      outputDirectory: outputDirectory ?? this.outputDirectory,
    );
  }
}
