class Product {
  const Product({
    required this.skuCode,
    required this.name,
    required this.category,
    required this.unitOfMeasure,
    required this.reorderPoint,
    required this.reorderQuantity,
    required this.stockByLocation,
  });

  final String skuCode;
  final String name;
  final String category;
  final String unitOfMeasure;
  final int reorderPoint;
  final int reorderQuantity;
  final Map<String, int> stockByLocation;

  String get id => skuCode;

  int get totalStock {
    return stockByLocation.values.fold<int>(0, (int sum, int qty) => sum + qty);
  }

  Product copyWith({
    String? skuCode,
    String? name,
    String? category,
    String? unitOfMeasure,
    int? reorderPoint,
    int? reorderQuantity,
    Map<String, int>? stockByLocation,
  }) {
    return Product(
      skuCode: skuCode ?? this.skuCode,
      name: name ?? this.name,
      category: category ?? this.category,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      reorderQuantity: reorderQuantity ?? this.reorderQuantity,
      stockByLocation: stockByLocation ?? this.stockByLocation,
    );
  }
}
