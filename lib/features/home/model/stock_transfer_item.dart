class StockTransferItem {
  final int bagCount;
  final String goniTypeId;

  StockTransferItem({
    required this.bagCount,
    required this.goniTypeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'bagCount': bagCount,
      'goniTypeId': goniTypeId,
    };
  }

  factory StockTransferItem.fromJson(Map<String, dynamic> json) {
    return StockTransferItem(
      bagCount: json['bagCount'] as int,
      goniTypeId: json['goniTypeId'] as String,
    );
  }
}
