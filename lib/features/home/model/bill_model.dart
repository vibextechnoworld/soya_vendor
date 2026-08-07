import 'farmer_model.dart';
import 'goni_type_model.dart';

class BillListModel {
  final bool? success;
  final String? message;
  final List<BillModel>? data;
  final int? currentPage;
  final int? totalPages;
  final int? totalItems;
  final num? averageRate;
  final num? totalAmount;
  final int? limit;
  final num? totalBags;
  final num? totalGrossWeight;
  final num? totalBagWeight;
  final num? totalNetWeight;
  final num? avgFm;
  final num? avgDamage;
  final num? avgMoisture;

  BillListModel({
    this.success,
    this.message,
    this.data,
    this.currentPage,
    this.totalPages,
    this.totalItems,
    this.averageRate,
    this.totalAmount,
    this.limit,
    this.totalBags,
    this.totalGrossWeight,
    this.totalBagWeight,
    this.totalNetWeight,
    this.avgFm,
    this.avgDamage,
    this.avgMoisture,
  });

  static int? _parsePageInfo(
      Map<String, dynamic> json, List<String> keys, Map? jsonData) {
    for (final key in keys) {
      if (json[key] != null) return _toInt(json[key]);
      if (jsonData != null && jsonData[key] != null) {
        return _toInt(jsonData[key]);
      }
    }
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static num? _toNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static num? _parseNum(
      Map<String, dynamic> json, List<String> keys, Map? jsonData) {
    for (final key in keys) {
      if (json[key] != null) return _toNum(json[key]);
      if (jsonData != null && jsonData[key] != null) {
        return _toNum(jsonData[key]);
      }
    }
    return null;
  }

  factory BillListModel.fromJson(Map<String, dynamic> json) {
    final jsonData = json['data'];
    return BillListModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: jsonData != null && jsonData is Map && jsonData['bills'] != null
          ? (jsonData['bills'] as List)
              .map((i) => BillModel.fromJson(i))
              .toList()
          : (jsonData is List
              ? jsonData.map((i) => BillModel.fromJson(i)).toList()
              : (jsonData != null &&
                      jsonData is Map &&
                      jsonData['data'] != null &&
                      jsonData['data'] is List
                  ? (jsonData['data'] as List)
                      .map((i) => BillModel.fromJson(i))
                      .toList()
                  : null)),
      currentPage: _parsePageInfo(json, ['currentPage', 'current_page', 'page'],
          jsonData is Map ? jsonData : null),
      totalPages: _parsePageInfo(json, ['totalPages', 'total_pages', 'pages'],
          jsonData is Map ? jsonData : null),
      totalItems: _parsePageInfo(
          json,
          ['totalItems', 'total_items', 'total', 'count'],
          jsonData is Map ? jsonData : null),
      averageRate: _parseNum(
          json,
          ['averageRate', 'average_rate', 'avgRate', 'avg_rate'],
          jsonData is Map ? jsonData : null),
      totalAmount: _parseNum(
          json,
          ['totalAmount', 'total_amount', 'totAmount', 'tot_amount'],
          jsonData is Map ? jsonData : null),
      totalBags: _parseNum(
          json,
          ['totalBags', 'total_bags', 'totalNoOfBags'],
          jsonData is Map ? jsonData : null),
      totalGrossWeight: _parseNum(
          json,
          ['totalGrossWeight', 'total_gross_weight'],
          jsonData is Map ? jsonData : null),
      totalBagWeight: _parseNum(
          json,
          ['totalBagWeight', 'total_bag_weight'],
          jsonData is Map ? jsonData : null),
      totalNetWeight: _parseNum(
          json,
          ['totalNetWeight', 'total_net_weight'],
          jsonData is Map ? jsonData : null),
      avgFm: _parseNum(
          json,
          ['avgFm', 'averageFm', 'avg_fm', 'totalFm'],
          jsonData is Map ? jsonData : null),
      avgDamage: _parseNum(
          json,
          ['avgDamage', 'averageDamage', 'avg_damage', 'totalDamage'],
          jsonData is Map ? jsonData : null),
      avgMoisture: _parseNum(
          json,
          ['avgMoisture', 'averageMoisture', 'avg_moisture', 'totalMoisture'],
          jsonData is Map ? jsonData : null),
      limit: jsonData != null && jsonData is Map
          ? _toInt(jsonData['limit'])
          : null,
    );
  }
}

