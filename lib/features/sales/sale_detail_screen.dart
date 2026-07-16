import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../../core/utils.dart';

class SaleDetailScreen extends ConsumerWidget {
  final SaleData sale;
  const SaleDetailScreen({super.key, required this.sale});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return Scaffold(
        appBar: AppBar(title: Text(sale.invoiceNumber)),
        body: FutureBuilder(
            future: Future.wait(
                [db.saleItemsFor(sale.id), db.paymentsFor(sale.id)]),
            builder: (c, s) {
              if (!s.hasData)
                return const Center(child: CircularProgressIndicator());
              final items = s.data![0] as List<SaleItemData>;
              final pays = s.data![1] as List<PaymentData>;
              return ListView(padding: const EdgeInsets.all(16), children: [
                Text(shortDate(sale.createdAt)),
                const SizedBox(height: 16),
                ...items.map((i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(i.productName),
                    subtitle: Text('${i.quantity} × ${money(i.unitPrice)}'),
                    trailing: Text(money(i.total)))),
                const Divider(),
                _line('Subtotal', sale.subtotal),
                _line('Discount', sale.discount),
                _line('Tax', sale.tax),
                _line('Total', sale.total, b: true),
                _line('Paid', sale.paid),
                _line('Balance', sale.total - sale.paid),
                const SizedBox(height: 20),
                Text('Payments',
                    style: Theme.of(context).textTheme.titleMedium),
                ...pays.map((p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.method.toUpperCase()),
                    subtitle: Text([p.network, p.phone, p.reference]
                        .whereType<String>()
                        .where((e) => e.isNotEmpty)
                        .join(' • ')),
                    trailing: Text(money(p.amount))))
              ]);
            }));
  }
}

Widget _line(String a, double v, {bool b = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(a),
      Text(money(v),
          style: b
              ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
              : null)
    ]));
