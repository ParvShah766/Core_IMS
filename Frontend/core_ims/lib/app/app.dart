import 'package:flutter/material.dart';

import '../features/auth/services/auth_service.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/reset_password_screen.dart';
import '../features/auth/ui/signup_screen.dart';
import '../features/dashboard/services/dashboard_service.dart';
import '../features/navigation/ui/home_shell_screen.dart';
import '../features/operations/services/operations_service.dart';
import '../features/products/services/product_service.dart';
import '../features/settings/services/warehouse_service.dart';
import 'app_scope.dart';
import 'app_session.dart';
import 'app_theme.dart';

class CoreImsApp extends StatefulWidget {
  const CoreImsApp({super.key});

  @override
  State<CoreImsApp> createState() => _CoreImsAppState();
}

class _CoreImsAppState extends State<CoreImsApp> {
  late final AuthService _authService;
  late final DashboardService _dashboardService;
  late final ProductService _productService;
  late final OperationsService _operationsService;
  late final WarehouseService _warehouseService;
  late final AppSession _session;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _dashboardService = DashboardService();
    _productService = ProductService();
    _operationsService = OperationsService(productService: _productService);
    _warehouseService = WarehouseService();
    _session = AppSession(authService: _authService);
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      session: _session,
      dashboardService: _dashboardService,
      operationsService: _operationsService,
      productService: _productService,
      warehouseService: _warehouseService,
      child: AnimatedBuilder(
        animation: _session,
        builder: (BuildContext context, Widget? child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Core IMS',
            theme: AppTheme.lightTheme,
            routes: <String, WidgetBuilder>{
              LoginScreen.routeName: (_) => const LoginScreen(),
              SignUpScreen.routeName: (_) => const SignUpScreen(),
              ResetPasswordScreen.routeName: (_) => const ResetPasswordScreen(),
              HomeShellScreen.routeName: (_) => const HomeShellScreen(),
            },
            home: _session.isAuthenticated
                ? const HomeShellScreen()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
