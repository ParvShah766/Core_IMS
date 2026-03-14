enum DocumentType { receipts, deliveries, internal, adjustments }

enum InventoryStatus { draft, waiting, ready, done, canceled }

class ProductStock {
  const ProductStock({
    required this.sku,
    required this.name,
    required this.category,
    required this.warehouse,
    required this.location,
    required this.quantity,
    required this.reorderLevel,
  });

  final String sku;
  final String name;
  final String category;
  final String warehouse;
  final String location;
  final int quantity;
  final int reorderLevel;

  bool get isOutOfStock => quantity == 0;
  bool get isLowStock => quantity > 0 && quantity <= reorderLevel;
}

class InventoryDocument {
  const InventoryDocument({
    required this.reference,
    required this.type,
    required this.status,
    required this.warehouse,
    required this.location,
    required this.category,
  });

  final String reference;
  final DocumentType type;
  final InventoryStatus status;
  final String warehouse;
  final String location;
  final String category;
}

class DashboardFilters {
  const DashboardFilters({
    this.type,
    this.status,
    this.warehouseOrLocation,
    this.category,
  });

  final DocumentType? type;
  final InventoryStatus? status;
  final String? warehouseOrLocation;
  final String? category;

  DashboardFilters copyWith({
    DocumentType? type,
    bool clearType = false,
    InventoryStatus? status,
    bool clearStatus = false,
    String? warehouseOrLocation,
    bool clearWarehouseOrLocation = false,
    String? category,
    bool clearCategory = false,
  }) {
    return DashboardFilters(
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
      warehouseOrLocation: clearWarehouseOrLocation
          ? null
          : (warehouseOrLocation ?? this.warehouseOrLocation),
      category: clearCategory ? null : (category ?? this.category),
    );
  }

  bool get isEmpty =>
      type == null &&
      status == null &&
      warehouseOrLocation == null &&
      category == null;
}

class DashboardKpis {
  const DashboardKpis({
    required this.totalProductsInStock,
    required this.lowOrOutOfStockItems,
    required this.pendingReceipts,
    required this.pendingDeliveries,
    required this.internalTransfersScheduled,
  });

  final int totalProductsInStock;
  final int lowOrOutOfStockItems;
  final int pendingReceipts;
  final int pendingDeliveries;
  final int internalTransfersScheduled;
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.kpis,
    required this.filters,
    required this.products,
    required this.documents,
    required this.availableWarehousesOrLocations,
    required this.availableCategories,
  });

  final DashboardKpis kpis;
  final DashboardFilters filters;
  final List<ProductStock> products;
  final List<InventoryDocument> documents;
  final List<String> availableWarehousesOrLocations;
  final List<String> availableCategories;
}
