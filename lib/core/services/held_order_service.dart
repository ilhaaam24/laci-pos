import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/entities/held_order_entity.dart';
import 'printer_service.dart';

/// Service to manage held / open orders with offline persistence and reactive notifiers.
class HeldOrderService {
  static final HeldOrderService _instance = HeldOrderService._internal();
  factory HeldOrderService() => _instance;
  HeldOrderService._internal();

  static const String _storageKey = 'laci_held_orders_v1';

  final List<HeldOrder> _cachedOrders = [];

  /// ValueNotifier for instant badge updates in the app header and UI.
  final ValueNotifier<int> heldOrderCountNotifier = ValueNotifier<int>(0);

  /// ValueNotifier with the full list of active held orders.
  final ValueNotifier<List<HeldOrder>> heldOrdersNotifier =
      ValueNotifier<List<HeldOrder>>([]);

  /// Unmodifiable view of currently cached held orders.
  List<HeldOrder> get currentHeldOrders =>
      List<HeldOrder>.unmodifiable(_cachedOrders);

  /// Convenience getter for the held orders list.
  List<HeldOrder> get heldOrders => currentHeldOrders;

  /// Convenience getter for the total number of held orders.
  int get heldOrderCount => _cachedOrders.length;

  /// Find a held order by its ID.
  HeldOrder? getHeldOrder(String id) {
    try {
      return _cachedOrders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Convenience alias to clear all held orders.
  Future<void> clearAllHeldOrders() => clearAll();

  /// Initialize and load saved orders from SharedPreferences.
  Future<void> init() async {
    await _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.trim().isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
        _cachedOrders.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _cachedOrders.add(HeldOrder.fromJson(item));
          }
        }
        // Sort by most recently updated first
        _cachedOrders.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      } else {
        _cachedOrders.clear();
      }
    } catch (e) {
      debugPrint('HeldOrderService._loadFromStorage error: $e');
      _cachedOrders.clear();
    } finally {
      _notify();
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _cachedOrders.map((o) => o.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('HeldOrderService._saveToStorage error: $e');
    }
  }

  void _notify() {
    heldOrderCountNotifier.value = _cachedOrders.length;
    heldOrdersNotifier.value = List<HeldOrder>.unmodifiable(_cachedOrders);
  }

  /// Get all active held orders.
  Future<List<HeldOrder>> getHeldOrders() async {
    if (_cachedOrders.isEmpty) {
      await _loadFromStorage();
    }
    return currentHeldOrders;
  }

  /// Save or update a held order.
  Future<void> saveHeldOrder(HeldOrder order) async {
    final index = _cachedOrders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      _cachedOrders[index] = order;
    } else {
      _cachedOrders.insert(0, order);
    }
    _cachedOrders.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _notify();
    await _saveToStorage();
  }

  /// Remove a held order by ID (e.g. after it is paid or cancelled).
  Future<void> removeHeldOrder(String id) async {
    _cachedOrders.removeWhere((o) => o.id == id);
    _notify();
    await _saveToStorage();
  }

  /// Clear all held orders.
  Future<void> clearAll() async {
    _cachedOrders.clear();
    _notify();
    await _saveToStorage();
  }

  /// Prints a pro-forma / temporary check slip for the customer's table before payment.
  Future<bool> printProformaBill({
    required HeldOrder order,
    BusinessInfo? businessInfo,
  }) async {
    final printerService = PrinterService();
    if (!printerService.isConnected) return false;

    return await printerService.printHeldOrderProforma(
      order: order,
      businessInfo: businessInfo,
    );
  }
}
