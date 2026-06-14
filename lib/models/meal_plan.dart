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
    return MealPlanModel(
      planId: json['plan_id'] ?? json['planId'] ?? 0,
      date: json['date'] ?? '',
      mealType: json['meal_type'] ?? json['mealType'] ?? 'Lunch',
      recipe: RecipeModel.fromJson(json['recipe'] ?? {}),
    );
  }
}
