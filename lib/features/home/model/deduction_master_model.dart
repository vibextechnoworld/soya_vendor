class DeductionMasterModel {
  final bool? success;
  final String? message;
  final List<DeductionMaster>? data;

  DeductionMasterModel({
    this.success,
    this.message,
    this.data,
  });

  factory DeductionMasterModel.fromJson(Map<String, dynamic> json) {
    return DeductionMasterModel(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? (json['data'] as List)
              .map((i) => DeductionMaster.fromJson(i))
              .toList()
          : null,
    );
  }
}

class DeductionMaster {
  final String? id;
  final String? name;
  final String? type; // e.g., "FORMULA", "FIXED"
  final double? baseAmount;
  final double? persent;
  final String? formulaExpression;
  final bool? isActive;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final List<DeductionVariable>? variables;
  final List<String>? variableValues;
  final String? percentRatio;

  DeductionMaster({
    this.id,
    this.name,
    this.type,
    this.baseAmount,
    this.persent,
    this.formulaExpression,
    this.isActive,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.variables,
    this.variableValues,
    this.percentRatio,
  });

  factory DeductionMaster.fromJson(Map<String, dynamic> json) {
    return DeductionMaster(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      baseAmount: json['baseAmount']?.toDouble(),
      formulaExpression: json['formulaExpression'],
      persent: json['persent']?.toDouble(),
      isActive: json['isActive'] == true,
      createdBy: json['createdBy'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      variables: json['variables'] != null
          ? (json['variables'] as List)
              .map((i) => DeductionVariable.fromJson(i))
              .toList()
          : null,
      variableValues: json['variableValues'] != null
          ? (json['variableValues'] as List).map((e) => e.toString()).toList()
          : null,
      percentRatio: json['percentRatio'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeductionMaster && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class DeductionVariable {
  final String? id;
  final String? masterId;
  final String? code;
  final String? label;
  final String? unitHint;
  final String? createdAt;

  DeductionVariable({
    this.id,
    this.masterId,
    this.code,
    this.label,
    this.unitHint,
    this.createdAt,
  });

  factory DeductionVariable.fromJson(Map<String, dynamic> json) {
    return DeductionVariable(
      id: json['id'],
      masterId: json['masterId'],
      code: json['code'],
      label: json['label'],
      unitHint: json['unitHint'],
      createdAt: json['createdAt'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeductionVariable && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
