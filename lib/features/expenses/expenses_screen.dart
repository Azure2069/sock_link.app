import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/utils.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addExpense(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: expenses.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('No expenses'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, index) => ListTile(
                  title: Text(items[index].category),
                  subtitle: Text(
                      '${items[index].description}\n${shortDate(items[index].createdAt)}'),
                  trailing: Text(money(items[index].amount)),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

Future<void> _addExpense(BuildContext context, WidgetRef ref) async {
  var category = 'Transport';
  final amount = TextEditingController();
  final description = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: category,
              items: [
                'Transport',
                'Rent',
                'Utilities',
                'Salaries',
                'Miscellaneous'
              ]
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() => category = value!),
            ),
            const SizedBox(height: 10),
            TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount')),
            const SizedBox(height: 10),
            TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(amount.text) ?? 0;
              if (value <= 0) return;
              final db = ref.read(databaseProvider);
              await db.into(db.expenses).insert(ExpensesCompanion.insert(
                    category: category,
                    amount: value,
                    description: Value(description.text),
                  ));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  amount.dispose();
  description.dispose();
}
