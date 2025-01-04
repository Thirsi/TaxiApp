import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class SettingsService {
  DatabaseService? _databaseService;
  static const String _mileageRateKey = 'mileageRate';
  static const String _shiftChargeKey = 'shiftCharge';
  
  static const double defaultMileageRate = 0.85;
  static const double defaultShiftCharge = 5.0;

  final SharedPreferences _prefs;

  SettingsService(this._prefs) {
    _databaseService = DatabaseService(this);
  }

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  double get mileageRate => _prefs.getDouble(_mileageRateKey) ?? defaultMileageRate;
  double get shiftCharge => _prefs.getDouble(_shiftChargeKey) ?? defaultShiftCharge;

  Future<void> setMileageRate(double rate) async {
    await _prefs.setDouble(_mileageRateKey, rate);
  }

  Future<void> setShiftCharge(double charge) async {
    await _prefs.setDouble(_shiftChargeKey, charge);
  }

  Future<void> resetToDefaults() async {
    await _prefs.remove(_mileageRateKey);
    await _prefs.remove(_shiftChargeKey);
  }

  Future<void> clearDatabase() async {
    await _databaseService?.clearDatabase();
  }
}
