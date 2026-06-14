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
    this.matchPercentage,
    this.matchedCount,
    this.totalCount,
    this.missingIngredients,
    this.ingredients,
  });

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
      recipeId: json['recipe_id'] ?? json['recipeId'] ?? 0,
      recipeName: json['recipe_name'] ?? json['recipeName'] ?? '',
      category: json['category'] ?? 'None',
      cookingTime: json['cooking_time'] ?? json['cookingTime'] ?? 0,
      difficultyLevel: json['difficulty_level'] ?? json['difficultyLevel'] ?? 'Easy',
      instructions: json['instructions'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      calories: json['calories'] ?? 0,
      matchPercentage: json['match_percentage'] != null 
          ? double.tryParse(json['match_percentage'].toString()) 
          : null,
      matchedCount: json['matched_count'] ?? json['matchedCount'],
      totalCount: json['total_count'] ?? json['totalCount'],
      missingIngredients: parsedMissing,
      ingredients: parsedIngredients,
    );
  }
}