class BillDetailModel {
  final bool? success;
  final String? message;
  final BillModel? data;

  BillDetailModel({this.success, this.message, this.data});

  factory BillDetailModel.fromJson(Map<String, dynamic> json) {
    final jsonData = json['data'];
    if (jsonData != null && jsonData is Map) {
      return BillDetailModel(
        success: json['success'] as bool?,
        message: json['message'] as String?,
        data: jsonData['bill'] != null
            ? BillModel.fromJson(jsonData['bill'] as Map<String, dynamic>)
            : BillModel.fromJson(jsonData as Map<String, dynamic>),
      );
    }
    return BillDetailModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: null,
    );
  }
}

class BillModel {
  final String? rate;
  final String? id;
  final String? grnNo;
  final String? billNo;
  final int? vendorBillSeq;
  final String? billDate;
  final String? vendorId;
  final String? farmerId;
  final num? totalAmount;
  final String? status;
  final String? createdAt;
  final num? primaryQuantity;
  final String? primaryUnit;
  final num? ratePerUnit;
  final num? grossAmount;
  final String? goniTypeId;
  final int? bagCount;
  final num? goniWeight;
  final num? netPayable;
  final GoniType? goniType;
  final List<BillGoni>? gonis;
  final FarmerData? farmer;
  final BillVendor? vendor;
  final List<BillItem>? items;
  final List<BillDeduction>? deductions;
  final List<BillSlip>? slips;
  final String? vehicleNumber;
  final String? vehicleType;
  final String? driverName;
  final num? goniDeductionAmount;
  final num? perQtlLabDeduction;
  final num? balanceAmount;
  final num? advancedAmount;
  final num? settledAmount;
  final String? paymentStatus;
  final PaymentModelDetail? payment;
  final String? billLocation;
  final CalculationDetails? calculationDetails;

  bool get isOverdue {
    if (paymentStatus != null && paymentStatus!.toUpperCase() == 'PAID') {
      return false;
    }
    final dateStr = billDate ?? createdAt;
    if (dateStr == null) return false;
    DateTime? billDateTime;
    try {
      billDateTime = DateTime.parse(dateStr);
    } catch (_) {
      return false;
    }
    final diff = DateTime.now().difference(billDateTime);
    return diff.inDays >= 2;
  }

