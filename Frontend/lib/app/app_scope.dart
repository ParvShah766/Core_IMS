import 'package:flutter/widgets.dart';

import 'app_session.dart';
import '../features/dashboard/services/dashboard_service.dart';
import '../features/operations/services/operations_service.dart';
import '../features/products/services/product_service.dart';
import '../features/settings/services/warehouse_service.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.session,
    required this.dashboardService,
    required this.operationsService,
    required this.productService,
    required this.warehouseService,
    required super.child,
  });

  final AppSession session;
  final DashboardService dashboardService;
  final OperationsService operationsService;
  final ProductService productService;
  final WarehouseService warehouseService;

  static AppScope of(BuildContext context) {
    final AppScope? result = context
        .dependOnInheritedWidgetOfExactType<AppScope>();
    assert(result != null, 'No AppScope found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return session != oldWidget.session ||
        dashboardService != oldWidget.dashboardService ||
        operationsService != oldWidget.operationsService ||
        productService != oldWidget.productService ||
        warehouseService != oldWidget.warehouseService;
  }
}
