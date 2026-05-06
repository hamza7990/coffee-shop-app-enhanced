import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/coffee_table.dart';
import '../models/order.dart';

class LocalStorageRepository {
  static const _tablesKey = 'tables_data';
  static const _activeOrdersKey = 'active_orders_data';
  static const _completedOrdersKey = 'completed_orders_data';
  static const _themeKey = 'theme_mode';
  static const _authTokenKey = 'auth_token';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  LocalStorageRepository(this._prefs, this._secureStorage);

  static Future<LocalStorageRepository> init() async {
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();
    return LocalStorageRepository(prefs, secureStorage);
  }

  // --- Auth Token ---
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: _authTokenKey, value: token);
  }

  Future<String?> loadAuthToken() async {
    return await _secureStorage.read(key: _authTokenKey);
  }

  Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: _authTokenKey);
  }

  // --- Theme ---
  Future<void> saveThemeMode(bool isDark) async {
    await _prefs.setBool(_themeKey, isDark);
  }

  bool? loadThemeMode() {
    return _prefs.getBool(_themeKey);
  }

  // --- Tables ---
  Future<void> saveTables(List<CoffeeTable> tables) async {
    final List<Map<String, dynamic>> jsonList = tables.map((t) => t.toJson()).toList();
    await _prefs.setString(_tablesKey, jsonEncode(jsonList));
  }

  List<CoffeeTable>? loadTables() {
    final str = _prefs.getString(_tablesKey);
    if (str == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((e) => CoffeeTable.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  // --- Orders ---
  Future<void> saveActiveOrders(List<Order> orders) async {
    final List<Map<String, dynamic>> jsonList = orders.map((o) => o.toJson()).toList();
    await _prefs.setString(_activeOrdersKey, jsonEncode(jsonList));
  }

  List<Order>? loadActiveOrders() {
    final str = _prefs.getString(_activeOrdersKey);
    if (str == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> saveCompletedOrders(List<Order> orders) async {
    final List<Map<String, dynamic>> jsonList = orders.map((o) => o.toJson()).toList();
    await _prefs.setString(_completedOrdersKey, jsonEncode(jsonList));
  }

  List<Order>? loadCompletedOrders() {
    final str = _prefs.getString(_completedOrdersKey);
    if (str == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }
}
