import 'package:soya_app/features/home/model/farmer_bank_model.dart';
import 'package:soya_app/features/home/model/farmer_document_model.dart';
import 'package:soya_app/features/home/model/farmer_land_model.dart';

class FarmerModel {
  final bool? success;
  final String? message;
  final FarmerData? data;

  FarmerModel({
    this.success,
    this.message,
    this.data,
  });

  factory FarmerModel.fromJson(Map<String, dynamic> json) {
    return FarmerModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? FarmerData.fromJson(json['data'] as Map<String, dynamic>)
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

class FarmerData {
  final String? id;
  final String? name;
  final String? aadhaarNo;
  final String? phone;
  final String? email;
  final String? villageAdd;
  final String? gutNumber;
  final String? taluka;
  final String? district;
  final String? panNo;
  final String? profileUrl;
  final String? createdAt;
  final int? totalKycDocuments;
  final int? totalLands;
  final String? vendorName;
  final String? kycStatus;
  final String? kycRejectionReason;
  final List<BankData>? banks;
  final List<DocumentData>? documents;
  final List<LandData>? lands;
  final List<dynamic>? vendors;

  FarmerData({
    this.id,
    this.name,
    this.aadhaarNo,
    this.phone,
    this.email,
    this.villageAdd,
    this.gutNumber,
    this.taluka,
    this.district,
    this.panNo,
    this.profileUrl,
    this.createdAt,
    this.totalKycDocuments,
    this.totalLands,
    this.vendorName,
    this.kycStatus,
    this.kycRejectionReason,
    this.banks,
    this.documents,
    this.lands,
    this.vendors,
  });

  factory FarmerData.fromJson(Map<String, dynamic> json) {
    return FarmerData(
      id: json['id'] as String?,
      name: json['name'] as String?,
      aadhaarNo: json['aadhaarNo'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      villageAdd: json['villageAdd'] as String?,
      gutNumber: json['gutNumber'] as String?,
      taluka: json['taluka'] as String?,
      district: json['district'] as String?,
      panNo: json['panNo'] as String?,
      profileUrl: json['profileUrl'] as String?,
      createdAt: json['createdAt'] as String?,
      totalKycDocuments: json['totalKycDocuments'] as int?,
      totalLands: json['totalLands'] as int?,
      vendorName: json['vendorName'] as String?,
      kycStatus: json['kycStatus'] as String?,
      kycRejectionReason: json['kycRejectionReason'] as String?,
      banks: json['banks'] != null
          ? (json['banks'] as List).map((i) => BankData.fromJson(i)).toList()
          : null,
      documents: json['documents'] != null
          ? (json['documents'] as List)
              .map((i) => DocumentData.fromJson(i))
              .toList()
          : null,
      lands: json['lands'] != null
          ? (json['lands'] as List).map((i) => LandData.fromJson(i)).toList()
          : null,
      vendors: json['vendors'] as List<dynamic>?,
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
      'panNo': panNo,
      'profileUrl': profileUrl,
      'createdAt': createdAt,
      'totalKycDocuments': totalKycDocuments,
      'totalLands': totalLands,
      'vendorName': vendorName,
      'kycStatus': kycStatus,
      'kycRejectionReason': kycRejectionReason,
      'banks': banks?.map((i) => i.toJson()).toList(),
      'documents': documents?.map((i) => i.toJson()).toList(),
      'lands': lands?.map((i) => i.toJson()).toList(),
      'vendors': vendors,
    };
  }
}