  BillModel({
    this.rate,
    this.id,
    this.grnNo,
    this.billNo,
    this.vendorBillSeq,
    this.billDate,
    this.vendorId,
    this.farmerId,
    this.totalAmount,
    this.status,
    this.createdAt,
    this.primaryQuantity,
    this.primaryUnit,
    this.ratePerUnit,
    this.grossAmount,
    this.goniTypeId,
    this.bagCount,
    this.goniWeight,
    this.netPayable,
    this.goniType,
    this.gonis,
    this.farmer,
    this.vendor,
    this.items,
    this.deductions,
    this.slips,
    this.vehicleNumber,
    this.vehicleType,
    this.driverName,
    this.goniDeductionAmount,
    this.perQtlLabDeduction,
    this.balanceAmount,
    this.advancedAmount,
    this.settledAmount,
    this.paymentStatus,
    this.payment,
    this.billLocation,
    this.calculationDetails,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String?,
      rate: json['quality'] as String?,
      grnNo: json['grnNumber'] as String?,
      billNo: json['billNo'] as String?,
      vendorBillSeq: (json['vendorBillSeq'] as num?)?.toInt(),
      billDate: json['billDate'] as String?,
      vendorId: json['vendorId'] as String?,
      farmerId: json['farmerId'] as String?,
      totalAmount: json['totalAmount'] as num?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String?,
      primaryQuantity: json['primaryQuantity'] as num?,
      primaryUnit: json['primaryUnit'] as String?,
      ratePerUnit: json['ratePerUnit'] as num?,
      grossAmount: json['grossAmount'] as num?,
      goniTypeId: json['goniTypeId'] as String?,
      bagCount: json['bagCount'] as int?,
      goniWeight: json['goniWeight'] as num?,
      netPayable: json['netPayable'] as num?,
      goniType:
          json['goniType'] != null ? GoniType.fromJson(json['goniType']) : null,
      gonis: json['gonis'] != null
          ? (json['gonis'] as List).map((i) => BillGoni.fromJson(i)).toList()
          : null,
      farmer:
          json['farmer'] != null ? FarmerData.fromJson(json['farmer']) : null,
      vendor: json['vendor'] != null
          ? BillVendor.fromJson(json['vendor'] as Map<String, dynamic>)
          : null,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => BillItem.fromJson(i)).toList()
          : null,
      deductions: json['deductions'] != null
          ? (json['deductions'] as List)
              .map((i) => BillDeduction.fromJson(i))
              .toList()
          : null,
      slips: json['slips'] != null
          ? (json['slips'] as List).map((i) => BillSlip.fromJson(i)).toList()
          : null,
      vehicleNumber: json['vehicleNumber'] as String?,
      vehicleType: json['vehicleType'] as String?,
      driverName: json['driverName'] as String?,
      goniDeductionAmount: json['goniDeductionAmount'] as num?,
      perQtlLabDeduction: json['perQtlLabDeduction'] as num?,
      balanceAmount: json['balanceAmount'] as num?,
      advancedAmount: json['adjustedAdvanceAmount'] as num? ?? json['advancedAmount'] as num?,
      settledAmount: json['settledAmount'] as num?,
      paymentStatus: json['paymentStatus'] as String?,
      payment: json['payment'] != null
          ? PaymentModelDetail.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
      billLocation: json['billLocation'] as String?,

      calculationDetails: json['calculationDetails'] != null
          ? CalculationDetails.fromJson(json['calculationDetails'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quality': rate,
      'grnNumber': grnNo,
      'id': id,
      'billNo': billNo,
      'vendorBillSeq': vendorBillSeq,
      'billDate': billDate,
      'vendorId': vendorId,
      'farmerId': farmerId,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt,
      'primaryQuantity': primaryQuantity,
      'primaryUnit': primaryUnit,
      'ratePerUnit': ratePerUnit,
      'grossAmount': grossAmount,
      'goniTypeId': goniTypeId,
      'bagCount': bagCount,
      'goniWeight': goniWeight,
      'netPayable': netPayable,
      'goniType': goniType?.toJson(),
      'gonis': gonis?.map((i) => i.toJson()).toList(),
      'farmer': farmer?.toJson(),
      'vendor': vendor?.toJson(),
      'items': items?.map((i) => i.toJson()).toList(),
      'deductions': deductions?.map((i) => i.toJson()).toList(),
      'slips': slips?.map((i) => i.toJson()).toList(),
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'driverName': driverName,
      'goniDeductionAmount': goniDeductionAmount,
      'perQtlLabDeduction': perQtlLabDeduction,
      'balanceAmount': balanceAmount,
      'advancedAmount': advancedAmount,
      'settledAmount': settledAmount,
      'paymentStatus': paymentStatus,
      'payment': payment?.toJson(),
      'billLocation': billLocation,
      'calculationDetails': calculationDetails?.toJson(),
    };
  }
}

class BillGoni {
  final String? id;
  final String? billId;
  final String? goniTypeId;
  final int? bagCount;
  final num? weight;
  final String? createdAt;
  final GoniType? goniType;

  BillGoni({
    this.id,
    this.billId,
    this.goniTypeId,
    this.bagCount,
    this.weight,
    this.createdAt,
    this.goniType,
  });

