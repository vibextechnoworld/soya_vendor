class VendorStockSummaryModel {
  bool? success;
  String? message;
  StockSummaryData? data;

  VendorStockSummaryModel({this.success, this.message, this.data});

  VendorStockSummaryModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data =
        json['data'] != null ? StockSummaryData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class StockSummaryData {
  List<SummaryItem>? summary;
  TotalAvailable? totalAvailable;
  BagLedgerTotals? bagLedgerTotals;

  StockSummaryData({this.summary, this.totalAvailable, this.bagLedgerTotals});

  StockSummaryData.fromJson(Map<String, dynamic> json) {
    if (json['summary'] != null) {
      summary = <SummaryItem>[];
      json['summary'].forEach((v) {
        summary!.add(SummaryItem.fromJson(v));
      });
    }
    totalAvailable = json['totalAvailable'] != null
        ? TotalAvailable.fromJson(json['totalAvailable'])
        : null;
    bagLedgerTotals = json['bagLedgerTotals'] != null
        ? BagLedgerTotals.fromJson(json['bagLedgerTotals'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (summary != null) {
      data['summary'] = summary!.map((v) => v.toJson()).toList();
    }
    if (totalAvailable != null) {
      data['totalAvailable'] = totalAvailable!.toJson();
    }
    if (bagLedgerTotals != null) {
      data['bagLedgerTotals'] = bagLedgerTotals!.toJson();
    }
    return data;
  }
}

class SummaryItem {
  Sum? sSum;
  int? sCount;
  String? status;

  SummaryItem({this.sSum, this.sCount, this.status});

  SummaryItem.fromJson(Map<String, dynamic> json) {
    sSum = json['_sum'] != null ? Sum.fromJson(json['_sum']) : null;
    sCount = json['_count'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (sSum != null) {
      data['_sum'] = sSum!.toJson();
    }
    data['_count'] = sCount;
    data['status'] = status;
    return data;
  }
}

class Sum {
  double? weight;
  int? bagCount;

  Sum({this.weight, this.bagCount});

  Sum.fromJson(Map<String, dynamic> json) {
    weight = (json['weight'] as num?)?.toDouble();
    bagCount = json['bagCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['weight'] = weight;
    data['bagCount'] = bagCount;
    return data;
  }
}

class TotalAvailable {
  double? weight;
  int? bagCount;

  TotalAvailable({this.weight, this.bagCount});

  TotalAvailable.fromJson(Map<String, dynamic> json) {
    weight = (json['weight'] as num?)?.toDouble();
    bagCount = json['bagCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['weight'] = weight;
    data['bagCount'] = bagCount;
    return data;
  }
}

class BagLedgerTotals {
  int? totalReceivedFromFarmers;
  int? totalSentToAdmin;
  int? totalReturnedToFarmers;
  int? totalReceivedFromAdmin;
  int? totalReceivedFromVendorSelf;
  int? totalAdminAdded;
  int? totalRemainingWithVendor;

  BagLedgerTotals({
    this.totalReceivedFromFarmers,
    this.totalSentToAdmin,
    this.totalReturnedToFarmers,
    this.totalReceivedFromAdmin,
    this.totalReceivedFromVendorSelf,
    this.totalAdminAdded,
    this.totalRemainingWithVendor,
  });

  BagLedgerTotals.fromJson(Map<String, dynamic> json) {
    totalReceivedFromFarmers = json['totalReceivedFromFarmers'];
    totalSentToAdmin = json['totalSentToAdmin'];
    totalReturnedToFarmers = json['totalReturnedToFarmers'];
    totalReceivedFromAdmin = json['totalReceivedFromAdmin'];
    totalReceivedFromVendorSelf = json['totalReceivedFromVendorSelf'];
    totalAdminAdded = json['totalAdminAdded'];
    totalRemainingWithVendor = json['totalRemainingWithVendor'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalReceivedFromFarmers'] = totalReceivedFromFarmers;
    data['totalSentToAdmin'] = totalSentToAdmin;
    data['totalReturnedToFarmers'] = totalReturnedToFarmers;
    data['totalReceivedFromAdmin'] = totalReceivedFromAdmin;
    data['totalReceivedFromVendorSelf'] = totalReceivedFromVendorSelf;
    data['totalAdminAdded'] = totalAdminAdded;
    data['totalRemainingWithVendor'] = totalRemainingWithVendor;
    return data;
  }
}
