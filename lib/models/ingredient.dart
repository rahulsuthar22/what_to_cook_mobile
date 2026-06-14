class IngredientModel {
  final int ingredientId;
  final String ingredientName;
  final String category;
  final String? quantity;

  IngredientModel({
    required this.ingredientId,
    required this.ingredientName,
    required this.category,
    this.quantity,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      ingredientId: json['ingredient_id'] ?? json['ingredientId'] ?? 0,
      ingredientName: json['ingredient_name'] ?? json['ingredientName'] ?? '',
      category: json['category'] ?? '',
      quantity: json['quantity'],
    );
  }
}
