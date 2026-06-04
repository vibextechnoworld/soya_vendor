class CreateBillModel {
  final bool? success;
  final String? message;
  final BillData? data;

  CreateBillModel({
    this.success,
    this.message,
    this.data,
  });

  factory CreateBillModel.fromJson(Map<String, dynamic> json) {
    return CreateBillModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null ? BillData.fromJson(json['data']) : null,
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

class BillData {
  final String? id;
  final String? billNo;
  final String? billDate;
  final String? vendorId;
  final String? farmerId;
  final String? millId;
  final String? vehicleId;
  final num? totalAmount;
  final String? status;
  final String? createdAt;
  final String? productId;

  BillData({
    this.id,
    this.billNo,
    this.billDate,
    this.vendorId,
    this.farmerId,
    this.millId,
    this.vehicleId,
    this.totalAmount,
    this.status,
    this.createdAt,
    this.productId,
  });

  factory BillData.fromJson(Map<String, dynamic> json) {
    return BillData(
      id: json['id'] as String?,
      billNo: json['billNo'] as String?,
      billDate: json['billDate'] as String?,
      vendorId: json['vendorId'] as String?,
      farmerId: json['farmerId'] as String?,
      millId: json['millId'] as String?,
      vehicleId: json['vehicleId'] as String?,
      totalAmount: json['totalAmount'] as num?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String?,
      productId: json['productId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'billNo': billNo,
      'billDate': billDate,
      'vendorId': vendorId,
      'farmerId': farmerId,
      'millId': millId,
      'vehicleId': vehicleId,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt,
      'productId': productId,
    };
  }
}
