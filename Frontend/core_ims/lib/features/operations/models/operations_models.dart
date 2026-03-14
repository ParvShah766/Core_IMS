enum LedgerMovementType { receipt, delivery, transfer, adjustment }

class OperationLine {
  const OperationLine({
    required this.productCode,
    required this.location,
    required this.quantity,
  });

  final String productCode;
  final String location;
  final int quantity;
}

class ReceiptRecord {
  const ReceiptRecord({
    required this.reference,
    required this.supplier,
    required this.lines,
    required this.validatedAt,
  });

  final String reference;
  final String supplier;
  final List<OperationLine> lines;
  final DateTime validatedAt;
}

class DeliveryOrderRecord {
  const DeliveryOrderRecord({
    required this.reference,
    required this.customer,
    required this.lines,
    required this.picked,
    required this.packed,
    required this.validatedAt,
  });

  final String reference;
  final String customer;
  final List<OperationLine> lines;
  final bool picked;
  final bool packed;
  final DateTime validatedAt;
}

class InternalTransferRecord {
  const InternalTransferRecord({
    required this.reference,
    required this.productCode,
    required this.fromLocation,
    required this.toLocation,
    required this.quantity,
    required this.validatedAt,
  });

  final String reference;
  final String productCode;
  final String fromLocation;
  final String toLocation;
  final int quantity;
  final DateTime validatedAt;
}

class StockAdjustmentRecord {
  const StockAdjustmentRecord({
    required this.reference,
    required this.productCode,
    required this.location,
    required this.recordedQuantity,
    required this.countedQuantity,
    required this.delta,
    required this.validatedAt,
  });

  final String reference;
  final String productCode;
  final String location;
  final int recordedQuantity;
  final int countedQuantity;
  final int delta;
  final DateTime validatedAt;
}

class StockLedgerEntry {
  const StockLedgerEntry({
    required this.reference,
    required this.timestamp,
    required this.movementType,
    required this.productCode,
    required this.productName,
    required this.fromLocation,
    required this.toLocation,
    required this.quantityDelta,
    required this.note,
  });

  final String reference;
  final DateTime timestamp;
  final LedgerMovementType movementType;
  final String productCode;
  final String productName;
  final String? fromLocation;
  final String? toLocation;
  final int quantityDelta;
  final String note;
}

class OperationResult {
  const OperationResult({required this.success, required this.message});

  final bool success;
  final String message;
}
