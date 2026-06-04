class FarmerLandModel {
  final bool? success;
  final String? message;
  final LandData? data;

  FarmerLandModel({
    this.success,
    this.message,
    this.data,
  });

  factory FarmerLandModel.fromJson(dynamic json) {
    if (json is List) {
      return FarmerLandModel(
        success: true,
        data: json.isNotEmpty ? LandData.fromJson(json.first) : null,
      );
    }

    dynamic dataJson = json['data'];
    Map<String, dynamic>? dataMap;

    if (dataJson != null) {
      if (dataJson is List) {
        if (dataJson.isNotEmpty) {
          dataMap = dataJson.first as Map<String, dynamic>;
        }
      } else if (dataJson is Map) {
        dataMap = dataJson as Map<String, dynamic>;
      }
    }

    return FarmerLandModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: dataMap != null ? LandData.fromJson(dataMap) : null,
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

class LandData {
  final String? id;
  final String? farmerId;
  final String? locationId; 
  final String? landType;
  final double? area;
  final String? documentUrl;
  final String? createdAt;
  final String? villageAdd;
  final String? taluka;
  final String? district;
  final String? landOwnerName;
  final String? relationType;

  LandData({
    this.id,
    this.farmerId,
    this.locationId,
    this.landType,
    this.area,
    this.documentUrl,
    this.createdAt,
    this.villageAdd,
    this.taluka,
    this.district,
    this.landOwnerName,
    this.relationType,
  });

  factory LandData.fromJson(Map<String, dynamic> json) {
    return LandData(
      id: json['id'] as String?,
      farmerId: json['farmerId'] as String?,
      locationId: json['locationId'] as String?,
      landType: json['landType'] as String?,
      area: json['area'] != null
          ? (json['area'] is int
              ? (json['area'] as int).toDouble()
              : json['area'] as double?)
          : null,
      documentUrl: json['documentUrl'] as String?,
      createdAt: json['createdAt'] as String?,
      villageAdd: json['villageAdd'] as String?,
      taluka: json['taluka'] as String?,
      district: json['district'] as String?,
      landOwnerName: json['landOwnerName'] as String?,
      relationType: json['relationType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmerId': farmerId,
      'locationId': locationId,
      'landType': landType,
      'area': area,
      'documentUrl': documentUrl,
      'createdAt': createdAt,
      'villageAdd': villageAdd,
      'taluka': taluka,
      'district': district,
      'landOwnerName': landOwnerName,
      'relationType': relationType,
    };
  }
}
