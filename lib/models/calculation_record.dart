import 'package:hive/hive.dart';

part 'calculation_record.g.dart';

@HiveType(typeId: 0)
class CalculationRecord extends HiveObject {
  @HiveField(0)
  int? id;
  
  @HiveField(1)
  late String expression;
  
  @HiveField(2)
  late String result;
  
  @HiveField(3)
  late DateTime createdAt;

  // Required empty constructor for Hive
  CalculationRecord();

  // Factory method to create a new record
  factory CalculationRecord.create({
    required String expression,
    required String result,
    DateTime? createdAt,
  }) {
    final record = CalculationRecord()
      ..expression = expression
      ..result = result
      ..createdAt = createdAt ?? DateTime.now();
    return record;
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expression': expression,
      'result': result,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create from Map
  factory CalculationRecord.fromMap(Map<String, dynamic> map) {
    return CalculationRecord.create(
      expression: map['expression'] ?? '',
      result: map['result'] ?? '',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    )..id = map['id'];
  }
}