  factory BillGoni.fromJson(Map<String, dynamic> json) {
    return BillGoni(
      id: json['id'] as String?,
      billId: json['billId'] as String?,
      goniTypeId: json['goniTypeId'] as String?,
      bagCount: json['bagCount'] as int?,
      weight: json['weight'] as num?,
      createdAt: json['createdAt'] as String?,
      goniType:
          json['goniType'] != null ? GoniType.fromJson(json['goniType']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'billId': billId,
      'goniTypeId': goniTypeId,
      'bagCount': bagCount,
      'weight': weight,
      'createdAt': createdAt,
      'goniType': goniType?.toJson(),
    };
  }
}

class BillItem {
  final String? id;
  final String? billId;
  final String? productId;
  final int? bagCount;
  final String? unit;
  final num? quantity;
  final num? rate;
  final num? amount;

  BillItem({
    this.id,
    this.billId,
    this.productId,
    this.bagCount,
    this.unit,
    this.quantity,
    this.rate,
    this.amount,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'] as String?,
      billId: json['billId'] as String?,
      productId: json['productId'] as String?,
      bagCount: json['bagCount'] as int?,
      unit: json['unit'] as String?,
      quantity: json['quantity'] as num?,
      rate: json['rate'] as num?,
      amount: json['amount'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'billId': billId,
      'productId': productId,
      'bagCount': bagCount,
      'unit': unit,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
    };
  }
}

class BillDeduction {
  final String? id;
  final String? billId;
  final String? masterId;
  final String? label;
  final num? value;
  final Map<String, dynamic>? payload;
  final Map<String, dynamic>? actualInputs;
  final Map<String, dynamic>? defaultInputs;
  final Map<String, dynamic>? variableDeductions;

  final Map<String, dynamic>? customInputs;
  final Map<String, dynamic>? deductedInputs;
  final Map<String, dynamic>? deductedAmounts;
  final Map<String, dynamic>? allowedInputs;
  final List<VariableDetail>? variableDetails;
  final num? deductionPercent;
  final num? deductionWeight;
  final num? deductionAmount;
  final num? perQtlLabDeduction;

  BillDeduction({
    this.id,
    this.billId,
    this.masterId,
    this.label,
    this.value,
    this.payload,
    this.actualInputs,
    this.defaultInputs,
    this.variableDeductions,
    this.customInputs,
    this.deductedInputs,
    this.deductedAmounts,
    this.allowedInputs,
    this.variableDetails,
    this.deductionPercent,
    this.deductionWeight,
    this.deductionAmount,
    this.perQtlLabDeduction,
  });

  factory BillDeduction.fromJson(Map<String, dynamic> json) {
    final payloadMap = json['payload'] as Map<String, dynamic>?;
    final variableDetailsRaw =
        json['variableDetails'] ?? payloadMap?['variableDetails'];
    return BillDeduction(
      id: (json['id'] ?? json['deductionId']) as String?,
      billId: json['billId'] as String?,
      masterId: json['masterId'] as String?,
      label: json['label'] as String?,
      value: json['value'] as num?,
      payload: payloadMap,
      actualInputs: (json['actualInputs'] ?? payloadMap?['actualInputs'])
          as Map<String, dynamic>?,
      defaultInputs: (json['defaultInputs'] ?? payloadMap?['defaultInputs'])
          as Map<String, dynamic>?,
      variableDeductions: (json['variableDeductions'] ??
          payloadMap?['variableDeductions']) as Map<String, dynamic>?,
      customInputs: (json['customInputs'] ?? payloadMap?['customInputs'])
          as Map<String, dynamic>?,
      deductedInputs: (json['deductedInputs'] ?? payloadMap?['deductedInputs'])
          as Map<String, dynamic>?,
      deductedAmounts: (json['deductedAmounts'] ??
          payloadMap?['deductedAmounts']) as Map<String, dynamic>?,
      allowedInputs: json['allowedInputs'] as Map<String, dynamic>?,
      variableDetails: variableDetailsRaw != null
          ? (variableDetailsRaw as List)
              .map((i) => VariableDetail.fromJson(i))
              .toList()
          : null,
      deductionPercent: (json['deductionPercent'] ??
          payloadMap?['totalDeductionPercent']) as num?,
      deductionWeight:
          (json['deductionWeight'] ?? payloadMap?['deductionWeight']) as num?,
      deductionAmount:
          (json['deductionAmount'] ?? payloadMap?['deductionAmount']) as num?,
      perQtlLabDeduction: json['perQtlLabDeduction'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'billId': billId,
      'masterId': masterId,
      'label': label,
      'value': value,
      'payload': payload,
      'actualInputs': actualInputs,
      'defaultInputs': defaultInputs,
      'variableDeductions': variableDeductions,
      'perQtlLabDeduction': perQtlLabDeduction,
    };
  }
}

class BillSlip {
  final String? id;
  final String? billId;
  final String? slipNo;
  final List<BillSlipEntry>? entries;
  final String? createdAt;

