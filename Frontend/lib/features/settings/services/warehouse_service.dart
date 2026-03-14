import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../app/api_config.dart';
import '../models/warehouse.dart';

class WarehouseService extends ChangeNotifier {
  WarehouseService() {
    unawaited(loadFromBackend());
  }

  List<Warehouse> _warehouses = <Warehouse>[
    const Warehouse(code: 'MAIN', name: 'Main WH'),
    const Warehouse(code: 'DSP', name: 'Dispatch WH'),
    const Warehouse(code: 'MNT', name: 'Maintenance WH'),
  ];

  List<Warehouse> get warehouses => List<Warehouse>.unmodifiable(_warehouses);

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<void> loadFromBackend() async {
    try {
      final http.Response response = await http.get(_uri('/api/warehouses'));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final List<dynamic> decoded = jsonDecode(response.body) as List<dynamic>;
      final List<Warehouse> remoteWarehouses = decoded
          .whereType<Map<String, dynamic>>()
          .map(_fromJson)
          .toList();

      if (remoteWarehouses.isEmpty) {
        return;
      }

      _warehouses = remoteWarehouses;
      notifyListeners();
    } catch (_) {
      // Keep local seed data if backend is unavailable.
    }
  }

  Warehouse _fromJson(Map<String, dynamic> json) {
    return Warehouse(
      code: (json['code'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
    );
  }

  Future<void> addWarehouse(Warehouse warehouse) async {
    _warehouses.add(warehouse);
    notifyListeners();
    unawaited(_createRemoteWarehouse(warehouse));
  }

  Future<void> _createRemoteWarehouse(Warehouse warehouse) async {
    try {
      await http.post(
        _uri('/api/warehouses'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{
          'code': warehouse.code,
          'name': warehouse.name,
        }),
      );
    } catch (_) {
      // Ignore errors
    }
  }

  Future<void> updateWarehouse(Warehouse warehouse) async {
    final int index = _warehouses.indexWhere(
      (Warehouse w) => w.code == warehouse.code,
    );
    if (index == -1) {
      return;
    }
    _warehouses[index] = warehouse;
    notifyListeners();
    unawaited(_updateRemoteWarehouse(warehouse));
  }

  Future<void> _updateRemoteWarehouse(Warehouse warehouse) async {
    try {
      await http.put(
        _uri('/api/warehouses/${warehouse.code}'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{'name': warehouse.name}),
      );
    } catch (_) {
      // Ignore errors
    }
  }
}
