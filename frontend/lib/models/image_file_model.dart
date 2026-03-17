class ImageFileModel {
  static const Object _unset = Object();

  const ImageFileModel({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    this.status = 'pending',
    this.errorMessage,
    this.progress,
    this.compressionRatio,
    this.outputFileSize,
    this.estimatedOutputSize,
    this.estimatedChangeRatio,
  });

  final String filePath;
  final String fileName;
  final int fileSize;
  final String status;
  final String? errorMessage;
  final double? progress;
  final String? compressionRatio;
  final int? outputFileSize;
  final int? estimatedOutputSize;
  final double? estimatedChangeRatio;

  ImageFileModel copyWith({
    String? filePath,
    String? fileName,
    int? fileSize,
    String? status,
    Object? errorMessage = _unset,
    Object? progress = _unset,
    Object? compressionRatio = _unset,
    Object? outputFileSize = _unset,
    Object? estimatedOutputSize = _unset,
    Object? estimatedChangeRatio = _unset,
  }) {
    return ImageFileModel(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      progress: identical(progress, _unset)
          ? this.progress
          : progress as double?,
      compressionRatio: identical(compressionRatio, _unset)
          ? this.compressionRatio
          : compressionRatio as String?,
      outputFileSize: identical(outputFileSize, _unset)
          ? this.outputFileSize
          : outputFileSize as int?,
      estimatedOutputSize: identical(estimatedOutputSize, _unset)
          ? this.estimatedOutputSize
          : estimatedOutputSize as int?,
      estimatedChangeRatio: identical(estimatedChangeRatio, _unset)
          ? this.estimatedChangeRatio
          : estimatedChangeRatio as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'status': status,
      'errorMessage': errorMessage,
      'progress': progress,
      'compressionRatio': compressionRatio,
      'outputFileSize': outputFileSize,
      'estimatedOutputSize': estimatedOutputSize,
      'estimatedChangeRatio': estimatedChangeRatio,
    };
  }

  factory ImageFileModel.fromJson(Map<String, dynamic> json) {
    return ImageFileModel(
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      status: (json['status'] as String?) ?? 'pending',
      errorMessage: json['errorMessage'] as String?,
      progress: (json['progress'] as num?)?.toDouble(),
      compressionRatio: json['compressionRatio'] as String?,
      outputFileSize: json['outputFileSize'] as int?,
      estimatedOutputSize: json['estimatedOutputSize'] as int?,
      estimatedChangeRatio: (json['estimatedChangeRatio'] as num?)?.toDouble(),
    );
  }
}