  BillSlip({this.id, this.billId, this.slipNo, this.entries, this.createdAt});

  factory BillSlip.fromJson(Map<String, dynamic> json) {
    final entriesData =
        json['entries'] ?? json['billSlipEntries'] ?? json['weightSlipEntries'];
    return BillSlip(
      id: json['id'] as String?,
      billId: json['billId'] as String?,
      slipNo: json['slipNo'] as String?,
      entries: entriesData != null
          ? (entriesData as List).map((i) => BillSlipEntry.fromJson(i)).toList()
          : null,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'billId': billId,
      'slipNo': slipNo,
      'entries': entries?.map((i) => i.toJson()).toList(),
      'createdAt': createdAt,
    };
  }
}

class BillSlipEntry {
  final int? srNo;
  final num? gross;
  final num? tare;

  BillSlipEntry({this.srNo, this.gross, this.tare});

  factory BillSlipEntry.fromJson(Map<String, dynamic> json) {
    return BillSlipEntry(
      srNo: (json['srNo'] ?? json['snNo'] ?? json['sr_no']) is int
          ? (json['srNo'] ?? json['snNo'] ?? json['sr_no']) as int?
          : int.tryParse(
              (json['srNo'] ?? json['snNo'] ?? json['sr_no'])?.toString() ??
                  ''),
      gross: json['gross'] is num
          ? json['gross'] as num?
          : double.tryParse(json['gross']?.toString() ?? ''),
      tare: json['tare'] is num
          ? json['tare'] as num?
          : double.tryParse(json['tare']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'srNo': srNo,
      'gross': gross,
      'tare': tare,
    };
  }
}

class CalculationDetails {
  final num? totalQuantityReceived;
  final num? ratePerUnit;
  final num? bagWeight;
  final num? netWeightForLab;
  final num? goniDeductionAmount;
  final num? totalLabDeductionPercent;
  final num? totalLabDeductionWeight;
  final num? totalLabDeductionAmount;
  final num? totalFixedDeductionAmount;
  final num? finalNetPayableWeight;
  final num? amountAfterLab;
  final num? finalPayableAmount;
  final num? rateAfterLabDeduction;
  final num? rateAfterLabDeductionRounded;
  final num? recalculatedTotal;
  final num? pricedQuantity;
  final num? perQtlLabDeduction;

  CalculationDetails({
    this.totalQuantityReceived,
    this.ratePerUnit,
    this.bagWeight,
    this.netWeightForLab,
    this.goniDeductionAmount,
    this.totalLabDeductionPercent,
    this.totalLabDeductionWeight,
    this.totalLabDeductionAmount,
    this.totalFixedDeductionAmount,
    this.finalNetPayableWeight,
    this.amountAfterLab,
    this.finalPayableAmount,
    this.rateAfterLabDeduction,
    this.rateAfterLabDeductionRounded,
    this.recalculatedTotal,
    this.pricedQuantity,
    this.perQtlLabDeduction,
  });

