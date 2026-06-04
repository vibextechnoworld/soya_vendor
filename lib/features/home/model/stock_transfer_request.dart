import 'package:soya_app/features/home/model/stock_transfer_item.dart';

class StockTransferRequest {
  final double? weight;
  final String? unit;
  final List<StockTransferItem>? items;
  final List<String>? thappiIds;
  final String sourceLocationId;
  final String destinationLocationId;
  final String vehicalNumber;
  final String? toVendorId;

  StockTransferRequest({
    this.weight,
    this.unit,
    this.items,
    this.thappiIds,
    required this.sourceLocationId,
    required this.destinationLocationId,
    required this.vehicalNumber,
    this.toVendorId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (weight != null) 'weight': weight,
      if (unit != null) 'unit': unit,
      if (items != null) 'items': items!.map((x) => x.toJson()).toList(),
      if (thappiIds != null) 'thappiIds': thappiIds,
      'sourceLocationId': sourceLocationId,
      'destinationLocationId': destinationLocationId,
      'vehicalNumber': vehicalNumber,
      if (toVendorId != null) 'toVendorId': toVendorId,
    };
  }
}
