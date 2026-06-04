class GoniTypeModel {
  final bool? success;
  final String? message;
  final List<GoniType>? data;

  GoniTypeModel({
    this.success,
    this.message,
    this.data,
  });

  factory GoniTypeModel.fromJson(Map<String, dynamic> json) {
    return GoniTypeModel(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? (json['data'] as List).map((i) => GoniType.fromJson(i)).toList()
          : null,
    );
  }
}

class GoniType {
  final String? id;
  final String? name;
  final double? weightPerBag;
  final bool? isActive;
  final bool? isTracked;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  GoniType({
    this.id,
    this.name,
    this.weightPerBag,
    this.isActive,
    this.isTracked,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory GoniType.fromJson(Map<String, dynamic> json) {
    return GoniType(
      id: json['id'] ?? json['_id'],
      name: json['name'],
      weightPerBag: (json['weightPerBag'] as num?)?.toDouble(),
      isActive: json['isActive'],
      isTracked: json['isTracked'],
      createdBy: json['createdBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'weightPerBag': weightPerBag,
      'isActive': isActive,
      'isTracked': isTracked,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoniType && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
