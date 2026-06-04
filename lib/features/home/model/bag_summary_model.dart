class BagSummaryModel {
  bool? success;
  String? message;
  BagSummaryData? data;

  BagSummaryModel({this.success, this.message, this.data});

  BagSummaryModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? BagSummaryData.fromJson(json['data']) : null;
  }
}

class BagSummaryData {
  BagTotals? totals;
  List<BagByType>? byType;
  List<ReturnedToFarmer>? returnedToFarmersByFarmer;
  List<ReceivedFromAdminByAdmin>? receivedFromAdminByAdmin;

  BagSummaryData(
      {this.totals,
      this.byType,
      this.returnedToFarmersByFarmer,
      this.receivedFromAdminByAdmin});

  BagSummaryData.fromJson(Map<String, dynamic> json) {
    totals = json['totals'] != null ? BagTotals.fromJson(json['totals']) : null;
    if (json['byType'] != null) {
      byType = <BagByType>[];
      json['byType'].forEach((v) {
        byType!.add(BagByType.fromJson(v));
      });
    }
    if (json['returnedToFarmersByFarmer'] != null) {
      returnedToFarmersByFarmer = <ReturnedToFarmer>[];
      json['returnedToFarmersByFarmer'].forEach((v) {
        returnedToFarmersByFarmer!.add(ReturnedToFarmer.fromJson(v));
      });
    }
    if (json['receivedFromAdminByAdmin'] != null) {
      receivedFromAdminByAdmin = <ReceivedFromAdminByAdmin>[];
      json['receivedFromAdminByAdmin'].forEach((v) {
        receivedFromAdminByAdmin!.add(ReceivedFromAdminByAdmin.fromJson(v));
      });
    }
  }
}

class BagTotals {
  int? receivedFromFarmers;
  int? sentToAdmin;
  int? receivedFromAdmin;
  int? receivedFromVendorSelf;
  int? receivedAdminAdd;
  int? returnedToFarmers;
  int? currentWithVendor;

  BagTotals(
      {this.receivedFromFarmers,
      this.sentToAdmin,
      this.receivedFromAdmin,
      this.receivedFromVendorSelf,
      this.receivedAdminAdd,
      this.returnedToFarmers,
      this.currentWithVendor});

  BagTotals.fromJson(Map<String, dynamic> json) {
    receivedFromFarmers = json['receivedFromFarmers'];
    sentToAdmin = json['sentToAdmin'];
    receivedFromAdmin = json['receivedFromAdmin'];
    receivedFromVendorSelf = json['receivedFromVendorSelf'];
    receivedAdminAdd = json['receivedAdminAdd'];
    returnedToFarmers = json['returnedToFarmers'];
    currentWithVendor = json['currentWithVendor'];
  }
}

class BagByType {
  String? goniTypeId;
  String? goniTypeName;
  int? receivedFromFarmers;
  int? sentToAdmin;
  int? receivedFromAdmin;
  int? receivedFromVendorSelf;
  int? receivedAdminAdd;
  int? returnedToFarmers;
  int? currentWithVendor;

  BagByType(
      {this.goniTypeId,
      this.goniTypeName,
      this.receivedFromFarmers,
      this.sentToAdmin,
      this.receivedFromAdmin,
      this.receivedFromVendorSelf,
      this.receivedAdminAdd,
      this.returnedToFarmers,
      this.currentWithVendor});

  BagByType.fromJson(Map<String, dynamic> json) {
    goniTypeId = json['goniTypeId'];
    goniTypeName = json['goniTypeName'];
    receivedFromFarmers = json['receivedFromFarmers'];
    sentToAdmin = json['sentToAdmin'];
    receivedFromAdmin = json['receivedFromAdmin'];
    receivedFromVendorSelf = json['receivedFromVendorSelf'];
    receivedAdminAdd = json['receivedAdminAdd'];
    returnedToFarmers = json['returnedToFarmers'];
    currentWithVendor = json['currentWithVendor'];
  }
}

class ReturnedToFarmer {
  FarmerInfo? farmer;
  int? bagCount;

  ReturnedToFarmer({this.farmer, this.bagCount});

  ReturnedToFarmer.fromJson(Map<String, dynamic> json) {
    farmer =
        json['farmer'] != null ? FarmerInfo.fromJson(json['farmer']) : null;
    bagCount = json['bagCount'];
  }
}

class FarmerInfo {
  String? id;
  String? name;
  String? phone;

  FarmerInfo({this.id, this.name, this.phone});

  FarmerInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    phone = json['phone'];
  }
}

class ReceivedFromAdminByAdmin {
  String? goniTypeId;
  int? bagCount;

  ReceivedFromAdminByAdmin({this.goniTypeId, this.bagCount});

  ReceivedFromAdminByAdmin.fromJson(Map<String, dynamic> json) {
    goniTypeId = json['goniTypeId'];
    bagCount = json['bagCount'];
  }
}
