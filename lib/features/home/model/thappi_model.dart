class Thappi {
  final String id;
  final String locationId;
  final String code;
  final double weightQtl;
  final double moisture;
  final double fm;
  final double damage;
  final String? imageUrl;
  final String? status;
  final List<ThappiBagBreakdown> bagBreakdown;

  Thappi({
    required this.id,
    required this.locationId,
    required this.code,
    required this.weightQtl,
    required this.moisture,
    required this.fm,
    required this.damage,
    this.imageUrl,
    this.status,
    required this.bagBreakdown,
  });

  factory Thappi.fromJson(Map<String, dynamic> json) {
    // If it's a junction record, extract properties from the nested 'thappi' key
    final Map<String, dynamic> thappiJson = json['thappi'] is Map<String, dynamic>
        ? json['thappi'] as Map<String, dynamic>
        : json;

    final String thappiId = json['thappiId'] ?? thappiJson['id'] ?? thappiJson['_id'] ?? json['id'] ?? json['_id'] ?? '';

    var breakdownList = (thappiJson['bagBreakdown'] ?? json['bagBreakdown']) as List? ?? [];
    List<ThappiBagBreakdown> breakdown = breakdownList
        .map((x) => ThappiBagBreakdown.fromJson(x))
        .toList();

    return Thappi(
      id: thappiId,
      locationId: thappiJson['locationId'] ?? thappiJson['location']?['_id'] ?? thappiJson['location']?['id'] ?? '',
      code: thappiJson['code'] ?? '',
      weightQtl: (json['weightQtl'] as num?)?.toDouble() ?? (thappiJson['weightQtl'] as num?)?.toDouble() ?? 0.0,
      moisture: (thappiJson['moisture'] as num?)?.toDouble() ?? 0.0,
      fm: (thappiJson['fm'] as num?)?.toDouble() ?? 0.0,
      damage: (thappiJson['damage'] as num?)?.toDouble() ?? 0.0,
      imageUrl: thappiJson['imageUrl'] ?? json['imageUrl'],
      status: thappiJson['status'] ?? json['status'],
      bagBreakdown: breakdown,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'locationId': locationId,
      'code': code,
      'weightQtl': weightQtl,
      'moisture': moisture,
      'fm': fm,
      'damage': damage,
      'imageUrl': imageUrl,
      'status': status,
      'bagBreakdown': bagBreakdown.map((x) => x.toJson()).toList(),
    };
  }
}

class ThappiBagBreakdown {
  final String goniTypeId;
  final int bagCount;
  final String? name;

  ThappiBagBreakdown({
    required this.goniTypeId,
    required this.bagCount,
    this.name,
  });

  factory ThappiBagBreakdown.fromJson(Map<String, dynamic> json) {
    return ThappiBagBreakdown(
      goniTypeId: json['goniTypeId'] ?? json['goniType']?['_id'] ?? json['goniType']?['id'] ?? '',
      bagCount: json['bagCount'] ?? 0,
      name: json['name'] ?? json['goniTypeName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goniTypeId': goniTypeId,
      'bagCount': bagCount,
      if (name != null) 'name': name,
    };
  }
}
