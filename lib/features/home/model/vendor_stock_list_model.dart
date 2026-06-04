// Model for Vendor Stock List Response
class VendorStockListModel {
  final bool? success;
  final String? message;
  final List<VendorStockData>? data;
  final int? currentPage;
  final int? totalPages;
  final int? totalItems;

  VendorStockListModel({
    this.success,
    this.message,
    this.data,
    this.currentPage,
    this.totalPages,
    this.totalItems,
  });

  factory VendorStockListModel.fromJson(Map<String, dynamic> json) {
    final jsonData = json['data'];
    return VendorStockListModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: jsonData != null &&
              (jsonData is List ||
                  (jsonData is Map && jsonData['stocks'] != null))
          ? ((jsonData is List ? jsonData : jsonData['stocks']) as List)
              .map((item) =>
                  VendorStockData.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      currentPage: jsonData != null && jsonData is Map
          ? jsonData['currentPage'] as int?
          : null,
      totalPages: jsonData != null && jsonData is Map
          ? jsonData['totalPages'] as int?
          : null,
      totalItems: jsonData != null && jsonData is Map
          ? jsonData['totalItems'] as int?
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

class VendorStockData {
  final String? id;
  final String? vendorId;
  final String? farmerId;
  final String? productId;
  final double? quantity;
  final String? createdAt;
  final String? updatedAt;
  final FarmerInfo? farmer;
  final ProductInfo? product;

  VendorStockData({
    this.id,
    this.vendorId,
    this.farmerId,
    this.productId,
    this.quantity,
    this.createdAt,
    this.updatedAt,
    this.farmer,
    this.product,
  });

  factory VendorStockData.fromJson(Map<String, dynamic> json) {
    return VendorStockData(
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
      farmer: json['farmer'] != null
          ? FarmerInfo.fromJson(json['farmer'] as Map<String, dynamic>)
          : null,
      product: json['product'] != null
          ? ProductInfo.fromJson(json['product'] as Map<String, dynamic>)
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
      'farmer': farmer?.toJson(),
      'product': product?.toJson(),
    };
  }
}

class FarmerInfo {
  final String? id;
  final String? name;
  final String? aadhaarNo;
  final String? phone;
  final String? email;
  final String? villageAdd;
  final String? gutNumber;
  final String? taluka;
  final String? district;
  final String? createdAt;

  FarmerInfo({
    this.id,
    this.name,
    this.aadhaarNo,
    this.phone,
    this.email,
    this.villageAdd,
    this.gutNumber,
    this.taluka,
    this.district,
    this.createdAt,
  });

  factory FarmerInfo.fromJson(Map<String, dynamic> json) {
    return FarmerInfo(
      id: json['id'] as String?,
      name: json['name'] as String?,
      aadhaarNo: json['aadhaarNo'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      villageAdd: json['villageAdd'] as String?,
      gutNumber: json['gutNumber'] as String?,
      taluka: json['taluka'] as String?,
      district: json['district'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'aadhaarNo': aadhaarNo,
      'phone': phone,
      'email': email,
      'villageAdd': villageAdd,
      'gutNumber': gutNumber,
      'taluka': taluka,
      'district': district,
      'createdAt': createdAt,
    };
  }
}

class ProductInfo {
  final String? id;
  final String? name;
  final String? type;
  final bool? isActive;
  final String? createdAt;

  ProductInfo({
    this.id,
    this.name,
    this.type,
    this.isActive,
    this.createdAt,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
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
