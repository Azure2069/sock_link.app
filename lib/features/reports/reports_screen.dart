import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/utils.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final sales = ref.watch(salesProvider).valueOrNull ?? [];
    final ex = ref.watch(expensesProvider).valueOrNull ?? [];
    final now = DateTime.now();
    bool sameMonth(DateTime d) => d.year == now.year && d.month == now.month;
    final monthSales = sales
        .where((x) => sameMonth(x.createdAt))
        .fold<double>(0, (s, x) => s + x.total);
    final monthPaid = sales
        .where((x) => sameMonth(x.createdAt))
        .fold<double>(0, (s, x) => s + x.paid);
    final monthExpenses = ex
        .where((x) => sameMonth(x.createdAt))
        .fold<double>(0, (s, x) => s + x.amount);
    return Scaffold(
        appBar: AppBar(title: const Text('Reports')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text('This month', style: Theme.of(c).textTheme.headlineSmall),
          const SizedBox(height: 12),
          _card('Sales', monthSales, Icons.payments),
          const SizedBox(height: 10),
          _card('Payments received', monthPaid, Icons.account_balance_wallet),
          const SizedBox(height: 10),
          _card('Expenses', monthExpenses, Icons.receipt_long),
          const SizedBox(height: 10),
          _card('Net cash', monthPaid - monthExpenses, Icons.trending_up),
          const SizedBox(height: 24),
          Text(
              'Sales count: ${sales.where((x) => sameMonth(x.createdAt)).length}'),
          Text(
              'All-time sales: ${money(sales.fold<double>(0, (s, x) => s + x.total))}')
        ]));
  }

  Widget _card(String t, double v, IconData i) => Card(
      child: ListTile(
          leading: Icon(i),
          title: Text(t),
          trailing: Text(money(v),
              style: const TextStyle(fontWeight: FontWeight.bold))));
}
