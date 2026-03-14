import '../models/inventory_models.dart';

class DashboardService {
  final List<ProductStock> _products = const <ProductStock>[
    ProductStock(
      sku: 'RM-001',
      name: 'Raw Material A',
      category: 'Raw Materials',
      warehouse: 'Main WH',
      location: 'A1',
      quantity: 120,
      reorderLevel: 40,
    ),
    ProductStock(
      sku: 'RM-002',
      name: 'Raw Material B',
      category: 'Raw Materials',
      warehouse: 'Main WH',
      location: 'A2',
      quantity: 22,
      reorderLevel: 25,
    ),
    ProductStock(
      sku: 'FG-010',
      name: 'Finished Good X',
      category: 'Finished Goods',
      warehouse: 'Dispatch WH',
      location: 'D1',
      quantity: 0,
      reorderLevel: 10,
    ),
    ProductStock(
      sku: 'PK-004',
      name: 'Packaging Box 40x30',
      category: 'Packaging',
      warehouse: 'Main WH',
      location: 'P3',
      quantity: 310,
      reorderLevel: 100,
    ),
    ProductStock(
      sku: 'SP-003',
      name: 'Spare Belt',
      category: 'Maintenance',
      warehouse: 'Maintenance WH',
      location: 'M1',
      quantity: 6,
      reorderLevel: 8,
    ),
  ];

  final List<InventoryDocument> _documents = const <InventoryDocument>[
    InventoryDocument(
      reference: 'RCV-24001',
      type: DocumentType.receipts,
      status: InventoryStatus.waiting,
      warehouse: 'Main WH',
      location: 'A1',
      category: 'Raw Materials',
    ),
    InventoryDocument(
      reference: 'RCV-24002',
      type: DocumentType.receipts,
      status: InventoryStatus.ready,
      warehouse: 'Dispatch WH',
      location: 'Dock-2',
      category: 'Packaging',
    ),
    InventoryDocument(
      reference: 'DLV-24011',
      type: DocumentType.deliveries,
      status: InventoryStatus.waiting,
      warehouse: 'Dispatch WH',
      location: 'D1',
      category: 'Finished Goods',
    ),
    InventoryDocument(
      reference: 'DLV-24012',
      type: DocumentType.deliveries,
      status: InventoryStatus.draft,
      warehouse: 'Dispatch WH',
      location: 'D2',
      category: 'Finished Goods',
    ),
    InventoryDocument(
      reference: 'INT-24031',
      type: DocumentType.internal,
      status: InventoryStatus.ready,
      warehouse: 'Main WH',
      location: 'Transit',
      category: 'Raw Materials',
    ),
    InventoryDocument(
      reference: 'INT-24032',
      type: DocumentType.internal,
      status: InventoryStatus.waiting,
      warehouse: 'Maintenance WH',
      location: 'Transit',
      category: 'Maintenance',
    ),
    InventoryDocument(
      reference: 'ADJ-24017',
      type: DocumentType.adjustments,
      status: InventoryStatus.done,
      warehouse: 'Main WH',
      location: 'CycleCount',
      category: 'Raw Materials',
    ),
  ];

  List<InventoryDocument> get allDocuments =>
      List<InventoryDocument>.unmodifiable(_documents);

  DashboardSnapshot snapshot({
    DashboardFilters filters = const DashboardFilters(),
  }) {
    final List<InventoryDocument> filteredDocuments = _documents
        .where((InventoryDocument doc) => _matchesFilters(doc, filters))
        .toList();

    final List<ProductStock> filteredProducts = _products
        .where(
          (ProductStock product) => _matchesProductFilters(product, filters),
        )
        .toList();

    final int totalStock = filteredProducts.fold<int>(
      0,
      (int sum, ProductStock product) => sum + product.quantity,
    );

    final int lowOrOut = filteredProducts
        .where(
          (ProductStock product) => product.isLowStock || product.isOutOfStock,
        )
        .length;

    final int pendingReceipts = filteredDocuments
        .where(
          (InventoryDocument doc) =>
              doc.type == DocumentType.receipts &&
              doc.status != InventoryStatus.done &&
              doc.status != InventoryStatus.canceled,
        )
        .length;

    final int pendingDeliveries = filteredDocuments
        .where(
          (InventoryDocument doc) =>
              doc.type == DocumentType.deliveries &&
              doc.status != InventoryStatus.done &&
              doc.status != InventoryStatus.canceled,
        )
        .length;

    final int scheduledInternalTransfers = filteredDocuments
        .where(
          (InventoryDocument doc) =>
              doc.type == DocumentType.internal &&
              (doc.status == InventoryStatus.waiting ||
                  doc.status == InventoryStatus.ready),
        )
        .length;

    final Set<String> whAndLocations = <String>{
      ..._documents.map((InventoryDocument d) => d.warehouse),
      ..._documents.map((InventoryDocument d) => d.location),
      ..._products.map((ProductStock p) => p.warehouse),
      ..._products.map((ProductStock p) => p.location),
    };

    final Set<String> categories = <String>{
      ..._documents.map((InventoryDocument d) => d.category),
      ..._products.map((ProductStock p) => p.category),
    };

    return DashboardSnapshot(
      kpis: DashboardKpis(
        totalProductsInStock: totalStock,
        lowOrOutOfStockItems: lowOrOut,
        pendingReceipts: pendingReceipts,
        pendingDeliveries: pendingDeliveries,
        internalTransfersScheduled: scheduledInternalTransfers,
      ),
      filters: filters,
      products: filteredProducts,
      documents: filteredDocuments,
      availableWarehousesOrLocations: whAndLocations.toList()..sort(),
      availableCategories: categories.toList()..sort(),
    );
  }

  bool _matchesFilters(InventoryDocument document, DashboardFilters filters) {
    if (filters.type != null && document.type != filters.type) {
      return false;
    }

    if (filters.status != null && document.status != filters.status) {
      return false;
    }

    if (filters.warehouseOrLocation != null &&
        document.warehouse != filters.warehouseOrLocation &&
        document.location != filters.warehouseOrLocation) {
      return false;
    }

    if (filters.category != null && document.category != filters.category) {
      return false;
    }

    return true;
  }

  bool _matchesProductFilters(ProductStock product, DashboardFilters filters) {
    if (filters.warehouseOrLocation != null &&
        product.warehouse != filters.warehouseOrLocation &&
        product.location != filters.warehouseOrLocation) {
      return false;
    }

    if (filters.category != null && product.category != filters.category) {
      return false;
    }

    return true;
  }
}
