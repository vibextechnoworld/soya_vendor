class LocationModel {
  final String id;
  final String name;
  final String? code;
  final String? stateCode;
  /// 'official' or 'custom' for villages; null for districts/talukas.
  final String? source;

  LocationModel({
    required this.id,
    required this.name,
    this.code,
    this.stateCode,
    this.source,
  });

  static final LocationModel other =
      LocationModel(id: '-1', name: 'Other', code: 'OTHER');

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      stateCode: json['stateCode']?.toString(),
      source: json['source']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}