import 'package:flutter/foundation.dart';

import '../../products/models/product.dart';
import '../../products/services/product_service.dart';
import '../models/operations_models.dart';

class OperationsService extends ChangeNotifier {
  OperationsService({required ProductService productService})
    : _productService = productService;

  final ProductService _productService;

  final List<ReceiptRecord> _receipts = <ReceiptRecord>[];
  final List<DeliveryOrderRecord> _deliveries = <DeliveryOrderRecord>[];
  final List<InternalTransferRecord> _transfers = <InternalTransferRecord>[];
  final List<StockAdjustmentRecord> _adjustments = <StockAdjustmentRecord>[];
  final List<StockLedgerEntry> _ledger = <StockLedgerEntry>[];

  int _receiptSeed = 1000;
  int _deliverySeed = 2000;
  int _transferSeed = 3000;
  int _adjustmentSeed = 4000;

  List<ReceiptRecord> get receipts =>
      List<ReceiptRecord>.unmodifiable(_receipts);
  List<DeliveryOrderRecord> get deliveries =>
      List<DeliveryOrderRecord>.unmodifiable(_deliveries);
  List<InternalTransferRecord> get transfers =>
      List<InternalTransferRecord>.unmodifiable(_transfers);
  List<StockAdjustmentRecord> get adjustments =>
      List<StockAdjustmentRecord>.unmodifiable(_adjustments);
  List<StockLedgerEntry> get ledger =>
      List<StockLedgerEntry>.unmodifiable(_ledger);

  OperationResult validateReceipt({
    required String supplier,
    required List<OperationLine> lines,
  }) {
    if (supplier.trim().isEmpty) {
      return const OperationResult(
        success: false,
        message: 'Supplier is required.',
      );
    }

    final List<OperationLine> filteredLines = _validLines(lines);
    if (filteredLines.isEmpty) {
      return const OperationResult(
        success: false,
        message: 'Add at least one valid line item.',
      );
    }

    for (final OperationLine line in filteredLines) {
      final Product? product = _productService.findByCode(line.productCode);
      if (product == null) {
        return OperationResult(
          success: false,
          message: 'Unknown product code ${line.productCode}.',
        );
      }
    }

    final String receiptReference = _nextReceiptReference();
    final DateTime timestamp = DateTime.now();

    for (final OperationLine line in filteredLines) {
      final Product product = _productService.findByCode(line.productCode)!;

      _productService.changeStock(
        productCode: line.productCode,
        location: line.location,
        delta: line.quantity,
      );

      _ledger.insert(
        0,
        StockLedgerEntry(
          reference: receiptReference,
          timestamp: timestamp,
          movementType: LedgerMovementType.receipt,
          productCode: product.skuCode,
          productName: product.name,
          fromLocation: null,
          toLocation: line.location,
          quantityDelta: line.quantity,
          note: 'Receipt from supplier ${supplier.trim()}',
        ),
      );
    }

    _receipts.insert(
      0,
      ReceiptRecord(
        reference: receiptReference,
        supplier: supplier.trim(),
        lines: filteredLines,
        validatedAt: timestamp,
      ),
    );

    notifyListeners();
    return OperationResult(
      success: true,
      message:
          'Receipt $receiptReference validated. Stock updated successfully.',
    );
  }

  OperationResult validateDeliveryOrder({
    required String customer,
    required bool picked,
    required bool packed,
    required List<OperationLine> lines,
  }) {
    if (customer.trim().isEmpty) {
      return const OperationResult(
        success: false,
        message: 'Customer is required.',
      );
    }
    if (!picked || !packed) {
      return const OperationResult(
        success: false,
        message:
            'Delivery validation requires both Pick and Pack steps completed.',
      );
    }

    final List<OperationLine> filteredLines = _validLines(lines);
    if (filteredLines.isEmpty) {
      return const OperationResult(
        success: false,
        message: 'Add at least one valid line item.',
      );
    }

    for (final OperationLine line in filteredLines) {
      final Product? product = _productService.findByCode(line.productCode);
      if (product == null) {
        return OperationResult(
          success: false,
          message: 'Unknown product code ${line.productCode}.',
        );
      }

      final int available = _productService.stockAtLocation(
        productCode: line.productCode,
        location: line.location,
      );
      if (available < line.quantity) {
        return OperationResult(
          success: false,
          message:
              'Insufficient stock for ${product.skuCode} at ${line.location}. Available $available, requested ${line.quantity}.',
        );
      }
    }

    final String deliveryReference = _nextDeliveryReference();
    final DateTime timestamp = DateTime.now();

    for (final OperationLine line in filteredLines) {
      final Product product = _productService.findByCode(line.productCode)!;

      _productService.changeStock(
        productCode: line.productCode,
        location: line.location,
        delta: -line.quantity,
      );

      _ledger.insert(
        0,
        StockLedgerEntry(
          reference: deliveryReference,
          timestamp: timestamp,
          movementType: LedgerMovementType.delivery,
          productCode: product.skuCode,
          productName: product.name,
          fromLocation: line.location,
          toLocation: null,
          quantityDelta: -line.quantity,
          note: 'Delivery to customer ${customer.trim()}',
        ),
      );
    }

    _deliveries.insert(
      0,
      DeliveryOrderRecord(
        reference: deliveryReference,
        customer: customer.trim(),
        lines: filteredLines,
        picked: picked,
        packed: packed,
        validatedAt: timestamp,
      ),
    );

    notifyListeners();
    return OperationResult(
      success: true,
      message:
          'Delivery order $deliveryReference validated. Stock reduced successfully.',
    );
  }

