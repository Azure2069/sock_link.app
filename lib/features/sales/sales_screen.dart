import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/utils.dart';
import 'checkout_screen.dart';
import 'sale_detail_screen.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(salesProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Sales')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CheckoutScreen())),
            icon: const Icon(Icons.add),
            label: const Text('New sale')),
        body: s.when(
            data: (rows) => rows.isEmpty
                ? const Center(child: Text('No sales yet'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (c, i) {
                      final x = rows[i];
                      return Card(
                          child: ListTile(
                              onTap: () => Navigator.push(
                                  c,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          SaleDetailScreen(sale: x))),
                              title: Text(x.invoiceNumber),
                              subtitle: Text(shortDate(x.createdAt)),
                              trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(money(x.total),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(x.status)
                                  ])));
                    }),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e')));
  }
}
