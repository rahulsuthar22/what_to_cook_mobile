import 'recipe.dart';

class MealPlanModel {
  final int planId;
  final String date;
  final String mealType;
  final RecipeModel recipe;

  MealPlanModel({
    required this.planId,
    required this.date,
    required this.mealType,
    required this.recipe,
  });

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    final recipeData = json['recipe'] ?? {
      'recipe_id': json['recipe_id'],
      'recipe_name': json['recipe_name'],
      'category': json['category'],
      'cooking_time': json['cooking_time'],
      'image_url': json['image_url'],
      'calories': json['calories'],
    };

    return MealPlanModel(
      planId: json['plan_id'] ?? json['planId'] ?? json['meal_plan_id'] ?? 0,
      date: json['date'] ?? json['meal_date'] ?? '',
      mealType: json['meal_type'] ?? json['mealType'] ?? 'Lunch',
      recipe: RecipeModel.fromJson(recipeData),
    );
  }
}
