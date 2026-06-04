class BankDetailModel {
  final bool? success;
  final String? message;
  final List<BankDetailData>? data;

  BankDetailModel({
    this.success,
    this.message,
    this.data,
  });

  factory BankDetailModel.fromJson(Map<String, dynamic> json) {
    return BankDetailModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((i) => BankDetailData.fromJson(i as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class BankDetailData {
  final String? id;
  final String? bankName;
  final String? ifsc;
  final String? branchName;
  final String? createdAt;
  final String? updatedAt;

  BankDetailData({
    this.id,
    this.bankName,
    this.ifsc,
    this.branchName,
    this.createdAt,
    this.updatedAt,
  });

  factory BankDetailData.fromJson(Map<String, dynamic> json) {
    return BankDetailData(
      id: json['id'] as String?,
      bankName: json['bankName'] as String?,
      ifsc: json['ifsc'] as String?,
      branchName: json['branchName'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

class CreateBankResponse {
  final bool? success;
  final String? message;
  final BankDetailData? data;

  CreateBankResponse({
    this.success,
    this.message,
    this.data,
  });

  factory CreateBankResponse.fromJson(Map<String, dynamic> json) {
    return CreateBankResponse(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? BankDetailData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
