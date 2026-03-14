import 'package:flutter/foundation.dart';

import '../models/product.dart';

class LowStockAlert {
  const LowStockAlert({
    required this.skuCode,
    required this.productName,
    required this.location,
    required this.warehouse,
    required this.quantity,
    required this.reorderPoint,
  });

  final String skuCode;
  final String productName;
  final String location;
  final String warehouse;
  final int quantity;
  final int reorderPoint;
}

class ProductService extends ChangeNotifier {
  final List<Product> _products = <Product>[
    const Product(
      skuCode: 'PRD-1001',
      name: 'Raw Material A',
      category: 'Raw Materials',
      unitOfMeasure: 'Units',
      reorderPoint: 40,
      reorderQuantity: 120,
      stockByLocation: <String, int>{'Main WH-A1': 120, 'Main WH-A2': 28},
    ),
    const Product(
      skuCode: 'PRD-1002',
      name: 'Finished Good X',
      category: 'Finished Goods',
      unitOfMeasure: 'Units',
      reorderPoint: 10,
      reorderQuantity: 50,
      stockByLocation: <String, int>{'Dispatch WH-D1': 0},
    ),
    const Product(
      skuCode: 'PRD-1003',
      name: 'Packaging Box 40x30',
      category: 'Packaging',
      unitOfMeasure: 'Box',
      reorderPoint: 100,
      reorderQuantity: 300,
      stockByLocation: <String, int>{'Main WH-P3': 310},
    ),
  ];

  List<Product> get products => List<Product>.unmodifiable(_products);

  List<String> get categories {
    final Set<String> values = _products.map((Product p) => p.category).toSet();
    final List<String> sorted = values.toList()..sort();
    return sorted;
  }

  List<String> get warehouses {
    final Set<String> names = <String>{
      for (final Product product in _products)
        ...product.stockByLocation.keys.map(_warehouseFromLocation),
    };
    final List<String> sorted = names.toList()..sort();
    return sorted;
  }

  List<LowStockAlert> get lowStockAlerts {
    final List<LowStockAlert> alerts = <LowStockAlert>[];

    for (final Product product in _products) {
      for (final MapEntry<String, int> entry
          in product.stockByLocation.entries) {
        if (entry.value <= product.reorderPoint) {
          alerts.add(
            LowStockAlert(
              skuCode: product.skuCode,
              productName: product.name,
              location: entry.key,
              warehouse: _warehouseFromLocation(entry.key),
              quantity: entry.value,
              reorderPoint: product.reorderPoint,
            ),
          );
        }
      }
    }

    alerts.sort(
      (LowStockAlert a, LowStockAlert b) => a.quantity.compareTo(b.quantity),
    );
    return alerts;
  }

  List<Product> smartFilterProducts({
    String? query,
    String? category,
    String? warehouse,
    bool onlyLowStock = false,
  }) {
    final String normalizedQuery = (query ?? '').trim().toLowerCase();

    return _products.where((Product product) {
      final bool queryMatch =
          normalizedQuery.isEmpty ||
          product.skuCode.toLowerCase().contains(normalizedQuery) ||
          product.name.toLowerCase().contains(normalizedQuery) ||
          product.category.toLowerCase().contains(normalizedQuery);

      final bool categoryMatch =
          category == null || product.category == category;
      final bool warehouseMatch =
          warehouse == null ||
          product.stockByLocation.keys.any(
            (String location) => _warehouseFromLocation(location) == warehouse,
          );
      final bool lowStockMatch =
          !onlyLowStock ||
          product.stockByLocation.values.any(
            (int quantity) => quantity <= product.reorderPoint,
          );

      return queryMatch && categoryMatch && warehouseMatch && lowStockMatch;
    }).toList();
  }

  void createProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(Product product) {
    final int index = _products.indexWhere(
      (Product p) => p.skuCode == product.skuCode,
    );
    if (index == -1) {
      return;
    }
    _products[index] = product;
    notifyListeners();
  }

  Product? findByCode(String productCode) {
    for (final Product product in _products) {
      if (product.skuCode.toLowerCase() == productCode.trim().toLowerCase()) {
        return product;
      }
    }
    return null;
  }

  int stockAtLocation({required String productCode, required String location}) {
    final Product? product = findByCode(productCode);
    if (product == null) {
      return 0;
    }

    return product.stockByLocation[location.trim()] ?? 0;
  }

  void changeStock({
    required String productCode,
    required String location,
    required int delta,
  }) {
    final Product? product = findByCode(productCode);
    if (product == null) {
      return;
    }

    final String normalizedLocation = location.trim();
    final Map<String, int> stock = Map<String, int>.from(
      product.stockByLocation,
    );
    final int current = stock[normalizedLocation] ?? 0;
    final int next = current + delta;

    stock[normalizedLocation] = next < 0 ? 0 : next;
    updateProduct(product.copyWith(stockByLocation: stock));
  }

  void setStockAtLocation({
    required String productCode,
    required String location,
    required int quantity,
  }) {
    final Product? product = findByCode(productCode);
    if (product == null) {
      return;
    }

    final Map<String, int> stock = Map<String, int>.from(
      product.stockByLocation,
    );
    stock[location.trim()] = quantity < 0 ? 0 : quantity;
    updateProduct(product.copyWith(stockByLocation: stock));
  }

  Map<String, int> stockByWarehouse(Product product) {
    final Map<String, int> result = <String, int>{};
    for (final MapEntry<String, int> entry in product.stockByLocation.entries) {
      final String warehouse = _warehouseFromLocation(entry.key);
      result[warehouse] = (result[warehouse] ?? 0) + entry.value;
    }
    return result;
  }

  String _warehouseFromLocation(String location) {
    final int split = location.indexOf('-');
    if (split <= 0) {
      return location.trim();
    }
    return location.substring(0, split).trim();
  }
}
