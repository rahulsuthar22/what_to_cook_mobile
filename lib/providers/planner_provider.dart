import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/meal_plan.dart';
import 'auth_provider.dart';

class PlannerProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final AuthProvider authProvider;
  
  List<MealPlanModel> _mealPlans = [];
  bool _isLoading = false;
  String? _error;

  List<MealPlanModel> get mealPlans => _mealPlans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PlannerProvider(this.authProvider) {
    _dio.options.baseUrl = ApiConfig.baseUrl;
  }

  void updateSession(String? cookie) {
    if (cookie != null) {
      _dio.options.headers['Cookie'] = cookie;
    }
  }

  Future<void> fetchMealPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _dio.get(ApiConfig.plannerEndpoint);
      if (res.statusCode == 200 && res.data['success'] == true) {
        var list = res.data['mealPlans'] as List;
        _mealPlans = list.map((m) => MealPlanModel.fromJson(m)).toList();
      }
    } catch (e) {
      _error = 'Failed to load meal plans: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> scheduleMeal({
    required int recipeId,
    required String date,
    required String mealType,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _dio.post(
        ApiConfig.plannerEndpoint,
        data: {
          'recipe_id': recipeId,
          'date': date,
          'meal_type': mealType,
        },
      );

      if (res.statusCode == 201 && res.data['success'] == true) {
        await fetchMealPlans();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMealPlan(int planId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _dio.delete(
        ApiConfig.plannerEndpoint,
        data: {
          'plan_id': planId,
        },
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        _mealPlans.removeWhere((element) => element.planId == planId);
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
