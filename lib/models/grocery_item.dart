class RecipeQuantity {
  final String recipe;
  final String quantity;

  RecipeQuantity({required this.recipe, required this.quantity});

  factory RecipeQuantity.fromJson(Map<String, dynamic> json) {
    return RecipeQuantity(
      recipe: json['recipe'] ?? '',
      quantity: json['quantity'] ?? '',
    );
  }
}

class GroceryItemModel {
  final int groceryId;
  final String itemName;
  final String quantity;
  final bool isCompleted;
  final List<String> usedIn;
  final List<RecipeQuantity> recipeQuantities;
  final String totalQuantity;

  GroceryItemModel({
    required this.groceryId,
    required this.itemName,
    required this.quantity,
    required this.isCompleted,
    this.usedIn = const [],
    this.recipeQuantities = const [],
    this.totalQuantity = '',
  });

  factory GroceryItemModel.fromJson(Map<String, dynamic> json) {
    // Parse used_in array
    List<String> parsedUsedIn = [];
    if (json['used_in'] != null && json['used_in'] is List) {
      parsedUsedIn = (json['used_in'] as List).map((e) => e.toString()).toList();
    }

    // Parse recipe_quantities array
    List<RecipeQuantity> parsedRecipeQty = [];
    if (json['recipe_quantities'] != null && json['recipe_quantities'] is List) {
      parsedRecipeQty = (json['recipe_quantities'] as List)
          .map((e) => RecipeQuantity.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return GroceryItemModel(
      groceryId: json['grocery_id'] ?? json['groceryId'] ?? 0,
      itemName: json['ingredient_name'] ?? json['item_name'] ?? json['itemName'] ?? '',
      quantity: json['quantity'] ?? '',
      isCompleted: json['is_completed'] ?? json['isCompleted'] ?? (json['status'] == 'Completed'),
      usedIn: parsedUsedIn,
      recipeQuantities: parsedRecipeQty,
      totalQuantity: json['total_quantity'] ?? json['quantity'] ?? '',
    );
  }
}
