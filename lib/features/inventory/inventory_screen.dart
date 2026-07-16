import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory movements')),
      body: products.when(
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final product = items[index];
            return Card(
              child: ListTile(
                title: Text(product.name),
                subtitle: Text('Current: ${product.quantity} ${product.unit}'),
                trailing: FilledButton.tonal(
                  onPressed: () => _adjust(context, ref, product),
                  child: const Text('Adjust'),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

Future<void> _adjust(
    BuildContext context, WidgetRef ref, ProductData product) async {
  var type = 'stock_in';
  final quantity = TextEditingController();
  final note = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Adjust ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'stock_in', child: Text('Stock in')),
                DropdownMenuItem(value: 'stock_out', child: Text('Stock out')),
                DropdownMenuItem(
                    value: 'damaged', child: Text('Damaged goods')),
                DropdownMenuItem(
                    value: 'returned', child: Text('Returned goods')),
                DropdownMenuItem(
                    value: 'adjustment', child: Text('Set exact quantity')),
              ],
              onChanged: (value) => setState(() => type = value!),
            ),
            const SizedBox(height: 10),
            TextField(
                controller: quantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity')),
            const SizedBox(height: 10),
            TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(quantity.text) ?? 0;
              if (value < 0) return;
              late final double newQuantity;
              late final double movement;
              if (type == 'adjustment') {
                newQuantity = value;
                movement = value - product.quantity;
              } else if (type == 'stock_in' || type == 'returned') {
                newQuantity = product.quantity + value;
                movement = value;
              } else {
                newQuantity = product.quantity - value;
                movement = -value;
                if (newQuantity < 0) return;
              }
              final db = ref.read(databaseProvider);
              await (db.update(db.products)
                    ..where((row) => row.id.equals(product.id)))
                  .write(ProductsCompanion(quantity: Value(newQuantity)));
              await db
                  .into(db.stockMovements)
                  .insert(StockMovementsCompanion.insert(
                    productId: product.id,
                    type: type,
                    quantity: movement,
                    note: Value(note.text),
                  ));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  quantity.dispose();
  note.dispose();
}
