import 'package:soya_app/features/home/model/goni_type_model.dart';
import 'package:soya_app/features/home/model/inventory_location_model.dart';
import 'package:soya_app/features/home/model/thappi_model.dart';

class VendorTransferListModel {
  final bool? success;
  final String? message;
  final VendorTransferDataWrapper? data;

  VendorTransferListModel({
    this.success,
    this.message,
    this.data,
  });

  factory VendorTransferListModel.fromJson(Map<String, dynamic> json) {
    return VendorTransferListModel(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? VendorTransferDataWrapper.fromJson(json['data'])
          : null,
    );
  }
}

class VendorTransferDataWrapper {
  final List<VendorTransferData>? transfers;
  final Pagination? pagination;

  VendorTransferDataWrapper({this.transfers, this.pagination});

  factory VendorTransferDataWrapper.fromJson(Map<String, dynamic> json) {
    return VendorTransferDataWrapper(
      transfers: json['transfers'] != null
          ? (json['transfers'] as List)
              .map((i) => VendorTransferData.fromJson(i))
              .toList()
          : null,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class VendorTransferData {
  final String? id;
  final String? transferNo;
  final String? vendorId;
  final String? goniTypeId;
  final double? vendorEnteredWeight;
  final String? vendorEnteredUnit;
  final double? adminAdjustedWeight;
  final String? adminAdjustedUnit;
  final String? adminAdjustedAt;
  final double? weight;
  final String? unit;
  final String? shopName; // Keep for backwards compatibility
  final String? shopLocation; // Keep for backwards compatibility
  final String? sourceLocationId;
  final String? destinationLocationId;
  final InventoryLocation? sourceLocation;
  final InventoryLocation? destinationLocation;
  final List<Thappi>? thappis;
  final String? vehicalNumber;
  final int? bagCount;
  final String? status;
  final String? createdAt;
  final String? completedAt;
  final VendorShort? vendor;
  final VendorShort? toVendor; // Added toVendor support
  final GoniType? goniType;
  final List<TransferItem>? items;

  // GPS & verification details
  final double? dispatchLatitude;
  final double? dispatchLongitude;
  final String? dispatchLocationText;
  final double? receiveLatitude;
  final double? receiveLongitude;
  final String? receiveLocationText;
  final double? receivedWeight;
  final String? receivedUnit;
  final int? receivedBagCount;
  final double? weightDifference;
  final int? bagDifference;
  final double? dispatchedWeight;
  final int? dispatchedBagCount;

  VendorTransferData({
    this.id,
    this.transferNo,
    this.vendorId,
    this.goniTypeId,
    this.vendorEnteredWeight,
    this.vendorEnteredUnit,
    this.adminAdjustedWeight,
    this.adminAdjustedUnit,
    this.adminAdjustedAt,
    this.weight,
    this.unit,
    this.shopName,
    this.shopLocation,
    this.sourceLocationId,
    this.destinationLocationId,
    this.sourceLocation,
    this.destinationLocation,
    this.thappis,
    this.vehicalNumber,
    this.bagCount,
    this.status,
    this.createdAt,
    this.completedAt,
    this.vendor,
    this.toVendor,
    this.goniType,
    this.items,
    this.dispatchLatitude,
    this.dispatchLongitude,
    this.dispatchLocationText,
    this.receiveLatitude,
    this.receiveLongitude,
    this.receiveLocationText,
    this.receivedWeight,
    this.receivedUnit,
    this.receivedBagCount,
    this.weightDifference,
    this.bagDifference,
    this.dispatchedWeight,
    this.dispatchedBagCount,
  });

  factory VendorTransferData.fromJson(Map<String, dynamic> json) {
    return VendorTransferData(
      id: json['id'] ?? json['_id'],
      transferNo: json['transferNo'],
      vendorId: json['vendorId'],
      goniTypeId: json['goniTypeId'],
      vendorEnteredWeight: (json['vendorEnteredWeight'] as num?)?.toDouble(),
      vendorEnteredUnit: json['vendorEnteredUnit'],
      adminAdjustedWeight: (json['adminAdjustedWeight'] as num?)?.toDouble(),
      adminAdjustedUnit: json['adminAdjustedUnit'],
      adminAdjustedAt: json['adminAdjustedAt'],
      weight: (json['weight'] as num?)?.toDouble(),
      unit: json['unit'],
      shopName: json['shopName'],
      shopLocation: json['shopLocation'],
      sourceLocationId: json['sourceLocationId'],
      destinationLocationId: json['destinationLocationId'],
      sourceLocation: json['sourceLocation'] != null
          ? InventoryLocation.fromJson(json['sourceLocation'])
          : null,
      destinationLocation: json['destinationLocation'] != null
          ? InventoryLocation.fromJson(json['destinationLocation'])
          : null,
      thappis: json['thappis'] != null
          ? (json['thappis'] as List).map((i) => Thappi.fromJson(i)).toList()
          : null,
      vehicalNumber: json['vehicalNumber'] ?? json['vehicalNo'],
      bagCount: json['bagCount'],
      status: json['status'],
      createdAt: json['createdAt'],
      completedAt: json['completedAt'],
      vendor:
          json['vendor'] != null ? VendorShort.fromJson(json['vendor']) : null,
      toVendor: json['toVendor'] != null
          ? VendorShort.fromJson(json['toVendor'])
          : null,
      goniType:
          json['goniType'] != null ? GoniType.fromJson(json['goniType']) : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((i) => TransferItem.fromJson(i))
              .toList()
          : null,
      dispatchLatitude: (json['dispatchLatitude'] as num?)?.toDouble(),
      dispatchLongitude: (json['dispatchLongitude'] as num?)?.toDouble(),
      dispatchLocationText: json['dispatchLocationText'],
      receiveLatitude: (json['receiveLatitude'] as num?)?.toDouble(),
      receiveLongitude: (json['receiveLongitude'] as num?)?.toDouble(),
      receiveLocationText: json['receiveLocationText'],
      receivedWeight: (json['receivedWeight'] as num?)?.toDouble(),
      receivedUnit: json['receivedUnit'],
      receivedBagCount: json['receivedBagCount'] as int?,
      weightDifference:
          ((json['weightShortage'] ?? json['weightDifference']) as num?)
              ?.toDouble(),
      bagDifference: (json['bagShortage'] ?? json['bagDifference']) as int?,
      dispatchedWeight: (json['dispatchedWeight'] as num?)?.toDouble(),
      dispatchedBagCount: json['dispatchedBagCount'] as int?,
    );
  }
}

class VendorShort {
  final String? id;
  final String? name;
  final String? phone;

  VendorShort({this.id, this.name, this.phone});

  factory VendorShort.fromJson(Map<String, dynamic> json) {
    return VendorShort(
      id: json['id'] ?? json['_id'],
      name: json['name'],
      phone: json['phone'],
    );
  }
}

class TransferItem {
  final String? id;
  final String? transferId;
  final String? goniTypeId;
  final int? bagCount;
  final String? createdAt;
  final GoniType? goniType;

  TransferItem({
    this.id,
    this.transferId,
    this.goniTypeId,
    this.bagCount,
    this.createdAt,
    this.goniType,
  });

  factory TransferItem.fromJson(Map<String, dynamic> json) {
    return TransferItem(
      id: json['id'] ?? json['_id'],
      transferId: json['transferId'],
      goniTypeId: json['goniTypeId'],
      bagCount: json['bagCount'],
      createdAt: json['createdAt'],
      goniType:
          json['goniType'] != null ? GoniType.fromJson(json['goniType']) : null,
    );
  }
}

class Pagination {
  final int? page;
  final int? limit;
  final int? total;
  final int? totalPages;

  Pagination({this.page, this.limit, this.total, this.totalPages});

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      totalPages: json['totalPages'],
    );
  }
}
