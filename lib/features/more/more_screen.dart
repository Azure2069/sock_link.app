import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/utils.dart';
import '../debts/debts_screen.dart';
import '../expenses/expenses_screen.dart';
import '../inventory/inventory_screen.dart';
import '../reports/reports_screen.dart';

class MoreScreen extends ConsumerWidget {
  final BusinessData business;
  final VoidCallback onLock;
  const MoreScreen({super.key, required this.business, required this.onLock});
  @override
  Widget build(BuildContext c, WidgetRef ref) => Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(children: [
        ListTile(
            leading: const Icon(Icons.swap_vert),
            title: const Text('Inventory movements'),
            onTap: () => go(c, const InventoryScreen())),
        ListTile(
            leading: const Icon(Icons.credit_score),
            title: const Text('Debts'),
            onTap: () => go(c, const DebtsScreen())),
        ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Expenses'),
            onTap: () => go(c, const ExpensesScreen())),
        ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            onTap: () => go(c, const ReportsScreen())),
        const Divider(),
        ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Business settings'),
            subtitle: Text(business.name),
            onTap: () => _settings(c, ref, business)),
        ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Lock app'),
            onTap: onLock)
      ]));
}

void go(BuildContext c, Widget w) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => w));
Future<void> _settings(BuildContext c, WidgetRef ref, BusinessData b) async {
  final name = TextEditingController(text: b.name),
      owner = TextEditingController(text: b.ownerName),
      phone = TextEditingController(text: b.phone),
      loc = TextEditingController(text: b.location),
      tax = TextEditingController(text: b.taxRate.toString()),
      pin = TextEditingController();
  await showDialog(
      context: c,
      builder: (d) => AlertDialog(
              title: const Text('Business settings'),
              content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: name,
                        decoration:
                            const InputDecoration(labelText: 'Business name')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: owner,
                        decoration: const InputDecoration(labelText: 'Owner')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: phone,
                        decoration: const InputDecoration(labelText: 'Phone')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: loc,
                        decoration:
                            const InputDecoration(labelText: 'Location')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: tax,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Tax rate (%)')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: pin,
                        maxLength: 4,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'New PIN (leave blank to keep current)'))
                  ]))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(d),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () async {
                      final db = ref.read(databaseProvider);
                      await (db.update(db.businesses)
                            ..where((t) => t.id.equals(b.id)))
                          .write(BusinessesCompanion(
                              name: Value(name.text.trim()),
                              ownerName: Value(owner.text.trim()),
                              phone: Value(phone.text.trim()),
                              location: Value(loc.text.trim()),
                              taxRate: Value(double.tryParse(tax.text) ?? 0),
                              pinHash: pin.text.isEmpty
                                  ? const Value.absent()
                                  : Value(hashPin(pin.text))));
                      if (d.mounted) Navigator.pop(d);
                    },
                    child: const Text('Save'))
              ]));
  for (final x in [name, owner, phone, loc, tax, pin]) x.dispose();
}
