class InventoryLocation {
  final String id;
  final String name;
  final String code;
  final String type; // VENDOR, GODOWN, PLANT
  final bool isActive;
  final String? vendorId;

  InventoryLocation({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.isActive,
    this.vendorId,
  });

  factory InventoryLocation.fromJson(Map<String, dynamic> json) {
    return InventoryLocation(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      type: json['type'] ?? '',
      isActive: json['isActive'] ?? false,
      vendorId: json['vendorId'] ?? json['vendor']?['id'] ?? json['vendor']?['_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'type': type,
      'isActive': isActive,
      if (vendorId != null) 'vendorId': vendorId,
    };
  }
}
