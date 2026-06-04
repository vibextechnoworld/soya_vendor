class FarmerDocumentModel {
  final bool? success;
  final String? message;
  final List<DocumentData>? data;

  FarmerDocumentModel({
    this.success,
    this.message,
    this.data,
  });

  factory FarmerDocumentModel.fromJson(dynamic json) {
    if (json is List) {
      return FarmerDocumentModel(
        success: true,
        data: json.map((x) => DocumentData.fromJson(x)).toList(),
      );
    }

    dynamic dataJson = json['data'];
    List<DocumentData>? documents;

    if (dataJson != null) {
      if (dataJson is List) {
        documents = dataJson.map((x) => DocumentData.fromJson(x)).toList();
      } else if (dataJson is Map) {
        documents = [DocumentData.fromJson(dataJson as Map<String, dynamic>)];
      }
    }

    return FarmerDocumentModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: documents,
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

class DocumentData {
  final String? id;
  final String? farmerId;
  final String? type;
  final String? imageUrl;
  final String? panNo;
  final String? createdAt;

  DocumentData({
    this.id,
    this.farmerId,
    this.type,
    this.imageUrl,
    this.panNo,
    this.createdAt,
  });

  factory DocumentData.fromJson(Map<String, dynamic> json) {
    return DocumentData(
      id: json['id'] as String?,
      farmerId: json['farmerId'] as String?,
      type: json['type'] as String?,
      imageUrl: json['imageUrl'] as String?,
      panNo: json['panNo'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmerId': farmerId,
      'type': type,
      'imageUrl': imageUrl,
      'panNo': panNo,
      'createdAt': createdAt,
    };
  }
}
