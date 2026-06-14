import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import 'auth_provider.dart';

class RecipeProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  final AuthProvider authProvider;
  
  List<RecipeModel> _recipes = [];
  List<RecipeModel> _recommendedRecipes = [];
  final List<IngredientModel> _ingredients = [];
  final List<String> _selectedIngredients = [];
  
  bool _isLoading = false;
  String? _error;

  List<RecipeModel> get recipes => _recipes;
  List<RecipeModel> get recommendedRecipes => _recommendedRecipes;
  List<IngredientModel> get ingredients => _ingredients;
  List<String> get selectedIngredients => _selectedIngredients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RecipeProvider(this.authProvider) {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Automatically link session cookie from AuthProvider
        if (authProvider.isAuthenticated) {
          // Pass base url in sync
          _dio.options.baseUrl = authProvider.user != null ? authProvider.user!.uid.isNotEmpty ? ApiConfig.baseUrl : ApiConfig.baseUrl : ApiConfig.baseUrl;
        }
        return handler.next(options);
      },
    ));
  }

  void updateSession(String? cookie) {
    if (cookie != null) {
      _dio.options.headers['Cookie'] = cookie;
    }
  }

  // Toggle ingredient selection
  void toggleIngredient(String name) {
    if (_selectedIngredients.contains(name)) {
      _selectedIngredients.remove(name);
    } else {
      _selectedIngredients.add(name);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIngredients.clear();
    _recommendedRecipes.clear();
    notifyListeners();
  }

  // Fetch all recipes (for browse or admin)
  Future<void> fetchRecipes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _dio.get(ApiConfig.recipesEndpoint);
      if (res.statusCode == 200 && res.data['success'] == true) {
        var list = res.data['recipes'] as List;
        _recipes = list.map((r) => RecipeModel.fromJson(r)).toList();
      }
    } catch (e) {
      _error = 'Failed to load recipes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Find matches by posting selected ingredients
  Future<void> findMatches() async {
    if (_selectedIngredients.isEmpty) {
      _recommendedRecipes = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _dio.post(
        ApiConfig.recommendEndpoint,
        data: {
          'ingredients': _selectedIngredients,
        },
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        var list = res.data['recommendations'] as List;
        _recommendedRecipes = list.map((r) => RecipeModel.fromJson(r)).toList();
      }
    } catch (e) {
      _error = 'Failed to load recommendations: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new recipe (Admin utility)
  Future<bool> createRecipe({
    required String name,
    required String category,
    required int cookingTime,
    required String difficulty,
    required String instructions,
    required String imageUrl,
    required int calories,
    required List<Map<String, dynamic>> ingredients,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _dio.post(
        ApiConfig.recipesEndpoint,
        data: {
          'recipe_name': name,
          'category': category,
          'cooking_time': cookingTime,
          'difficulty_level': difficulty,
          'instructions': instructions,
          'image_url': imageUrl,
          'calories': calories,
          'ingredients': ingredients,
        },
      );

      _isLoading = false;
      notifyListeners();
      return res.statusCode == 200 && res.data['success'] == true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
