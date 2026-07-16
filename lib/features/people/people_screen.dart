import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: _PeopleAppBar(),
          body: TabBarView(children: [_Customers(), _Suppliers()]),
        ),
      );
}

class _PeopleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PeopleAppBar();
  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
        title: const Text('Customers & suppliers'),
        bottom: const TabBar(
            tabs: [Tab(text: 'Customers'), Tab(text: 'Suppliers')]),
      );
}

class _Customers extends ConsumerWidget {
  const _Customers();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(customersProvider).valueOrNull ?? [];
    return _PeopleList(
      label: 'Add customer',
      rows: rows.map((row) => (row.name, row.phone)).toList(),
      onAdd: () => _personDialog(context, ref, true),
    );
  }
}

class _Suppliers extends ConsumerWidget {
  const _Suppliers();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(suppliersProvider).valueOrNull ?? [];
    return _PeopleList(
      label: 'Add supplier',
      rows: rows.map((row) => (row.name, row.phone)).toList(),
      onAdd: () => _personDialog(context, ref, false),
    );
  }
}

class _PeopleList extends StatelessWidget {
  const _PeopleList(
      {required this.onAdd, required this.rows, required this.label});
  final VoidCallback onAdd;
  final List<(String, String)> rows;
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(
        floatingActionButton: FloatingActionButton.extended(
            onPressed: onAdd, icon: const Icon(Icons.add), label: Text(label)),
        body: rows.isEmpty
            ? const Center(child: Text('No records yet'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, index) => ListTile(
                  leading: CircleAvatar(
                      child:
                          Text(rows[index].$1.substring(0, 1).toUpperCase())),
                  title: Text(rows[index].$1),
                  subtitle: Text(rows[index].$2),
                ),
              ),
      );
}

Future<void> _personDialog(
    BuildContext context, WidgetRef ref, bool customer) async {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(customer ? 'Add customer' : 'Add supplier'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 10),
        TextField(
            controller: phone,
            decoration: const InputDecoration(labelText: 'Phone')),
        const SizedBox(height: 10),
        TextField(
            controller: address,
            decoration: const InputDecoration(labelText: 'Address')),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (name.text.trim().isEmpty) return;
            final db = ref.read(databaseProvider);
            if (customer) {
              await db.into(db.customers).insert(CustomersCompanion.insert(
                  name: name.text.trim(),
                  phone: Value(phone.text.trim()),
                  address: Value(address.text.trim())));
            } else {
              await db.into(db.suppliers).insert(SuppliersCompanion.insert(
                  name: name.text.trim(),
                  phone: Value(phone.text.trim()),
                  address: Value(address.text.trim())));
            }
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  name.dispose();
  phone.dispose();
  address.dispose();
}
