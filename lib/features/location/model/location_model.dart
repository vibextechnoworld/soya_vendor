class LocationModel {
  final int id;
  final String name;
  final String? code;
  final String? stateCode;

  LocationModel({
    required this.id,
    required this.name,
    this.code,
    this.stateCode,
  });

  static final LocationModel other = LocationModel(id: -1, name: "Other", code: "OTHER");

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      stateCode: json['stateCode'],
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
