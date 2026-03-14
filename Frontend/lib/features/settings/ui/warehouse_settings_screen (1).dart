import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../models/warehouse.dart';

class WarehouseSettingsScreen extends StatelessWidget {
  const WarehouseSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).warehouseService;

    return AnimatedBuilder(
      animation: service,
      builder: (BuildContext context, Widget? child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'Warehouse Settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showWarehouseDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Warehouse'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: DataTable(
                columns: const <DataColumn>[
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: service.warehouses
                    .map(
                      (Warehouse warehouse) => DataRow(
                        cells: <DataCell>[
                          DataCell(Text(warehouse.code)),
                          DataCell(Text(warehouse.name)),
                          DataCell(
                            TextButton(
                              onPressed: () => _showWarehouseDialog(
                                context,
                                warehouse: warehouse,
                              ),
                              child: const Text('Edit'),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showWarehouseDialog(
    BuildContext context, {
    Warehouse? warehouse,
  }) async {
    final TextEditingController codeController = TextEditingController(
      text: warehouse?.code ?? '',
    );
    final TextEditingController nameController = TextEditingController(
      text: warehouse?.name ?? '',
    );
    final bool isEdit = warehouse != null;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Warehouse' : 'Add Warehouse'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Code'),
                enabled: !isEdit,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final Warehouse updated = Warehouse(
                  code: codeController.text.trim().toUpperCase(),
                  name: nameController.text.trim(),
                );

                if (updated.code.isEmpty || updated.name.isEmpty) {
                  return;
                }

                final service = AppScope.of(context).warehouseService;
                if (isEdit) {
                  service.updateWarehouse(updated);
                } else {
                  service.addWarehouse(updated);
                }

                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
