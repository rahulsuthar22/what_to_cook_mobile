import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/grocery_item.dart';
import 'auth_provider.dart';

class GroceryProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final AuthProvider authProvider;
  
  List<GroceryItemModel> _groceryItems = [];
  bool _isLoading = false;
  String? _error;

  List<GroceryItemModel> get groceryItems => _groceryItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  GroceryProvider(this.authProvider) {
    _dio.options.baseUrl = ApiConfig.baseUrl;
  }

  void updateSession(String? cookie) {
    if (cookie != null) {
      _dio.options.headers['Cookie'] = cookie;
    }
  }

  Future<void> fetchGroceryItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _dio.get(ApiConfig.groceryEndpoint);
      if (res.statusCode == 200 && res.data['success'] == true) {
        var list = res.data['groceryList'] as List;
        _groceryItems = list.map((g) => GroceryItemModel.fromJson(g)).toList();
      }
    } catch (e) {
      _error = 'Failed to load grocery items: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> generateFromPlanner(String startDate, String endDate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _dio.post(
        ApiConfig.groceryGenerateEndpoint,
        data: {
          'start_date': startDate,
          'end_date': endDate,
        },
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        await fetchGroceryItems();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addCustomItem(String name, String quantity) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _dio.post(
        ApiConfig.groceryEndpoint,
        data: {
          'item_name': name,
          'quantity': quantity,
        },
      );

      if (res.statusCode == 201 && res.data['success'] == true) {
        await fetchGroceryItems();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleItemStatus(int groceryId, bool currentStatus) async {
    try {
      final res = await _dio.put(
        ApiConfig.groceryEndpoint,
        data: {
          'grocery_id': groceryId,
          'is_completed': !currentStatus,
        },
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        // Toggle locally immediately for instant UI feedback
        final index = _groceryItems.indexWhere((item) => item.groceryId == groceryId);
        if (index != -index) {
          _groceryItems[index] = GroceryItemModel(
            groceryId: groceryId,
            itemName: _groceryItems[index].itemName,
            quantity: _groceryItems[index].quantity,
            isCompleted: !currentStatus,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Toggle item status error: $e');
      return false;
    }
  }

  Future<bool> clearAllItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _dio.delete(ApiConfig.groceryEndpoint);
      if (res.statusCode == 200 && res.data['success'] == true) {
        _groceryItems.clear();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
