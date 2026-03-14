import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedWarehouse;
  bool _onlyLowStock = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).productService;

    return AnimatedBuilder(
      animation: service,
      builder: (BuildContext context, Widget? child) {
        final List<Product> filteredProducts = service.smartFilterProducts(
          query: _searchController.text,
          category: _selectedCategory,
          warehouse: _selectedWarehouse,
          onlyLowStock: _onlyLowStock,
        );

        final List<LowStockAlert> alerts = service.lowStockAlerts;

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
                    Theme.of(context).colorScheme.tertiaryContainer,
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
                      ).colorScheme.surface.withValues(alpha: 0.74),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Products',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Manage SKUs, categories, and warehouse distribution',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showProductDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Product'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Product Categories: ${service.categories.join(', ')}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Search SKU / Name / Category',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String?>(
                        key: ValueKey<String?>(_selectedCategory),
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...service.categories.map(
                            (String category) => DropdownMenuItem<String?>(
                              value: category,
                              child: Text(category),
                            ),
                          ),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String?>(
                        key: ValueKey<String?>(_selectedWarehouse),
                        initialValue: _selectedWarehouse,
                        decoration: const InputDecoration(
                          labelText: 'Warehouse',
                          border: OutlineInputBorder(),
                        ),
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Warehouses'),
                          ),
                          ...service.warehouses.map(
                            (String warehouse) => DropdownMenuItem<String?>(
                              value: warehouse,
                              child: Text(warehouse),
                            ),
                          ),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            _selectedWarehouse = value;
                          });
                        },
                      ),
                    ),
                    FilterChip(
                      label: const Text('Low stock only'),
                      selected: _onlyLowStock,
                      onSelected: (bool selected) {
                        setState(() => _onlyLowStock = selected);
                      },
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _selectedCategory = null;
                          _selectedWarehouse = null;
                          _onlyLowStock = false;
                        });
                      },
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Reset Filters'),
                    ),
                  ],
                ),
              ),
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
            const SizedBox(height: 12),
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const <DataColumn>[
                    DataColumn(label: Text('SKU / Code')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Unit of Measure')),
                    DataColumn(label: Text('Warehouse Totals')),
                    DataColumn(label: Text('Stock by Location')),
                    DataColumn(label: Text('Total Stock')),
                    DataColumn(label: Text('Reorder Point')),
                    DataColumn(label: Text('Reorder Qty')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: filteredProducts
                      .map(
                        (Product product) => DataRow(
                          cells: <DataCell>[
                            DataCell(Text(product.skuCode)),
                            DataCell(Text(product.name)),
                            DataCell(Text(product.category)),
                            DataCell(Text(product.unitOfMeasure)),
                            DataCell(
                              Text(
                                _locationStockText(
                                  service.stockByWarehouse(product),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(_locationStockText(product.stockByLocation)),
                            ),
                            DataCell(Text(product.totalStock.toString())),
                            DataCell(Text(product.reorderPoint.toString())),
                            DataCell(Text(product.reorderQuantity.toString())),
                            DataCell(
                              TextButton(
                                onPressed: () => _showProductDialog(
                                  context,
                                  product: product,
                                ),
                                child: const Text('Update'),
                              ),
                            ),
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

  String _locationStockText(Map<String, int> stockByLocation) {
    return stockByLocation.entries
        .map((MapEntry<String, int> e) => '${e.key}: ${e.value}')
        .join(' | ');
  }

  Future<void> _showProductDialog(
    BuildContext context, {
    Product? product,
  }) async {
    final bool isEdit = product != null;
    final TextEditingController idController = TextEditingController(
      text: product?.skuCode ?? '',
    );
    final TextEditingController nameController = TextEditingController(
      text: product?.name ?? '',
    );
    final TextEditingController categoryController = TextEditingController(
      text: product?.category ?? '',
    );
    final TextEditingController uomController = TextEditingController(
      text: product?.unitOfMeasure ?? '',
    );
    final TextEditingController reorderPointController = TextEditingController(
      text: product?.reorderPoint.toString() ?? '0',
    );
    final TextEditingController reorderQtyController = TextEditingController(
      text: product?.reorderQuantity.toString() ?? '0',
    );
    final TextEditingController stockController = TextEditingController(
      text: product == null
          ? ''
          : product.stockByLocation.entries
                .map((MapEntry<String, int> e) => '${e.key}:${e.value}')
                .join(','),
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEdit ? 'Update Product' : 'Create Product'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: idController,
                  enabled: !isEdit,
                  decoration: const InputDecoration(labelText: 'SKU / Code'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: uomController,
                  decoration: const InputDecoration(
                    labelText: 'Unit of Measure',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock by Location',
                    helperText:
                        'Initial stock optional. Format: Main WH-A1:120,Dispatch WH-D1:20',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reorderPointController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reorder Point'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reorderQtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reorder Quantity',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final Product upsert = Product(
                  skuCode: idController.text.trim(),
                  name: nameController.text.trim(),
                  category: categoryController.text.trim(),
                  unitOfMeasure: uomController.text.trim(),
                  reorderPoint:
                      int.tryParse(reorderPointController.text.trim()) ?? 0,
                  reorderQuantity:
                      int.tryParse(reorderQtyController.text.trim()) ?? 0,
                  stockByLocation: _parseStockInput(
                    stockController.text.trim(),
                  ),
                );

                if (upsert.id.isEmpty ||
                    upsert.name.isEmpty ||
                    upsert.category.isEmpty ||
                    upsert.unitOfMeasure.isEmpty) {
                  return;
                }

                final service = AppScope.of(context).productService;
                if (isEdit) {
                  service.updateProduct(upsert);
                } else {
                  service.createProduct(upsert);
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

  Map<String, int> _parseStockInput(String text) {
    if (text.isEmpty) {
      return <String, int>{};
    }

    final Map<String, int> result = <String, int>{};
    final List<String> pairs = text.split(',');

    for (final String pair in pairs) {
      final List<String> tokens = pair.split(':');
      if (tokens.length != 2) {
        continue;
      }
      final String location = tokens[0].trim();
      final int quantity = int.tryParse(tokens[1].trim()) ?? 0;
      if (location.isEmpty) {
        continue;
      }
      result[location] = quantity;
    }

    return result;
  }
}