  factory CalculationDetails.fromJson(Map<String, dynamic> json) {
    return CalculationDetails(
      totalQuantityReceived: json['totalQuantityReceived'] as num?,
      ratePerUnit: json['ratePerUnit'] as num?,
      bagWeight: json['bagWeight'] as num?,
      netWeightForLab: json['netWeightForLab'] as num?,
      goniDeductionAmount: json['goniDeductionAmount'] as num?,
      totalLabDeductionPercent: json['totalLabDeductionPercent'] as num?,
      totalLabDeductionWeight: json['totalLabDeductionWeight'] as num?,
      totalLabDeductionAmount: json['totalLabDeductionAmount'] as num?,
      totalFixedDeductionAmount: json['totalFixedDeductionAmount'] as num?,
      finalNetPayableWeight: json['finalNetPayableWeight'] as num?,
      amountAfterLab: json['amountAfterLab'] as num?,
      finalPayableAmount: json['finalPayableAmount'] as num?,
      rateAfterLabDeduction: json['rateAfterLabDeduction'] as num?,
      rateAfterLabDeductionRounded:
          json['rateAfterLabDeductionRounded'] as num?,
      recalculatedTotal: json['recalculatedTotal'] as num?,
      pricedQuantity: json['pricedQuantity'] as num?,
      perQtlLabDeduction: json['perQtlLabDeduction'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalQuantityReceived': totalQuantityReceived,
      'ratePerUnit': ratePerUnit,
      'bagWeight': bagWeight,
      'netWeightForLab': netWeightForLab,
      'goniDeductionAmount': goniDeductionAmount,
      'totalLabDeductionPercent': totalLabDeductionPercent,
      'totalLabDeductionWeight': totalLabDeductionWeight,
      'totalLabDeductionAmount': totalLabDeductionAmount,
      'totalFixedDeductionAmount': totalFixedDeductionAmount,
      'finalNetPayableWeight': finalNetPayableWeight,
      'amountAfterLab': amountAfterLab,
      'finalPayableAmount': finalPayableAmount,
      'rateAfterLabDeduction': rateAfterLabDeduction,
      'rateAfterLabDeductionRounded': rateAfterLabDeductionRounded,
      'recalculatedTotal': recalculatedTotal,
      'pricedQuantity': pricedQuantity,
      'perQtlLabDeduction': perQtlLabDeduction,
    };
  }
}

class VariableDetail {
  final String? code;
  final String? label;
  final num? actual;
  final num? custom;
  final num? deducted;
  final String? unitHint;
  final num? deductedWeight;
  final num? deductionValue;

  VariableDetail({
    this.code,
    this.label,
    this.actual,
    this.custom,
    this.deducted,
    this.unitHint,
    this.deductedWeight,
    this.deductionValue,
  });

  factory VariableDetail.fromJson(Map<String, dynamic> json) {
    return VariableDetail(
      code: json['code'] as String?,
      label: json['label'] as String?,
      actual: json['actual'] as num?,
      custom: json['custom'] as num?,
      deducted: json['deducted'] as num?,
      unitHint: json['unitHint']?.toString(),
      deductedWeight: json['deductedWeight'] as num?,
      deductionValue: json['deductionValue'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'label': label,
      'actual': actual,
      'custom': custom,
      'deducted': deducted,
      'unitHint': unitHint,
      'deductedWeight': deductedWeight,
      'deductionValue': deductionValue,
    };
  }
}

class PaymentModelDetail {
  final String? id;
  final num? amount;
  final String? status;
  final String? paidDate;
  final String? reference;

  PaymentModelDetail({
    this.id,
    this.amount,
    this.status,
    this.paidDate,
    this.reference,
  });

  factory PaymentModelDetail.fromJson(Map<String, dynamic> json) {
    return PaymentModelDetail(
      id: json['id'] as String?,
      amount: json['amount'] as num?,
      status: json['status'] as String?,
      paidDate: json['paidDate'] as String?,
      reference: json['reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'status': status,
      'paidDate': paidDate,
      'reference': reference,
    };
  }
}

class BillVendor {
  final String? id;
  final String? name;
  final String? phone;
  final String? grnNumber;
  final String? villageAdd;

  BillVendor({
    this.id,
    this.name,
    this.phone,
    this.grnNumber,
    this.villageAdd,
  });

  factory BillVendor.fromJson(Map<String, dynamic> json) {
    return BillVendor(
      id: json['id'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      grnNumber: json['grnNumber'] as String?,
      villageAdd: json['villageAdd'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'grnNumber': grnNumber,
      'villageAdd': villageAdd,
    };
  }
}

