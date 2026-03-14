import 'package:flutter/foundation.dart';

import '../models/warehouse.dart';

class WarehouseService extends ChangeNotifier {
  final List<Warehouse> _warehouses = <Warehouse>[
    const Warehouse(code: 'MAIN', name: 'Main WH'),
    const Warehouse(code: 'DSP', name: 'Dispatch WH'),
    const Warehouse(code: 'MNT', name: 'Maintenance WH'),
  ];

  List<Warehouse> get warehouses => List<Warehouse>.unmodifiable(_warehouses);

  void addWarehouse(Warehouse warehouse) {
    _warehouses.add(warehouse);
    notifyListeners();
  }

  void updateWarehouse(Warehouse warehouse) {
    final int index = _warehouses.indexWhere(
      (Warehouse w) => w.code == warehouse.code,
    );
    if (index == -1) {
      return;
    }
    _warehouses[index] = warehouse;
    notifyListeners();
  }
}
