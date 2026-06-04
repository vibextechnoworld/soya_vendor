class MillListModel {
  final bool? success;
  final String? message;
  final List<MillData>? data;

  MillListModel({this.success, this.message, this.data});

  factory MillListModel.fromJson(Map<String, dynamic> json) {
    return MillListModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List).map((i) => MillData.fromJson(i)).toList()
          : null,
    );
  }
}

class MillData {
  final String? id;
  final String? name;
  final String? address;

  MillData({this.id, this.name, this.address});

  factory MillData.fromJson(Map<String, dynamic> json) {
    return MillData(
      id: json['id'] as String?,
      name: json['name'] as String?,
      address: json['address'] as String?,
    );
  }
}
