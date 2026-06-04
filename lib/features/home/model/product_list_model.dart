class ProductListModel {
  final bool? success;
  final String? message;
  final List<ProductListData>? data;

  ProductListModel({
    this.success,
    this.message,
    this.data,
  });

  factory ProductListModel.fromJson(Map<String, dynamic> json) {
    return ProductListModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) =>
                  ProductListData.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((item) => item.toJson()).toList(),
    };
  }
}

class ProductListData {
  final String? id;
  final String? name;
  final String? type;
  final bool? isActive;
  final String? createdAt;

  ProductListData({
    this.id,
    this.name,
    this.type,
    this.isActive,
    this.createdAt,
  });

  factory ProductListData.fromJson(Map<String, dynamic> json) {
    return ProductListData(
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
