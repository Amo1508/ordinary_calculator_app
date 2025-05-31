import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/calculation_record.dart';

/// Service class for handling database operations using Hive
/// Handles CRUD operations for CalculationRecord objects

class HiveDatabaseService {
  static const String _boxName = 'calculationsBox';
  static Box<CalculationRecord>? _box;
  
  /// Initialize Hive and open the box
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CalculationRecordAdapter());
      }
      
      _box = await Hive.openBox<CalculationRecord>(_boxName);
    } catch (e) {
      throw Exception('Failed to initialize Hive: $e');
    }
  }
  
  /// Save a calculation record to the database
  static Future<void> saveCalculation(CalculationRecord record) async {
    try {
      if (_box == null) await init();
      await _box!.add(record);
    } catch (e) {
      throw Exception('Failed to save calculation: $e');
    }
  }
  
  /// Get all calculation records, sorted by creation date (newest first)
  static Future<List<CalculationRecord>> getCalculations() async {
    try {
      if (_box == null) await init();
      final records = _box!.values.toList();
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (e) {
      throw Exception('Failed to get calculations: $e');
    }
  }
  
  /// Delete a specific calculation record
  static Future<void> deleteCalculation(CalculationRecord record) async {
    try {
      if (_box == null) await init();
      if (record.key != null) {
        await _box!.delete(record.key);
      }
    } catch (e) {
      throw Exception('Failed to delete calculation: $e');
    }
  }
  
  /// Clear all calculation records
  static Future<void> clearAll() async {
    try {
      if (_box == null) await init();
      await _box!.clear();
    } catch (e) {
      throw Exception('Failed to clear calculations: $e');
    }
  }
  
  static Future<void> close() async {
    await Hive.close();
  }
}
