import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/utils.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ref.watch(debtsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Outstanding debts')),
      body: debts.when(
        data: (items) {
          final outstanding =
              items.where((item) => item.status != 'paid').toList();
          if (outstanding.isEmpty) {
            return const Center(child: Text('No outstanding debts'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: outstanding
                .map((debt) => Card(
                      child: ListTile(
                        title: Text('Sale #${debt.saleId}'),
                        subtitle: Text(shortDate(debt.createdAt)),
                        trailing: FilledButton.tonal(
                          onPressed: () => _pay(context, ref, debt),
                          child: Text(money(debt.balance)),
                        ),
                      ),
                    ))
                .toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

Future<void> _pay(BuildContext context, WidgetRef ref, DebtData debt) async {
  final amountController = TextEditingController();
  var method = 'cash';
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Record debt payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Balance: ${money(debt.balance)}'),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: method,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'momo', child: Text('MoMo')),
              ],
              onChanged: (value) => setState(() => method = value!),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(databaseProvider).recordDebtPayment(
                      debt,
                      double.tryParse(amountController.text) ?? 0,
                      method,
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(SnackBar(content: Text('$error')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  amountController.dispose();
}
