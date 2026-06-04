class SaveBillRequest {
  final String? billId;
  final String? farmerId;
  final String? billDate;
  final String? productId; // Flat field
  final num? quantity; // Flat field
  final String? unit; // Flat field
  final num? rate; // Flat field
  final int? bagCount; // Flat field
  final String? slipNo; // Flat field
  final num? gross; // Flat field
  final num? tare; // Flat field
  final String? vehicleNumber;
  final String? vehicleType;
  final String? driverName;
  final String? billLocation;

  SaveBillRequest({
    this.billId,
    this.farmerId,
    this.billDate,
    this.productId,
    this.quantity,
    this.unit,
    this.rate,
    this.bagCount,
    this.slipNo,
    this.gross,
    this.tare,
    this.vehicleNumber,
    this.vehicleType,
    this.driverName,
    this.billLocation,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'farmerId': farmerId,
      'billDate': billDate,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'driverName': driverName,
      'billLocation': billLocation,
    };
    if (billId != null) {
      data['billId'] = billId;
    }
    return data;
  }
}

class SaveBillItem {
  final String? productId;
  final num? quantity;
  final String? unit;
  final num? rate;
  final int? bagCount;

  SaveBillItem({
    this.productId,
    this.quantity,
    this.unit,
    this.rate,
    this.bagCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'bagCount': bagCount,
    };
  }
}

class SaveBillSlip {
  final String? slipNo;
  final List<SaveBillSlipEntry>? entries;

  SaveBillSlip({this.slipNo, this.entries});

  Map<String, dynamic> toJson() {
    return {
      'slipNo': slipNo,
      'entries': entries?.map((e) => e.toJson()).toList(),
    };
  }
}

class SaveBillSlipEntry {
  final int? srNo;
  final num? gross;
  final num? tare;

  SaveBillSlipEntry({this.srNo, this.gross, this.tare});

  Map<String, dynamic> toJson() {
    return {
      'srNo': srNo,
      'gross': gross,
      'tare': tare,
    };
  }
}
