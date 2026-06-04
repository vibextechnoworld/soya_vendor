import 'farmer_model.dart';

class FarmerListModel {
  final bool? success;
  final String? message;
  final List<FarmerData>? data;
  final int? currentPage;
  final int? totalPages;
  final int? totalItems;
  final int? limit;

  FarmerListModel({
    this.success,
    this.message,
    this.data,
    this.currentPage,
    this.totalPages,
    this.totalItems,
    this.limit,
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

  factory FarmerListModel.fromJson(Map<String, dynamic> json) {
    final jsonData = json['data'];
    return FarmerListModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: (() {
        final possibleData = json['data'] ?? json;
        if (possibleData is Map) {
          final list = possibleData['farmers'] ??
              possibleData['data'] ??
              possibleData['docs'] ??
              possibleData['results'] ??
              possibleData['items'];
          if (list is List) {
            return list
                .map<FarmerData>(
                    (i) => FarmerData.fromJson(i as Map<String, dynamic>))
                .toList();
          }
          // If no list found in Map, check if any of the root keys themselves are lists
          if (json['farmers'] is List) {
            return (json['farmers'] as List)
                .map<FarmerData>(
                    (i) => FarmerData.fromJson(i as Map<String, dynamic>))
                .toList();
          }
        } else if (possibleData is List) {
          return possibleData
              .map((i) => FarmerData.fromJson(i as Map<String, dynamic>))
              .toList();
        }
        return <FarmerData>[];
      })(),
      currentPage: _parsePageInfo(json, ['page', 'currentPage', 'current_page'],
          jsonData is Map ? jsonData : null),
      totalPages: _parsePageInfo(json, ['totalPages', 'total_pages', 'pages'],
          jsonData is Map ? jsonData : null),
      totalItems: _parsePageInfo(
          json,
          ['total', 'totalItems', 'total_items', 'count'],
          jsonData is Map ? jsonData : null),
      limit: _parsePageInfo(json, ['limit', 'per_page', 'pageSize'],
          jsonData is Map ? jsonData : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((i) => i.toJson()).toList(),
    };
  }
}
