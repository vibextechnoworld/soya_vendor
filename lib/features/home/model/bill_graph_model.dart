
class BillGraphModel {
  final bool? success;
  final String? message;
  final BillGraphData? data;

  BillGraphModel({
    this.success,
    this.message,
    this.data,
  });

  factory BillGraphModel.fromJson(Map<String, dynamic> json) => BillGraphModel(
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : BillGraphData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class BillGraphData {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<GraphItem>? data;

  BillGraphData({
    this.startDate,
    this.endDate,
    this.data,
  });

  factory BillGraphData.fromJson(Map<String, dynamic> json) => BillGraphData(
        startDate: json["startDate"] == null ? null : DateTime.parse(json["startDate"]),
        endDate: json["endDate"] == null ? null : DateTime.parse(json["endDate"]),
        data: json["data"] == null
            ? []
            : List<GraphItem>.from(json["data"]!.map((x) => GraphItem.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "startDate": startDate?.toIso8601String(),
        "endDate": endDate?.toIso8601String(),
        "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class GraphItem {
  final String? month;
  final double? amount;
  final double? quantity;

  GraphItem({
    this.month,
    this.amount,
    this.quantity,
  });

  factory GraphItem.fromJson(Map<String, dynamic> json) => GraphItem(
        month: json["month"],
        amount: (json["amount"] as num?)?.toDouble(),
        quantity: (json["quantity"] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "month": month,
        "amount": amount,
        "quantity": quantity,
      };
}
