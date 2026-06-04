class QualityRateModel {
  bool? success;
  String? message;
  List<QualityRateData>? data;
  int? vendorRate;

  QualityRateModel({this.success, this.message, this.data, this.vendorRate});

  QualityRateModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      final dataMap = json['data'];
      vendorRate = dataMap['vendorRate'];
      if (dataMap['qualityRates'] != null) {
        data = <QualityRateData>[];
        dataMap['qualityRates'].forEach((v) {
          data!.add(QualityRateData.fromJson(v));
        });
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['success'] = success;
    json['message'] = message;
    final Map<String, dynamic> dataMap = <String, dynamic>{};
    dataMap['vendorRate'] = vendorRate;
    if (data != null) {
      dataMap['qualityRates'] = data!.map((v) => v.toJson()).toList();
    }
    json['data'] = dataMap;
    return json;
  }
}

class QualityRateData {
  String? quality;
  int? rate;
  String? createdAt;
  String? date;

  QualityRateData({this.quality, this.rate, this.createdAt, this.date});

  QualityRateData.fromJson(Map<String, dynamic> json) {
    quality = json['quality'] ?? 'standard_rate';
    rate = json['rate'];
    createdAt = json['createdAt'] as String?;
    date = json['date'] as String?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['quality'] = quality;
    data['rate'] = rate;
    data['createdAt'] = createdAt;
    data['date'] = date;
    return data;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QualityRateData &&
        other.quality == quality &&
        other.rate == rate &&
        other.createdAt == createdAt &&
        other.date == date;
  }

  @override
  int get hashCode => quality.hashCode ^ rate.hashCode ^ createdAt.hashCode;
}
