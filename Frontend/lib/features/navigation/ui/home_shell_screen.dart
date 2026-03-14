import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../auth/ui/login_screen.dart';
import '../../dashboard/ui/widgets/dashboard_panel.dart';
import '../../operations/ui/operations_views.dart';
import '../../products/ui/products_screen.dart';
import '../../profile/ui/my_profile_screen.dart';
import '../../settings/ui/warehouse_settings_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  _MenuItem _selected = _MenuItem.dashboard;

  @override
  Widget build(BuildContext context) {
    final appScope = AppScope.of(context);
    final user = appScope.session.currentUser;
    final bool compact = MediaQuery.sizeOf(context).width < 1100;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login.')));
    }

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned(
            top: -140,
            right: -60,
            child: _AuraBlob(
              color: Theme.of(context).colorScheme.primaryContainer,
              size: 360,
            ),
          ),
          Positioned(
            bottom: -180,
            left: -100,
            child: _AuraBlob(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              size: 380,
            ),
          ),
          Row(
            children: <Widget>[
              Container(
                width: compact ? 240 : 290,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Theme.of(context).colorScheme.surfaceContainer,
                      Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: <Widget>[
                          Container(
                            height: 34,
                            width: 34,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Core IMS',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle('Products'),
                    _tile(
                      _MenuItem.products,
                      'Products',
                      Icons.inventory_2_outlined,
                    ),
                    const SizedBox(height: 10),
                    _sectionTitle('Operations'),
                    _tile(
                      _MenuItem.receipts,
                      'Receipts',
                      Icons.move_to_inbox_outlined,
                    ),
                    _tile(
                      _MenuItem.deliveryOrders,
                      'Delivery Orders',
                      Icons.local_shipping_outlined,
                    ),
                    _tile(
                      _MenuItem.internalTransfers,
                      'Internal Transfers',
                      Icons.compare_arrows,
                    ),
                    _tile(
                      _MenuItem.inventoryAdjustment,
                      'Inventory Adjustment',
                      Icons.tune_outlined,
                    ),
                    _tile(
                      _MenuItem.moveHistory,
                      'Move History',
                      Icons.swap_horiz,
                    ),
                    _tile(
                      _MenuItem.dashboard,
                      'Dashboard',
                      Icons.dashboard_outlined,
                    ),
                    _tile(
                      _MenuItem.settingWarehouse,
                      'Setting - Warehouse',
                      Icons.warehouse_outlined,
                    ),
                    const SizedBox(height: 10),
                    _sectionTitle('Profile Menu'),
                    _tile(
                      _MenuItem.myProfile,
                      'My Profile',
                      Icons.person_outline,
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: 58,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.9),
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _titleFor(_selected),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.88),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: KeyedSubtree(
                                key: ValueKey<_MenuItem>(_selected),
                                child: _viewFor(_selected),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _tile(_MenuItem item, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selected == item,
      selectedTileColor: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.72),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      onTap: () => setState(() => _selected = item),
    );
  }

  Widget _viewFor(_MenuItem item) {
    switch (item) {
      case _MenuItem.products:
        return const ProductsScreen();
      case _MenuItem.receipts:
        return const ReceiptOperationsView();
      case _MenuItem.deliveryOrders:
        return const DeliveryOrdersView();
      case _MenuItem.internalTransfers:
        return const InternalTransfersView();
      case _MenuItem.inventoryAdjustment:
        return const StockAdjustmentsView();
      case _MenuItem.moveHistory:
        return const MoveHistoryView();
      case _MenuItem.dashboard:
        return const DashboardPanel();
      case _MenuItem.settingWarehouse:
        return const WarehouseSettingsScreen();
      case _MenuItem.myProfile:
        return const MyProfileScreen();
    }
  }

  String _titleFor(_MenuItem item) {
    switch (item) {
      case _MenuItem.products:
        return 'Products';
      case _MenuItem.receipts:
        return 'Operations - Receipts';
      case _MenuItem.deliveryOrders:
        return 'Operations - Delivery Orders';
      case _MenuItem.internalTransfers:
        return 'Operations - Internal Transfers';
      case _MenuItem.inventoryAdjustment:
        return 'Operations - Inventory Adjustment';
      case _MenuItem.moveHistory:
        return 'Operations - Move History';
      case _MenuItem.dashboard:
        return 'Dashboard';
      case _MenuItem.settingWarehouse:
        return 'Setting - Warehouse';
      case _MenuItem.myProfile:
        return 'My Profile';
    }
  }

  void _logout() {
    final appScope = AppScope.of(context);
    appScope.session.logout();
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (Route<dynamic> r) => false,
    );
  }
}

class _AuraBlob extends StatelessWidget {
  const _AuraBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.32),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MenuItem {
  products,
  receipts,
  deliveryOrders,
  internalTransfers,
  inventoryAdjustment,
  moveHistory,
  dashboard,
  settingWarehouse,
  myProfile,
}
