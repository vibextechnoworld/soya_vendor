class FarmerBankModel {
  final bool? success;
  final String? message;
  final List<BankData>? data;

  FarmerBankModel({
    this.success,
    this.message,
    this.data,
  });

  factory FarmerBankModel.fromJson(dynamic json) {
    if (json is List) {
      return FarmerBankModel(
        success: true,
        data: json.map((x) => BankData.fromJson(x)).toList(),
      );
    }

    dynamic dataJson = json['data'];
    List<BankData>? bankList;

    if (dataJson != null) {
      if (dataJson is List) {
        bankList = dataJson.map((x) => BankData.fromJson(x)).toList();
      } else if (dataJson is Map) {
        bankList = [BankData.fromJson(dataJson as Map<String, dynamic>)];
      }
    }

    return FarmerBankModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: bankList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((x) => x.toJson()).toList(),
    };
  }
}

class BankData {
  final String? id;
  final String? farmerId;
  final String? bankName;
  final String? accountNo;
  final String? ifsc;
  final String? branchName;
  final String? holderName;
  final bool? isPrimary;
  final String? passbookImage;
  final List<String>? passbookImages;

  BankData({
    this.id,
    this.farmerId,
    this.bankName,
    this.accountNo,
    this.ifsc,
    this.branchName,
    this.holderName,
    this.isPrimary,
    this.passbookImage,
    this.passbookImages,
  });

  factory BankData.fromJson(Map<String, dynamic> json) {
    List<String>? images = (json['documentUrls'] as List?)
        ?.whereType<String>()
        .where((u) => u.isNotEmpty)
        .toList();
    images ??= (json['passbookImages'] as List?)
        ?.whereType<String>()
        .where((u) => u.isNotEmpty)
        .toList();
    final String? single = json['passbookImage'] as String?;
    return BankData(
      id: json['id'] as String?,
      farmerId: json['farmerId'] as String?,
      bankName: json['bankName'] as String?,
      accountNo: json['accountNo'] as String?,
      ifsc: json['ifsc'] as String?,
      branchName: json['branchName'] as String?,
      holderName: json['holderName'] as String?,
      isPrimary: json['isPrimary'] as bool?,
      passbookImage: (images != null && images.isNotEmpty)
          ? images.first
          : single,
      passbookImages: images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmerId': farmerId,
      'bankName': bankName,
      'accountNo': accountNo,
      'ifsc': ifsc,
      'branchName': branchName,
      'holderName': holderName,
      'isPrimary': isPrimary,
      'passbookImage': passbookImage,
    };
  }
}
