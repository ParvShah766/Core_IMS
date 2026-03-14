import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../auth/models/app_user.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppUser? user = AppScope.of(context).session.currentUser;
    if (user == null) {
      return const Center(child: Text('No active user.'));
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'My Profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _ProfileRow(label: 'Name', value: user.fullName),
            _ProfileRow(label: 'Email', value: user.email),
            _ProfileRow(
              label: 'Role',
              value: user.role == UserRole.inventoryManager
                  ? 'Inventory Manager'
                  : 'Warehouse Staff',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
