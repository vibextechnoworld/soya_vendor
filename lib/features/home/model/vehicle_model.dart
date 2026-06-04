class VehicleListModel {
  final bool? success;
  final String? message;
  final List<VehicleData>? data;

  VehicleListModel({this.success, this.message, this.data});

  factory VehicleListModel.fromJson(Map<String, dynamic> json) {
    return VehicleListModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List).map((i) => VehicleData.fromJson(i)).toList()
          : null,
    );
  }
}

class VehicleData {
  final String? id;
  final String? vehicleNo;
  final String? ownerName;

  VehicleData({this.id, this.vehicleNo, this.ownerName});

  factory VehicleData.fromJson(Map<String, dynamic> json) {
    return VehicleData(
      id: json['id'] as String?,
      vehicleNo: json['vehicleNo'] as String?,
      ownerName: json['ownerName'] as String?,
    );
  }
}
