class ProductModel {
  final bool? success;
  final String? message;
  final ProductData? data;

  ProductModel({
    this.success,
    this.message,
    this.data,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? ProductData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class ProductData {
  final String? id;
  final String? name;
  final String? type;
  final bool? isActive;
  final String? createdAt;

  ProductData({
    this.id,
    this.name,
    this.type,
    this.isActive,
    this.createdAt,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      id: json['id'] as String?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}
