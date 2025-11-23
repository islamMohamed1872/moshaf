import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static Future<bool> putBoolean({
    required String key,
    required bool value,
  }) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setBool(key, value);
  }

  static Future<bool> putList({
    required String key,
    required List<String> value,
  }) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setStringList(key, value);
  }

  static dynamic getData({required String key}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    final value = sharedPreferences.get(key);
    // ✅ Try to decode JSON if it's a stringified object
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        return decoded;
      } catch (_) {
        return value; // plain string
      }
    }
    return value;
  }

  static Future<bool> saveData({
    required String key,
    required dynamic value,
  }) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (value is String) {
      return await sharedPreferences.setString(key, value);
    }
    if (value is int) {
      return await sharedPreferences.setInt(key, value);
    }
    if (value is double) {
      return await sharedPreferences.setDouble(key, value);
    }
    if (value is bool) {
      return await sharedPreferences.setBool(key, value);
    }
    if (value is List<String>) {
      return await sharedPreferences.setStringList(key, value);
    }
    return await sharedPreferences.setString(key, jsonEncode(value));
  }

  static Future<bool> deleteData({required String key}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.remove(key);
  }

  static Future<bool> saveMap({
    required Map<String, dynamic> myMap,
    required key,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(myMap);
    return await prefs.setString(key, jsonString);
  }

  static Future<Map<String, dynamic>?> getMap({required key}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(key);
    if (jsonString != null) {
      Map<String, dynamic> myMap = jsonDecode(jsonString);
      return myMap;
    } else {
      return null; // Return an empty map or handle the case when no data is available.
    }
  }
}
