class GroceryItemModel {
  final int groceryId;
  final String itemName;
  final String quantity;
  final bool isCompleted;

  GroceryItemModel({
    required this.groceryId,
    required this.itemName,
    required this.quantity,
    required this.isCompleted,
  });

  factory GroceryItemModel.fromJson(Map<String, dynamic> json) {
    return GroceryItemModel(
      groceryId: json['grocery_id'] ?? json['groceryId'] ?? 0,
      itemName: json['item_name'] ?? json['itemName'] ?? '',
      quantity: json['quantity'] ?? '',
      isCompleted: json['is_completed'] ?? json['isCompleted'] ?? false,
    );
  }
}