  OperationResult validateInternalTransfer({
    required String productCode,
    required String fromLocation,
    required String toLocation,
    required int quantity,
  }) {
    if (quantity <= 0) {
      return const OperationResult(
        success: false,
        message: 'Quantity should be greater than zero.',
      );
    }
    if (fromLocation.trim().isEmpty || toLocation.trim().isEmpty) {
      return const OperationResult(
        success: false,
        message: 'From and To locations are required.',
      );
    }
    if (fromLocation.trim() == toLocation.trim()) {
      return const OperationResult(
        success: false,
        message: 'Source and destination locations must differ.',
      );
    }

    final Product? product = _productService.findByCode(productCode);
    if (product == null) {
      return OperationResult(
        success: false,
        message: 'Unknown product code $productCode.',
      );
    }

    final int available = _productService.stockAtLocation(
      productCode: productCode,
      location: fromLocation,
    );
    if (available < quantity) {
      return OperationResult(
        success: false,
        message:
            'Insufficient stock at $fromLocation. Available $available, requested $quantity.',
      );
    }

    final String transferReference = _nextTransferReference();
    final DateTime timestamp = DateTime.now();

    _productService.changeStock(
      productCode: productCode,
      location: fromLocation,
      delta: -quantity,
    );
    _productService.changeStock(
      productCode: productCode,
      location: toLocation,
      delta: quantity,
    );

    _transfers.insert(
      0,
      InternalTransferRecord(
        reference: transferReference,
        productCode: productCode,
        fromLocation: fromLocation.trim(),
        toLocation: toLocation.trim(),
        quantity: quantity,
        validatedAt: timestamp,
      ),
    );

    _ledger.insert(
      0,
      StockLedgerEntry(
        reference: transferReference,
        timestamp: timestamp,
        movementType: LedgerMovementType.transfer,
        productCode: product.skuCode,
        productName: product.name,
        fromLocation: fromLocation.trim(),
        toLocation: null,
        quantityDelta: -quantity,
        note: 'Internal transfer out',
      ),
    );

    _ledger.insert(
      0,
      StockLedgerEntry(
        reference: transferReference,
        timestamp: timestamp,
        movementType: LedgerMovementType.transfer,
        productCode: product.skuCode,
        productName: product.name,
        fromLocation: null,
        toLocation: toLocation.trim(),
        quantityDelta: quantity,
        note: 'Internal transfer in',
      ),
    );

    notifyListeners();
    return OperationResult(
      success: true,
      message: 'Transfer $transferReference validated and logged in ledger.',
    );
  }

  OperationResult validateStockAdjustment({
    required String productCode,
    required String location,
    required int countedQuantity,
  }) {
    if (location.trim().isEmpty) {
      return const OperationResult(
        success: false,
        message: 'Location is required.',
      );
    }
    if (countedQuantity < 0) {
      return const OperationResult(
        success: false,
        message: 'Counted quantity cannot be negative.',
      );
    }

    final Product? product = _productService.findByCode(productCode);
    if (product == null) {
      return OperationResult(
        success: false,
        message: 'Unknown product code $productCode.',
      );
    }

    final int recorded = _productService.stockAtLocation(
      productCode: productCode,
      location: location,
    );
    final int delta = countedQuantity - recorded;

    _productService.setStockAtLocation(
      productCode: productCode,
      location: location,
      quantity: countedQuantity,
    );

    final String adjustmentReference = _nextAdjustmentReference();
    final DateTime timestamp = DateTime.now();

    _adjustments.insert(
      0,
      StockAdjustmentRecord(
        reference: adjustmentReference,
        productCode: productCode,
        location: location.trim(),
        recordedQuantity: recorded,
        countedQuantity: countedQuantity,
        delta: delta,
        validatedAt: timestamp,
      ),
    );

    _ledger.insert(
      0,
      StockLedgerEntry(
        reference: adjustmentReference,
        timestamp: timestamp,
        movementType: LedgerMovementType.adjustment,
        productCode: product.skuCode,
        productName: product.name,
        fromLocation: location.trim(),
        toLocation: location.trim(),
        quantityDelta: delta,
        note: 'Stock adjustment by physical count',
      ),
    );

    notifyListeners();
    return OperationResult(
      success: true,
      message:
          'Adjustment $adjustmentReference validated. Stock updated to physical count.',
    );
  }

  List<OperationLine> _validLines(List<OperationLine> lines) {
    return lines
        .where(
          (OperationLine line) =>
              line.productCode.trim().isNotEmpty &&
              line.location.trim().isNotEmpty &&
              line.quantity > 0,
        )
        .toList();
  }

  String _nextReceiptReference() {
    _receiptSeed += 1;
    return 'RCV-$_receiptSeed';
  }

  String _nextDeliveryReference() {
    _deliverySeed += 1;
    return 'DLV-$_deliverySeed';
  }

  String _nextTransferReference() {
    _transferSeed += 1;
    return 'TRN-$_transferSeed';
  }

  String _nextAdjustmentReference() {
    _adjustmentSeed += 1;
    return 'ADJ-$_adjustmentSeed';
  }
}
