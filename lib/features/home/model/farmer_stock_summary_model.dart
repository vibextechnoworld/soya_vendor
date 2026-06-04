// Model for Farmer Stock Summary Response
class FarmerStockSummaryModel {
  final bool? success;
  final String? message;
  final List<FarmerStockData>? data;

  FarmerStockSummaryModel({
    this.success,
    this.message,
    this.data,
  });

  factory FarmerStockSummaryModel.fromJson(Map<String, dynamic> json) {
    return FarmerStockSummaryModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) =>
                  FarmerStockData.fromJson(item as Map<String, dynamic>))
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

class FarmerStockData {
  final String? id;
  final String? vendorId;
  final String? farmerId;
  final String? productId;
  final double? quantity;
  final String? createdAt;
  final String? updatedAt;
  final StockProductInfo? product;

  FarmerStockData({
    this.id,
    this.vendorId,
    this.farmerId,
    this.productId,
    this.quantity,
    this.createdAt,
    this.updatedAt,
    this.product,
  });

  factory FarmerStockData.fromJson(Map<String, dynamic> json) {
    return FarmerStockData(
      id: json['id'] as String?,
      vendorId: json['vendorId'] as String?,
      farmerId: json['farmerId'] as String?,
      productId: json['productId'] as String?,
      quantity: json['quantity'] != null
          ? (json['quantity'] is int
              ? (json['quantity'] as int).toDouble()
              : json['quantity'] as double?)
          : null,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      product: json['product'] != null
          ? StockProductInfo.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'farmerId': farmerId,
      'productId': productId,
      'quantity': quantity,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'product': product?.toJson(),
    };
  }
}

class StockProductInfo {
  final String? id;
  final String? name;
  final String? type;
  final bool? isActive;
  final String? createdAt;

  StockProductInfo({
    this.id,
    this.name,
    this.type,
    this.isActive,
    this.createdAt,
  });

  factory StockProductInfo.fromJson(Map<String, dynamic> json) {
    return StockProductInfo(
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
