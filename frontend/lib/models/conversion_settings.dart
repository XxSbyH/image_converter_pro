class ConversionSettings {
  static const Object _unset = Object();

  const ConversionSettings({
    this.outputFormat = 'jpg',
    this.quality = 85,
    this.maxWidth,
    this.maxHeight,
    this.outputDirectory,
    this.enableWatermark = false,
    this.watermarkType = 'text',
    this.watermarkText = '',
    this.watermarkImagePath,
    this.watermarkOpacity = 30,
    this.watermarkPosition = 'bottom_right',
    this.watermarkFontSize = 24,
    this.stripMetadata = false,
    this.metadataAuthor,
    this.metadataCopyright,
    this.metadataComment,
  });

  final String outputFormat;
  final int quality;
  final int? maxWidth;
  final int? maxHeight;
  final String? outputDirectory;
  final bool enableWatermark;
  final String watermarkType;
  final String watermarkText;
  final String? watermarkImagePath;
  final int watermarkOpacity;
  final String watermarkPosition;
  final int watermarkFontSize;
  final bool stripMetadata;
  final String? metadataAuthor;
  final String? metadataCopyright;
  final String? metadataComment;

  ConversionSettings copyWith({
    String? outputFormat,
    int? quality,
    int? maxWidth,
    int? maxHeight,
    String? outputDirectory,
    bool? enableWatermark,
    String? watermarkType,
    String? watermarkText,
    Object? watermarkImagePath = _unset,
    int? watermarkOpacity,
    String? watermarkPosition,
    int? watermarkFontSize,
    bool? stripMetadata,
    Object? metadataAuthor = _unset,
    Object? metadataCopyright = _unset,
    Object? metadataComment = _unset,
  }) {
    return ConversionSettings(
      outputFormat: outputFormat ?? this.outputFormat,
      quality: quality ?? this.quality,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      enableWatermark: enableWatermark ?? this.enableWatermark,
      watermarkType: watermarkType ?? this.watermarkType,
      watermarkText: watermarkText ?? this.watermarkText,
      watermarkImagePath: identical(watermarkImagePath, _unset)
          ? this.watermarkImagePath
          : watermarkImagePath as String?,
      watermarkOpacity: watermarkOpacity ?? this.watermarkOpacity,
      watermarkPosition: watermarkPosition ?? this.watermarkPosition,
      watermarkFontSize: watermarkFontSize ?? this.watermarkFontSize,
      stripMetadata: stripMetadata ?? this.stripMetadata,
      metadataAuthor: identical(metadataAuthor, _unset)
          ? this.metadataAuthor
          : metadataAuthor as String?,
      metadataCopyright: identical(metadataCopyright, _unset)
          ? this.metadataCopyright
          : metadataCopyright as String?,
      metadataComment: identical(metadataComment, _unset)
          ? this.metadataComment
          : metadataComment as String?,
    );
  }
}
