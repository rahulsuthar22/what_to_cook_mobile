import 'ingredient.dart';

class RecipeModel {
  final int recipeId;
  final String recipeName;
  final String category;
  final int cookingTime;
  final String difficultyLevel;
  final String instructions;
  final String imageUrl;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String vitamins;
  final String videoUrl;
  
  // Scoring parameters for recommendations
  final double? matchPercentage;
  final int? matchedCount;
  final int? totalCount;
  final List<String>? missingIngredients;
  final List<IngredientModel>? ingredients;

  RecipeModel({
    required this.recipeId,
    required this.recipeName,
    required this.category,
    required this.cookingTime,
    required this.difficultyLevel,
    required this.instructions,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.vitamins,
    required this.videoUrl,
    this.matchPercentage,
    this.matchedCount,
    this.totalCount,
    this.missingIngredients,
    this.ingredients,
  });

  static double _doubleFromJson(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int _intFromJson(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    var ingList = json['ingredients'] as List?;
    List<IngredientModel>? parsedIngredients = ingList
        ?.map((i) => IngredientModel.fromJson(i))
        .toList();

    var missingList = json['missing_ingredients'] as List?;
    List<String>? parsedMissing = missingList
        ?.map((m) => m.toString())
        .toList();

    return RecipeModel(
      recipeId: _intFromJson(json['recipe_id'] ?? json['recipeId']),
      recipeName: json['recipe_name'] ?? json['recipeName'] ?? '',
      category: json['category'] ?? 'None',
      cookingTime: _intFromJson(json['cooking_time'] ?? json['cookingTime']),
      difficultyLevel: json['difficulty_level'] ?? json['difficultyLevel'] ?? 'Easy',
      instructions: json['instructions'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      calories: _intFromJson(json['calories']),
      protein: _doubleFromJson(json['protein']),
      carbs: _doubleFromJson(json['carbs']),
      fat: _doubleFromJson(json['fat']),
      fiber: _doubleFromJson(json['fiber']),
      vitamins: json['vitamins'] ?? '',
      videoUrl: json['video_url'] ?? json['videoUrl'] ?? '',
      matchPercentage: json['match_percentage'] != null 
          ? double.tryParse(json['match_percentage'].toString()) 
          : null,
      matchedCount: json['matched_count'] != null ? _intFromJson(json['matched_count']) : null,
      totalCount: json['total_count'] != null ? _intFromJson(json['total_count']) : null,
      missingIngredients: parsedMissing,
      ingredients: parsedIngredients,
    );
  }
}
