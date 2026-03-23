class ConversionPreset {
  const ConversionPreset({
    required this.id,
    required this.name,
    required this.outputFormat,
    required this.quality,
    this.isBuiltIn = false,
  });

  final String id;
  final String name;
  final String outputFormat;
  final int quality;
  final bool isBuiltIn;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'outputFormat': outputFormat,
      'quality': quality,
      'isBuiltIn': isBuiltIn,
    };
  }

  factory ConversionPreset.fromJson(Map<String, dynamic> json) {
    return ConversionPreset(
      id: json['id']?.toString() ?? 'custom',
      name: json['name']?.toString() ?? '自定义',
      outputFormat: json['outputFormat']?.toString() ?? 'jpg',
      quality: (json['quality'] as num?)?.toInt() ?? 85,
      isBuiltIn: json['isBuiltIn'] == true,
    );
  }
}
