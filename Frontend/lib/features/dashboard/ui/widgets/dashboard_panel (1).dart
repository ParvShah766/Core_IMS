import 'package:flutter/material.dart';

import '../../../../app/app_scope.dart';
import '../../models/inventory_models.dart';
import '../../../products/services/product_service.dart';

class DashboardPanel extends StatefulWidget {
  const DashboardPanel({super.key});

  @override
  State<DashboardPanel> createState() => _DashboardPanelState();
}

class _DashboardPanelState extends State<DashboardPanel> {
  DashboardFilters _filters = const DashboardFilters();

  @override
  Widget build(BuildContext context) {
    final snapshot = AppScope.of(
      context,
    ).dashboardService.snapshot(filters: _filters);
    final List<LowStockAlert> alerts = AppScope.of(
      context,
    ).productService.lowStockAlerts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: <Color>[
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insights_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Operational Snapshot',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live inventory health and movement indicators',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _KpiCard(
              label: 'Total Products in Stock',
              value: snapshot.kpis.totalProductsInStock.toString(),
              icon: Icons.inventory_2_outlined,
            ),
            _KpiCard(
              label: 'Low / Out of Stock Items',
              value: snapshot.kpis.lowOrOutOfStockItems.toString(),
              icon: Icons.warning_amber_outlined,
            ),
            _KpiCard(
              label: 'Pending Receipts',
              value: snapshot.kpis.pendingReceipts.toString(),
              icon: Icons.move_to_inbox_outlined,
            ),
            _KpiCard(
              label: 'Pending Deliveries',
              value: snapshot.kpis.pendingDeliveries.toString(),
              icon: Icons.local_shipping_outlined,
            ),
            _KpiCard(
              label: 'Internal Transfers Scheduled',
              value: snapshot.kpis.internalTransfersScheduled.toString(),
              icon: Icons.swap_horiz,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: alerts.isEmpty
              ? Theme.of(context).colorScheme.surfaceContainerLow
              : Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  alerts.isEmpty
                      ? 'Low Stock Alerts: No active alerts'
                      : 'Low Stock Alerts: ${alerts.length} location-level alerts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (alerts.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  ...alerts
                      .take(5)
                      .map(
                        (LowStockAlert alert) => Text(
                          '${alert.skuCode} | ${alert.productName} | ${alert.location} | Qty ${alert.quantity} (ROP ${alert.reorderPoint})',
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<DocumentType?>(
                    key: ValueKey<DocumentType?>(_filters.type),
                    initialValue: _filters.type,
                    decoration: const InputDecoration(
                      labelText: 'Document Type',
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<DocumentType?>>[
                      const DropdownMenuItem<DocumentType?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...DocumentType.values.map(
                        (DocumentType type) => DropdownMenuItem<DocumentType?>(
                          value: type,
                          child: Text(_docTypeLabel(type)),
                        ),
                      ),
                    ],
                    onChanged: (DocumentType? value) {
                      setState(
                        () => _filters = _filters.copyWith(
                          type: value,
                          clearType: value == null,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<InventoryStatus?>(
                    key: ValueKey<InventoryStatus?>(_filters.status),
                    initialValue: _filters.status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<InventoryStatus?>>[
                      const DropdownMenuItem<InventoryStatus?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...InventoryStatus.values.map(
                        (InventoryStatus status) =>
                            DropdownMenuItem<InventoryStatus?>(
                              value: status,
                              child: Text(_statusLabel(status)),
                            ),
                      ),
                    ],
                    onChanged: (InventoryStatus? value) {
                      setState(
                        () => _filters = _filters.copyWith(
                          status: value,
                          clearStatus: value == null,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey<String?>(_filters.warehouseOrLocation),
                    initialValue: _filters.warehouseOrLocation,
                    decoration: const InputDecoration(
                      labelText: 'Warehouse / Location',
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...snapshot.availableWarehousesOrLocations.map(
                        (String value) => DropdownMenuItem<String?>(
                          value: value,
                          child: Text(value),
                        ),
                      ),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _filters = _filters.copyWith(
                          warehouseOrLocation: value,
                          clearWarehouseOrLocation: value == null,
                        );
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey<String?>(_filters.category),
                    initialValue: _filters.category,
                    decoration: const InputDecoration(
                      labelText: 'Product Category',
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...snapshot.availableCategories.map(
                        (String value) => DropdownMenuItem<String?>(
                          value: value,
                          child: Text(value),
                        ),
                      ),
                    ],
                    onChanged: (String? value) {
                      setState(
                        () => _filters = _filters.copyWith(
                          category: value,
                          clearCategory: value == null,
                        ),
                      );
                    },
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _filters.isEmpty
                      ? null
                      : () =>
                            setState(() => _filters = const DashboardFilters()),
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Clear Filters'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Filtered Documents (${snapshot.documents.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(label: Text('Reference')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Warehouse')),
                DataColumn(label: Text('Location')),
                DataColumn(label: Text('Category')),
              ],
              rows: snapshot.documents
                  .map(
                    (InventoryDocument doc) => DataRow(
                      cells: <DataCell>[
                        DataCell(Text(doc.reference)),
                        DataCell(Text(_docTypeLabel(doc.type))),
                        DataCell(Text(_statusLabel(doc.status))),
                        DataCell(Text(doc.warehouse)),
                        DataCell(Text(doc.location)),
                        DataCell(Text(doc.category)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _docTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.receipts:
        return 'Receipts';
      case DocumentType.deliveries:
        return 'Deliveries';
      case DocumentType.internal:
        return 'Internal';
      case DocumentType.adjustments:
        return 'Adjustments';
    }
  }

  String _statusLabel(InventoryStatus status) {
    switch (status) {
      case InventoryStatus.draft:
        return 'Draft';
      case InventoryStatus.waiting:
        return 'Waiting';
      case InventoryStatus.ready:
        return 'Ready';
      case InventoryStatus.done:
        return 'Done';
      case InventoryStatus.canceled:
        return 'Canceled';
    }
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: <Color>[
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(label),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
