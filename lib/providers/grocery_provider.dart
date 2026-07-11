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
    } else {
      _dio.options.headers.remove('Cookie');
    }
  }

  Future<void> fetchGroceryItems() async {
    final uid = authProvider.user?.uid;
    if (uid == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _dio.get(
        ApiConfig.groceryEndpoint,
        queryParameters: {'user_id': uid},
      );
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
    final uid = authProvider.user?.uid;
    if (uid == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _dio.post(
        ApiConfig.groceryGenerateEndpoint,
        data: {
          'user_id': uid,
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
    final uid = authProvider.user?.uid;
    if (uid == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final res = await _dio.post(
        ApiConfig.groceryEndpoint,
        data: {
          'user_id': uid,
          'ingredient_name': name,
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
          'status': !currentStatus ? 'Completed' : 'Pending',
        },
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        // Toggle locally immediately for instant UI feedback
        final index = _groceryItems.indexWhere((item) => item.groceryId == groceryId);
        if (index != -1) {
          _groceryItems[index] = GroceryItemModel(
            groceryId: groceryId,
            itemName: _groceryItems[index].itemName,
            quantity: _groceryItems[index].quantity,
            isCompleted: !currentStatus,
            usedIn: _groceryItems[index].usedIn,
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
    final uid = authProvider.user?.uid;
    if (uid == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final res = await _dio.delete(
        ApiConfig.groceryEndpoint,
        queryParameters: {
          'user_id': uid,
          'clear': 'true',
        },
      );
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
