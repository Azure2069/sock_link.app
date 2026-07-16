import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/utils.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
              onPressed: () => _categoryDialog(context, ref),
              icon: const Icon(Icons.category))
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _productDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: products.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('No products yet'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final product = items[index];
                  return Card(
                    child: ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                          '${product.quantity} ${product.unit} • ${money(product.sellingPrice)}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'edit')
                            await _productDialog(context, ref, product);
                          if (action == 'delete') {
                            final db = ref.read(databaseProvider);
                            await (db.delete(db.products)
                                  ..where((row) => row.id.equals(product.id)))
                                .go();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
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

Future<CategoryData?> _categoryDialog(
    BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final category = await showDialog<CategoryData>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('New category'),
      content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category name')),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (controller.text.trim().isEmpty) return;
            final db = ref.read(databaseProvider);
            final id = await db.into(db.categories).insert(
                  CategoriesCompanion.insert(name: controller.text.trim()),
                  mode: InsertMode.insertOrIgnore,
                );
            final saved = id > 0
                ? await (db.select(db.categories)
                      ..where((row) => row.id.equals(id)))
                    .getSingle()
                : await (db.select(db.categories)
                      ..where((row) => row.name.equals(controller.text.trim())))
                    .getSingle();
            if (dialogContext.mounted) Navigator.pop(dialogContext, saved);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  return category;
}

Future<void> _productDialog(BuildContext context, WidgetRef ref,
    [ProductData? product]) async {
  final name = TextEditingController(text: product?.name);
  final sku = TextEditingController(text: product?.sku);
  final cost = TextEditingController(text: product?.costPrice.toString());
  final selling = TextEditingController(text: product?.sellingPrice.toString());
  final quantity =
      TextEditingController(text: product?.quantity.toString() ?? '0');
  final unit = TextEditingController(text: product?.unit ?? 'pcs');
  final minimum =
      TextEditingController(text: product?.minimumStock.toString() ?? '0');
  final notes = TextEditingController(text: product?.notes);
  final newCategory = TextEditingController();
  var categoryId = product?.categoryId;
  var addingCategory = false;
  ProductsCompanion? pendingSave;
  var openingQuantity = 0.0;
  final db = ref.read(databaseProvider);
  var categories = await db.select(db.categories).get();
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(product == null ? 'Add product' : 'Edit product'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 10),
              TextField(
                  controller: sku,
                  decoration: const InputDecoration(
                    labelText: 'SKU (optional)',
                    helperText: 'Your product code, e.g. RICE-5KG',
                  )),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                key: ValueKey(categoryId),
                initialValue: categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('None')),
                  ...categories.map((category) => DropdownMenuItem<int?>(
                      value: category.id, child: Text(category.name))),
                ],
                onChanged: (value) => setState(() => categoryId = value),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => addingCategory = !addingCategory),
                  icon: const Icon(Icons.add),
                  label: Text(categories.isEmpty
                      ? 'Create your first category'
                      : 'Add another category'),
                ),
              ),
              if (addingCategory) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: newCategory,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'New category name',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final categoryName = newCategory.text.trim();
                        if (categoryName.isEmpty) return;
                        await db.into(db.categories).insert(
                              CategoriesCompanion.insert(name: categoryName),
                              mode: InsertMode.insertOrIgnore,
                            );
                        final created = await (db.select(db.categories)
                              ..where((row) => row.name.equals(categoryName)))
                            .getSingle();
                        categories = await db.select(db.categories).get();
                        newCategory.clear();
                        setState(() {
                          categoryId = created.id;
                          addingCategory = false;
                        });
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: cost,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Cost price'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: selling,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Selling price'))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: quantity,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Quantity'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: unit,
                        decoration: const InputDecoration(labelText: 'Unit'))),
              ]),
              const SizedBox(height: 10),
              TextField(
                  controller: minimum,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Minimum stock')),
              const SizedBox(height: 10),
              TextField(
                  controller: notes,
                  decoration: const InputDecoration(labelText: 'Notes')),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              pendingSave = ProductsCompanion(
                name: Value(name.text.trim()),
                sku: Value(sku.text.trim().isEmpty ? null : sku.text.trim()),
                categoryId: Value(categoryId),
                costPrice: Value(double.tryParse(cost.text) ?? 0),
                sellingPrice: Value(double.tryParse(selling.text) ?? 0),
                quantity: Value(double.tryParse(quantity.text) ?? 0),
                unit:
                    Value(unit.text.trim().isEmpty ? 'pcs' : unit.text.trim()),
                minimumStock: Value(double.tryParse(minimum.text) ?? 0),
                notes: Value(notes.text.trim()),
              );
              openingQuantity = double.tryParse(quantity.text) ?? 0;
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );

  // Let the modal route finish unmounting before the database stream rebuilds
  // the products screen behind it.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  final values = pendingSave;
  if (values != null) {
    if (product == null) {
      final id = await db.into(db.products).insert(values);
      if (openingQuantity != 0) {
        await db.into(db.stockMovements).insert(
              StockMovementsCompanion.insert(
                productId: id,
                type: 'opening',
                quantity: openingQuantity,
              ),
            );
      }
    } else {
      await (db.update(db.products)..where((row) => row.id.equals(product.id)))
          .write(values);
    }
  }
  for (final controller in [
    name,
    sku,
    cost,
    selling,
    quantity,
    unit,
    minimum,
    notes,
    newCategory,
  ]) {
    controller.dispose();
  }
}
