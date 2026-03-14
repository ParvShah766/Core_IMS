import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../app/api_config.dart';
import '../models/inventory_models.dart';

class DashboardService extends ChangeNotifier {
  DashboardService() {
    unawaited(loadFromBackend());
  }

  List<ProductStock> _products = <ProductStock>[];
  List<InventoryDocument> _documents = <InventoryDocument>[];

  List<InventoryDocument> get allDocuments =>
      List<InventoryDocument>.unmodifiable(_documents);

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<void> loadFromBackend() async {
    try {
      // Load low stock alerts and inventory documents in parallel
      final responses = await Future.wait([
        http.get(_uri('/api/stock-ledger?low=true')),
        http.get(_uri('/api/inventory-documents')),
      ]);

      final alertsResponse = responses[0];
      final docsResponse = responses[1];

      // Process low stock alerts
      if (alertsResponse.statusCode >= 200 && alertsResponse.statusCode < 300) {
        final List<dynamic> decoded =
            jsonDecode(alertsResponse.body) as List<dynamic>;
        final List<ProductStock> stocks = <ProductStock>[];

        for (final dynamic item in decoded) {
          if (item is Map<String, dynamic>) {
            stocks.add(
              ProductStock(
                sku: (item['skuCode'] as String?) ?? '',
                name: (item['productName'] as String?) ?? '',
                category: (item['category'] as String?) ?? '',
                warehouse: 'Unknown',
                location: (item['location'] as String?) ?? '',
                quantity: (item['quantity'] as int?) ?? 0,
                reorderLevel: (item['reorderPoint'] as int?) ?? 0,
              ),
            );
          }
        }

        if (stocks.isNotEmpty) {
          _products = stocks;
        }
      }

      // Process inventory documents
      if (docsResponse.statusCode >= 200 && docsResponse.statusCode < 300) {
        final List<dynamic> decoded =
            jsonDecode(docsResponse.body) as List<dynamic>;
        final List<InventoryDocument> docs = <InventoryDocument>[];

        for (final dynamic item in decoded) {
          if (item is Map<String, dynamic>) {
            final String typeStr = ((item['type'] as String?) ?? 'receipts')
                .toLowerCase();
            final String statusStr = ((item['status'] as String?) ?? 'draft')
                .toLowerCase();

            DocumentType docType = _parseDocumentType(typeStr);
            InventoryStatus docStatus = _parseInventoryStatus(statusStr);

            docs.add(
              InventoryDocument(
                reference: (item['reference'] as String?) ?? '',
                type: docType,
                status: docStatus,
                warehouse:
                    ((item['warehouse'] as Map<String, dynamic>?)?['name']
                        as String?) ??
                    'Unknown',
                location: (item['location'] as String?) ?? '',
                category: (item['category'] as String?) ?? '',
              ),
            );
          }
        }

        if (docs.isNotEmpty) {
          _documents = docs;
        }
      }

      notifyListeners();
    } catch (_) {
      // Keep local seed data if backend is unavailable.
      notifyListeners();
    }
  }

  DocumentType _parseDocumentType(String type) {
    switch (type) {
      case 'deliveries':
        return DocumentType.deliveries;
      case 'internal':
        return DocumentType.internal;
      case 'adjustments':
        return DocumentType.adjustments;
      default:
        return DocumentType.receipts;
    }
  }

  InventoryStatus _parseInventoryStatus(String status) {
    switch (status) {
      case 'ready':
        return InventoryStatus.ready;
      case 'waiting':
        return InventoryStatus.waiting;
      case 'completed':
        return InventoryStatus.done;
      case 'cancelled':
        return InventoryStatus.canceled;
      default:
        return InventoryStatus.draft;
    }
  }

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
