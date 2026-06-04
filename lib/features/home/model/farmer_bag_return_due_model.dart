class FarmerBagReturnDueModel {
  bool? success;
  String? message;
  FarmerBagReturnDueData? data;

  FarmerBagReturnDueModel({this.success, this.message, this.data});

  FarmerBagReturnDueModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null
        ? FarmerBagReturnDueData.fromJson(json['data'])
        : null;
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

class FarmerBagReturnDueData {
  String? goniTypeId;
  String? goniTypeName;
  int? receivedFromFarmer;
  int? returnedToFarmer;
  int? returnDue;

  FarmerBagReturnDueData(
      {this.goniTypeId,
      this.goniTypeName,
      this.receivedFromFarmer,
      this.returnedToFarmer,
      this.returnDue});

  FarmerBagReturnDueData.fromJson(Map<String, dynamic> json) {
    goniTypeId = json['goniTypeId'];
    goniTypeName = json['goniTypeName'];
    receivedFromFarmer = json['receivedFromFarmer'];
    returnedToFarmer = json['returnedToFarmer'];
    returnDue = json['returnDue'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['goniTypeId'] = goniTypeId;
    data['goniTypeName'] = goniTypeName;
    data['receivedFromFarmer'] = receivedFromFarmer;
    data['returnedToFarmer'] = returnedToFarmer;
    data['returnDue'] = returnDue;
    return data;
  }
}
