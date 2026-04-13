// lib/services/settings_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/app_settings.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';

  static Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsJson = prefs.getString(_settingsKey);
    
    if (settingsJson != null) {
      return AppSettings.fromJson(jsonDecode(settingsJson));
    }
    return AppSettings(bookingType: AppConstants.bookingType ?? '1');
  }

  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    
    // Update the global AppConstants
    AppConstants.bookingType = settings.bookingType;
  }


  static Future<void> saveBookingType(String type) async {
    final settings = await getSettings();
    settings.bookingType = type;
    await saveSettings(settings);
  }
}