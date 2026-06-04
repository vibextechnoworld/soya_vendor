class LocationModel {
  final bool? success;
  final String? message;
  final List<LocationData>? data;

  LocationModel({
    this.success,
    this.message,
    this.data,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => LocationData.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((e) => e.toJson()).toList(),
    };
  }
}

class LocationData {
  final String? id;
  final String? name;
  final int? quintalLimit;
  final String? createdAt;

  LocationData({
    this.id,
    this.name,
    this.quintalLimit,
    this.createdAt,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      id: json['id'] as String?,
      name: json['name'] as String?,
      quintalLimit: json['quintalLimit'] as int?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quintalLimit': quintalLimit,
      'createdAt': createdAt,
    };
  }
}
