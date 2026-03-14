import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../products/models/product.dart';
import '../models/operations_models.dart';
import '../services/operations_service.dart';

class ReceiptOperationsView extends StatefulWidget {
  const ReceiptOperationsView({super.key});

  @override
  State<ReceiptOperationsView> createState() => _ReceiptOperationsViewState();
}

class _ReceiptOperationsViewState extends State<ReceiptOperationsView> {
  final TextEditingController _supplierController = TextEditingController();
  final List<_EditableLine> _lines = <_EditableLine>[_EditableLine()];
  String? _message;

  @override
  void dispose() {
    _supplierController.dispose();
    for (final _EditableLine line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OperationsService service = AppScope.of(context).operationsService;

    return AnimatedBuilder(
      animation: service,
      builder: (BuildContext context, Widget? child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Receipts (Incoming Goods)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: 'Supplier',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ..._lineInputs(title: 'Product lines'),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => setState(() => _lines.add(_EditableLine())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product Line'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _validateReceipt,
                  child: const Text('Validate Receipt'),
                ),
              ],
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_message!),
              ),
            const SizedBox(height: 16),
            Text(
              'Validated Receipts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _receiptTable(service.receipts),
          ],
        );
      },
    );
  }

  List<Widget> _lineInputs({required String title}) {
    return <Widget>[
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ..._lines.asMap().entries.map((MapEntry<int, _EditableLine> entry) {
        final int index = entry.key;
        final _EditableLine line = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: TextField(
                  controller: line.productCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Product SKU/Code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: line.locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: line.quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              if (_lines.length > 1)
                IconButton(
                  onPressed: () {
                    setState(() {
                      line.dispose();
                      _lines.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        );
      }),
    ];
  }

  Widget _receiptTable(List<ReceiptRecord> records) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('Reference')),
            DataColumn(label: Text('Supplier')),
            DataColumn(label: Text('Lines')),
            DataColumn(label: Text('Validated At')),
          ],
          rows: records
              .map(
                (ReceiptRecord record) => DataRow(
                  cells: <DataCell>[
                    DataCell(Text(record.reference)),
                    DataCell(Text(record.supplier)),
                    DataCell(Text(record.lines.length.toString())),
                    DataCell(Text(_date(record.validatedAt))),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _validateReceipt() {
    final OperationsService service = AppScope.of(context).operationsService;
    final List<OperationLine> lines = _toLines();
    final OperationResult result = service.validateReceipt(
      supplier: _supplierController.text,
      lines: lines,
    );

    setState(() {
      _message = result.message;
      if (result.success) {
        _supplierController.clear();
        for (final _EditableLine line in _lines) {
          line.dispose();
        }
        _lines
          ..clear()
          ..add(_EditableLine());
      }
    });
  }

  List<OperationLine> _toLines() {
    return _lines
        .map(
          (_EditableLine line) => OperationLine(
            productCode: line.productCodeController.text.trim(),
            location: line.locationController.text.trim(),
            quantity: int.tryParse(line.quantityController.text.trim()) ?? 0,
          ),
        )
        .toList();
  }
}

class DeliveryOrdersView extends StatefulWidget {
  const DeliveryOrdersView({super.key});

  @override
  State<DeliveryOrdersView> createState() => _DeliveryOrdersViewState();
}

class _DeliveryOrdersViewState extends State<DeliveryOrdersView> {
  final TextEditingController _customerController = TextEditingController();
  final List<_EditableLine> _lines = <_EditableLine>[_EditableLine()];
  bool _picked = false;
  bool _packed = false;
  String? _message;

  @override
  void dispose() {
    _customerController.dispose();
    for (final _EditableLine line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OperationsService service = AppScope.of(context).operationsService;

    return AnimatedBuilder(
      animation: service,
      builder: (BuildContext context, Widget? child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Delivery Orders (Outgoing Goods)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customerController,
              decoration: const InputDecoration(
                labelText: 'Customer',
                border: OutlineInputBorder(),
              ),
            ),
            CheckboxListTile(
              value: _picked,
              onChanged: (bool? value) =>
                  setState(() => _picked = value ?? false),
              title: const Text('Picked'),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _packed,
              onChanged: (bool? value) =>
                  setState(() => _packed = value ?? false),
              title: const Text('Packed'),
              contentPadding: EdgeInsets.zero,
            ),
            ..._lineInputs(),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => setState(() => _lines.add(_EditableLine())),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product Line'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _validateDelivery,
                  child: const Text('Validate Delivery'),
                ),
              ],
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_message!),
              ),
            const SizedBox(height: 16),
            Text(
              'Validated Delivery Orders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _deliveryTable(service.deliveries),
          ],
        );
      },
    );
  }

  List<Widget> _lineInputs() {
    return <Widget>[
      Text('Product lines', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ..._lines.asMap().entries.map((MapEntry<int, _EditableLine> entry) {
        final int index = entry.key;
        final _EditableLine line = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: TextField(
                  controller: line.productCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Product SKU/Code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: line.locationController,
                  decoration: const InputDecoration(
                    labelText: 'Pick Location',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: line.quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              if (_lines.length > 1)
                IconButton(
                  onPressed: () {
                    setState(() {
                      line.dispose();
                      _lines.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        );
      }),
    ];
  }

  Widget _deliveryTable(List<DeliveryOrderRecord> records) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('Reference')),
            DataColumn(label: Text('Customer')),
            DataColumn(label: Text('Lines')),
            DataColumn(label: Text('Pick/Pack')),
            DataColumn(label: Text('Validated At')),
          ],
          rows: records
              .map(
                (DeliveryOrderRecord record) => DataRow(
                  cells: <DataCell>[
                    DataCell(Text(record.reference)),
                    DataCell(Text(record.customer)),
                    DataCell(Text(record.lines.length.toString())),
                    DataCell(
                      Text(
                        '${record.picked ? 'Yes' : 'No'}/${record.packed ? 'Yes' : 'No'}',
                      ),
                    ),
                    DataCell(Text(_date(record.validatedAt))),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _validateDelivery() {
    final OperationsService service = AppScope.of(context).operationsService;
    final OperationResult result = service.validateDeliveryOrder(
      customer: _customerController.text,
      picked: _picked,
      packed: _packed,
      lines: _toLines(),
    );

    setState(() {
      _message = result.message;
      if (result.success) {
        _customerController.clear();
        _picked = false;
        _packed = false;
        for (final _EditableLine line in _lines) {
          line.dispose();
        }
        _lines
          ..clear()
          ..add(_EditableLine());
      }
    });
  }

  List<OperationLine> _toLines() {
    return _lines
        .map(
          (_EditableLine line) => OperationLine(
            productCode: line.productCodeController.text.trim(),
            location: line.locationController.text.trim(),
            quantity: int.tryParse(line.quantityController.text.trim()) ?? 0,
          ),
        )
        .toList();
  }
}

class InternalTransfersView extends StatefulWidget {
  const InternalTransfersView({super.key});

  @override
  State<InternalTransfersView> createState() => _InternalTransfersViewState();
}

class _InternalTransfersViewState extends State<InternalTransfersView> {
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _fromLocationController = TextEditingController();
  final TextEditingController _toLocationController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _productCodeController.dispose();
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OperationsService service = AppScope.of(context).operationsService;

    return AnimatedBuilder(
      animation: service,
      builder: (BuildContext context, Widget? child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Internal Transfers',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _productCodeController,
              decoration: const InputDecoration(
                labelText: 'Product SKU/Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fromLocationController,
              decoration: const InputDecoration(
                labelText: 'From Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _toLocationController,
              decoration: const InputDecoration(
                labelText: 'To Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _validateTransfer,
              child: const Text('Validate Transfer'),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_message!),
              ),
            const SizedBox(height: 16),
            Text(
              'Validated Internal Transfers',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _transferTable(service.transfers),
          ],
        );
      },
    );
  }

  Widget _transferTable(List<InternalTransferRecord> records) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('Reference')),
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('From')),
            DataColumn(label: Text('To')),
            DataColumn(label: Text('Qty')),
            DataColumn(label: Text('Validated At')),
          ],
          rows: records
              .map(
                (InternalTransferRecord record) => DataRow(
                  cells: <DataCell>[
                    DataCell(Text(record.reference)),
                    DataCell(Text(record.productCode)),
                    DataCell(Text(record.fromLocation)),
                    DataCell(Text(record.toLocation)),
                    DataCell(Text(record.quantity.toString())),
                    DataCell(Text(_date(record.validatedAt))),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _validateTransfer() {
    final OperationsService service = AppScope.of(context).operationsService;
    final OperationResult result = service.validateInternalTransfer(
      productCode: _productCodeController.text.trim(),
      fromLocation: _fromLocationController.text.trim(),
      toLocation: _toLocationController.text.trim(),
      quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
    );

    setState(() {
      _message = result.message;
      if (result.success) {
        _productCodeController.clear();
        _fromLocationController.clear();
        _toLocationController.clear();
        _quantityController.clear();
      }
    });
  }
}

class StockAdjustmentsView extends StatefulWidget {
  const StockAdjustmentsView({super.key});

  @override
  State<StockAdjustmentsView> createState() => _StockAdjustmentsViewState();
}

class _StockAdjustmentsViewState extends State<StockAdjustmentsView> {
  final TextEditingController _productCodeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _countedController = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _productCodeController.dispose();
    _locationController.dispose();
    _countedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OperationsService service = AppScope.of(context).operationsService;
    final List<Product> products = AppScope.of(context).productService.products;

    return AnimatedBuilder(
      animation: service,
      builder: (BuildContext context, Widget? child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Stock Adjustments',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _productCodeController,
              decoration: const InputDecoration(
                labelText: 'Product SKU/Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _countedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Counted Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _validateAdjustment,
              child: const Text('Validate Adjustment'),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_message!),
              ),
            const SizedBox(height: 16),
            Text(
              'Product/Location reference',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  products
                      .map(
                        (Product product) =>
                            '${product.skuCode} (${product.unitOfMeasure}) -> ${product.stockByLocation.entries.map((MapEntry<String, int> e) => '${e.key}:${e.value}').join(', ')}',
                      )
                      .join('\n'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Adjustment History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _adjustmentTable(service.adjustments),
          ],
        );
      },
    );
  }

  Widget _adjustmentTable(List<StockAdjustmentRecord> records) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('Reference')),
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Location')),
            DataColumn(label: Text('Recorded')),
            DataColumn(label: Text('Counted')),
            DataColumn(label: Text('Delta')),
            DataColumn(label: Text('Validated At')),
          ],
          rows: records
              .map(
                (StockAdjustmentRecord record) => DataRow(
                  cells: <DataCell>[
                    DataCell(Text(record.reference)),
                    DataCell(Text(record.productCode)),
                    DataCell(Text(record.location)),
                    DataCell(Text(record.recordedQuantity.toString())),
                    DataCell(Text(record.countedQuantity.toString())),
                    DataCell(
                      Text(
                        record.delta >= 0
                            ? '+${record.delta}'
                            : '${record.delta}',
                      ),
                    ),
                    DataCell(Text(_date(record.validatedAt))),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _validateAdjustment() {
    final OperationsService service = AppScope.of(context).operationsService;
    final OperationResult result = service.validateStockAdjustment(
      productCode: _productCodeController.text.trim(),
      location: _locationController.text.trim(),
      countedQuantity: int.tryParse(_countedController.text.trim()) ?? -1,
    );

    setState(() {
      _message = result.message;
      if (result.success) {
        _productCodeController.clear();
        _locationController.clear();
        _countedController.clear();
      }
    });
  }
}

class MoveHistoryView extends StatefulWidget {
  const MoveHistoryView({super.key});

  @override
  State<MoveHistoryView> createState() => _MoveHistoryViewState();
}

class _MoveHistoryViewState extends State<MoveHistoryView> {
  final TextEditingController _searchController = TextEditingController();
  LedgerMovementType? _selectedType;
  String? _locationContains;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OperationsService service = AppScope.of(context).operationsService;

    return AnimatedBuilder(
      animation: service,
      builder: (BuildContext context, Widget? child) {
        final List<StockLedgerEntry> filtered = service.ledger.where((
          StockLedgerEntry entry,
        ) {
          final String q = _searchController.text.trim().toLowerCase();
          final bool queryMatch =
              q.isEmpty ||
              entry.productCode.toLowerCase().contains(q) ||
              entry.productName.toLowerCase().contains(q) ||
              entry.reference.toLowerCase().contains(q);

          final bool typeMatch =
              _selectedType == null || entry.movementType == _selectedType;
          final bool locationMatch =
              _locationContains == null ||
              _locationContains!.isEmpty ||
              (entry.fromLocation ?? '').toLowerCase().contains(
                _locationContains!.toLowerCase(),
              ) ||
              (entry.toLocation ?? '').toLowerCase().contains(
                _locationContains!.toLowerCase(),
              );

          return queryMatch && typeMatch && locationMatch;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Stock Movement Ledger',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Search SKU / Product / Ref',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<LedgerMovementType?>(
                        key: ValueKey<LedgerMovementType?>(_selectedType),
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Movement Type',
                          border: OutlineInputBorder(),
                        ),
                        items: <DropdownMenuItem<LedgerMovementType?>>[
                          const DropdownMenuItem<LedgerMovementType?>(
                            value: null,
                            child: Text('All Types'),
                          ),
                          ...LedgerMovementType.values.map(
                            (LedgerMovementType type) =>
                                DropdownMenuItem<LedgerMovementType?>(
                                  value: type,
                                  child: Text(_typeLabel(type)),
                                ),
                          ),
                        ],
                        onChanged: (LedgerMovementType? value) {
                          setState(() => _selectedType = value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: TextField(
                        onChanged: (String value) {
                          setState(() => _locationContains = value.trim());
                        },
                        decoration: const InputDecoration(
                          labelText: 'Location contains',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _selectedType = null;
                          _locationContains = null;
                        });
                      },
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Reference')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('From')),
                    DataColumn(label: Text('To')),
                    DataColumn(label: Text('Delta')),
                    DataColumn(label: Text('Timestamp')),
                    DataColumn(label: Text('Note')),
                  ],
                  rows: filtered
                      .map(
                        (StockLedgerEntry entry) => DataRow(
                          cells: <DataCell>[
                            DataCell(Text(entry.reference)),
                            DataCell(Text(_typeLabel(entry.movementType))),
                            DataCell(
                              Text(
                                '${entry.productCode} - ${entry.productName}',
                              ),
                            ),
                            DataCell(Text(entry.fromLocation ?? '-')),
                            DataCell(Text(entry.toLocation ?? '-')),
                            DataCell(
                              Text(
                                entry.quantityDelta >= 0
                                    ? '+${entry.quantityDelta}'
                                    : '${entry.quantityDelta}',
                              ),
                            ),
                            DataCell(Text(_date(entry.timestamp))),
                            DataCell(Text(entry.note)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _typeLabel(LedgerMovementType type) {
    switch (type) {
      case LedgerMovementType.receipt:
        return 'Receipt';
      case LedgerMovementType.delivery:
        return 'Delivery';
      case LedgerMovementType.transfer:
        return 'Transfer';
      case LedgerMovementType.adjustment:
        return 'Adjustment';
    }
  }
}

class _EditableLine {
  _EditableLine();

  final TextEditingController productCodeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  void dispose() {
    productCodeController.dispose();
    locationController.dispose();
    quantityController.dispose();
  }
}

String _date(DateTime dateTime) {
  final String twoDigitMonth = dateTime.month.toString().padLeft(2, '0');
  final String twoDigitDay = dateTime.day.toString().padLeft(2, '0');
  final String twoDigitHour = dateTime.hour.toString().padLeft(2, '0');
  final String twoDigitMinute = dateTime.minute.toString().padLeft(2, '0');
  return '${dateTime.year}-$twoDigitMonth-$twoDigitDay $twoDigitHour:$twoDigitMinute';
}
