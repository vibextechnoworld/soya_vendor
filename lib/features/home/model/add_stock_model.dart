// Model for Add Stock Response
class AddStockModel {
  final bool? success;
  final String? message;
  final StockData? data;

  AddStockModel({
    this.success,
    this.message,
    this.data,
  });

  factory AddStockModel.fromJson(Map<String, dynamic> json) {
    return AddStockModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? StockData.fromJson(json['data'] as Map<String, dynamic>)
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

class StockData {
  final String? id;
  final String? vendorId;
  final String? farmerId;
  final String? productId;
  final double? quantity;
  final String? createdAt;
  final String? updatedAt;

  StockData({
    this.id,
    this.vendorId,
    this.farmerId,
    this.productId,
    this.quantity,
    this.createdAt,
    this.updatedAt,
  });

  factory StockData.fromJson(Map<String, dynamic> json) {
    return StockData(
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
    };
  }
}
