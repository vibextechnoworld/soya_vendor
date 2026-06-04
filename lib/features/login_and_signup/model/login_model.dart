class LoginModel {
  bool? success;
  String? message;
  Data? data;

  LoginModel({this.success, this.message, this.data});

  LoginModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
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

class Data {
  String? token;
  SafeUser? safeUser;

  Data({this.token, this.safeUser});

  Data.fromJson(Map<String, dynamic> json) {
    token = json['token'];
    safeUser =
        json['safeUser'] != null ? SafeUser.fromJson(json['safeUser']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['token'] = token;
    if (safeUser != null) {
      data['safeUser'] = safeUser!.toJson();
    }
    return data;
  }
}

class SafeUser {
  String? id;
  String? name;
  String? phone;
  String? email;
  String? role;
  bool? isActive;
  int? vendorRate;
  String? createdAt;
  String? villageAdd;
  String? taluka;
  String? district;
  bool? masterVendor;

  SafeUser(
      {this.id,
      this.name,
      this.phone,
      this.email,
      this.role,
      this.isActive,
      this.vendorRate,
      this.createdAt,
      this.villageAdd,
      this.taluka,
      this.district,
      this.masterVendor});

  SafeUser.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    phone = json['phone'];
    email = json['email'];
    role = json['role'];
    isActive = json['isActive'];
    vendorRate = json['vendorRate'];
    createdAt = json['createdAt'];
    villageAdd = json['villageAdd'];
    taluka = json['taluka'];
    district = json['district'];
    masterVendor = json['masterVendor'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['phone'] = phone;
    data['email'] = email;
    data['role'] = role;
    data['isActive'] = isActive;
    data['vendorRate'] = vendorRate;
    data['createdAt'] = createdAt;
    data['villageAdd'] = villageAdd;
    data['taluka'] = taluka;
    data['district'] = district;
    data['masterVendor'] = masterVendor;
    return data;
  }
}
